#!/usr/bin/env bash
set -euo pipefail

is_true() {
  case "${1,,}" in
    true|1|yes|y) return 0 ;;
    *) return 1 ;;
  esac
}

if ! is_true "${SEED_ON_DEPLOY:-false}"; then
  echo "SEED_ON_DEPLOY not true; skipping demo seed."
  exit 0
fi

required_vars=(
  ACCOUNTS_DB_HOST
  ACCOUNTS_DB_PORT
  ACCOUNTS_DB_USER
  ACCOUNTS_DB_PASSWORD
  ACCOUNTS_DB_NAME
  LEDGER_DB_HOST
  LEDGER_DB_PORT
  LEDGER_DB_USER
  LEDGER_DB_PASSWORD
  LEDGER_DB_NAME
  LOCAL_ROUTING_NUM
)

for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "Missing required env var: $var" >&2
    exit 1
  fi
done

seed_accounts() {
  echo "Seeding accountsdb..."
  local users_table
  users_table="$(PGPASSWORD="$ACCOUNTS_DB_PASSWORD" PGSSLMODE=require \
    psql -h "$ACCOUNTS_DB_HOST" -p "$ACCOUNTS_DB_PORT" -U "$ACCOUNTS_DB_USER" \
    -d "$ACCOUNTS_DB_NAME" -tAc "SELECT to_regclass('public.users')")"

  if [[ "$users_table" != "users" ]]; then
    echo "Creating accounts schema..."
    PGPASSWORD="$ACCOUNTS_DB_PASSWORD" PGSSLMODE=require \
      psql -h "$ACCOUNTS_DB_HOST" -p "$ACCOUNTS_DB_PORT" -U "$ACCOUNTS_DB_USER" \
      -d "$ACCOUNTS_DB_NAME" -v ON_ERROR_STOP=1 -f /seed/0-accounts-schema.sql
  fi

  echo "Loading demo users..."
  (
    export PGHOST="$ACCOUNTS_DB_HOST"
    export PGPORT="$ACCOUNTS_DB_PORT"
    export PGPASSWORD="$ACCOUNTS_DB_PASSWORD"
    export PGSSLMODE=require
    export POSTGRES_DB="$ACCOUNTS_DB_NAME"
    export POSTGRES_USER="$ACCOUNTS_DB_USER"
    export LOCAL_ROUTING_NUM="$LOCAL_ROUTING_NUM"
    export USE_DEMO_DATA=True
    bash /seed/1-load-testdata.sh
  )
}

seed_ledger() {
  echo "Seeding ledgerdb..."
  local tx_table
  tx_table="$(PGPASSWORD="$LEDGER_DB_PASSWORD" PGSSLMODE=require \
    psql -h "$LEDGER_DB_HOST" -p "$LEDGER_DB_PORT" -U "$LEDGER_DB_USER" \
    -d "$LEDGER_DB_NAME" -tAc "SELECT to_regclass('public.transactions')")"

  if [[ "$tx_table" != "transactions" ]]; then
    echo "Creating ledger schema..."
    PGPASSWORD="$LEDGER_DB_PASSWORD" PGSSLMODE=require \
      psql -h "$LEDGER_DB_HOST" -p "$LEDGER_DB_PORT" -U "$LEDGER_DB_USER" \
      -d "$LEDGER_DB_NAME" -v ON_ERROR_STOP=1 -f /seed/0_init_tables.sql
  fi

  local tx_count
  tx_count="$(PGPASSWORD="$LEDGER_DB_PASSWORD" PGSSLMODE=require \
    psql -h "$LEDGER_DB_HOST" -p "$LEDGER_DB_PORT" -U "$LEDGER_DB_USER" \
    -d "$LEDGER_DB_NAME" -tAc "SELECT count(*) FROM transactions")"
  tx_count="${tx_count//[[:space:]]/}"

  if [[ -n "$tx_count" && "$tx_count" -gt 0 ]]; then
    echo "Ledger already has $tx_count transactions; skipping."
    return
  fi

  echo "Loading demo transactions..."
  (
    export PGHOST="$LEDGER_DB_HOST"
    export PGPORT="$LEDGER_DB_PORT"
    export PGPASSWORD="$LEDGER_DB_PASSWORD"
    export PGSSLMODE=require
    export POSTGRES_DB="$LEDGER_DB_NAME"
    export POSTGRES_USER="$LEDGER_DB_USER"
    export POSTGRES_PASSWORD="$LEDGER_DB_PASSWORD"
    export LOCAL_ROUTING_NUM="$LOCAL_ROUTING_NUM"
    export USE_DEMO_DATA=True
    bash /seed/1_create_transactions.sh
  )
}

seed_accounts
seed_ledger

echo "Demo seed complete. Login with testuser / password."
