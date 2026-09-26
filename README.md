# DevOps Assessment - Terraform + Database Reliability

Internet -> ALB -> ECS/Fargate -> RDS PostgreSQL, written as Terraform modules
with separate dev and prod environments, plus a local PostgreSQL setup with
seed data, an optimised index, and tested backup/restore scripts.

## Repository layout

```
infra/
  modules/  network/  ecs/  rds/
  envs/     dev/  prod/
db/
  migrations/  001_create_tables.sql  002_create_indexes.sql
  seed/        003_seed_data.sql
scripts/  backup.sh  restore.sh
.github/workflows/terraform-plan.yml
docker-compose.yml
```

## 1. Terraform (no AWS account needed)

`plan_only` defaults to `true`, so the AWS provider uses mock credentials and
skips account lookups. The S3 backend needs a real bucket, so for review use a
local backend override (this file is git-ignored):

```bash
cd infra/envs/dev          # or prod
printf 'terraform {\n  backend "local" {}\n}\n' > backend_override.tf

terraform fmt -check -recursive ../..
terraform init
terraform validate
terraform plan -refresh=false
```

Real deployment: remove the override, create the state bucket, set
`TF_VAR_plan_only=false` and authenticate via OIDC.

### dev vs prod

| Setting              | dev            | prod            |
|----------------------|----------------|-----------------|
| AZs / NAT            | 2 / 1 shared   | 3 / 1 per AZ    |
| Fargate task         | 0.25 vCPU/512MB x1 | 0.5 vCPU/1GB x2 |
| RDS instance         | db.t4g.micro   | db.r6g.large    |
| Multi-AZ             | no             | yes             |
| Backup retention     | 3 days         | 30 days         |
| Deletion protection  | false          | true            |
| Final snapshot       | skipped        | taken           |
| State                | hotelbook-tfstate-dev | hotelbook-tfstate-prod |

## 2. Local database

```bash
cp .env.example .env        # optional, defaults work
docker compose up -d
docker compose ps           # wait for "healthy"
docker exec -it hotel_db psql -U hotel_app -d hotel
```

Migrations and seed run automatically on first start (empty volume).
To start over: `docker compose down -v && docker compose up -d`.

Seed: 1,000 bookings, 5 orgs, 6 cities, 5 statuses, ~2,000 booking events,
created_at spread over the last 90 days.

## 3. Index choice

```sql
CREATE INDEX idx_bookings_city_created_at
  ON hotel_bookings (city, created_at) INCLUDE (org_id, status, amount);
```

* `city` first because it is an equality filter; `created_at` second because
  it is a range. Equality-before-range lets Postgres jump straight to the
  delhi entries and read one contiguous slice of the last 30 days.
* `INCLUDE (org_id, status, amount)` puts the remaining columns in the index
  leaf pages, so the query becomes an **Index Only Scan** and never touches the
  table.
* Why not a partial index on `created_at >= now() - 30 days`? `now()` is not
  immutable, so that is not allowed (and the window moves anyway).

Check it:

```sql
EXPLAIN (ANALYZE) SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi' AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;
```

Expect `Index Only Scan using idx_bookings_city_created_at` and `Heap Fetches: 0`
(run `VACUUM ANALYZE hotel_bookings;` first if heap fetches are > 0).

## 4. Backup and restore

```bash
./scripts/backup.sh      # -> backups/hotel_YYYYMMDD_HHMMSS.dump (+ .sha256, latest.dump)
./scripts/restore.sh     # restores latest.dump into a fresh DB "hotel_restore"
./scripts/restore.sh backups/hotel_20260926_101500.dump   # a specific file
```

### How to verify the restore worked

1. `restore.sh` exits `0` and prints OK for each table plus the data fingerprint.
2. Check manually:

```bash
for db in hotel hotel_restore; do
  docker exec hotel_db psql -U hotel_app -d $db -tAc \
    "SELECT '$db', (SELECT count(*) FROM hotel_bookings), (SELECT count(*) FROM booking_events);"
done
docker exec hotel_db psql -U hotel_app -d hotel_restore -c '\di'   # indexes restored
```

3. Run the optimised query against `hotel_restore` - same result as `hotel`.
