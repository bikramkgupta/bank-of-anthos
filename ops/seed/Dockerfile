FROM postgres:15

WORKDIR /seed

COPY src/accounts/accounts-db/initdb/0-accounts-schema.sql /seed/0-accounts-schema.sql
COPY src/accounts/accounts-db/initdb/1-load-testdata.sh /seed/1-load-testdata.sh
COPY src/ledger/ledger-db/initdb/0_init_tables.sql /seed/0_init_tables.sql
COPY src/ledger/ledger-db/initdb/1_create_transactions.sh /seed/1_create_transactions.sh
COPY ops/seed/seed.sh /seed/seed.sh

RUN chmod +x /seed/*.sh

CMD ["/seed/seed.sh"]
