# Load the database objects from a backup
export PGPASSWORD="$POSTGRES_PASSWORD"
pg_restore --username="$POSTGRES_USER" --dbname="$OC_DATABASE" --no-password \
    --no-owner --role="$OC_USER" --jobs=4 \
    "/docker-entrypoint-initdb.d/openclinica.backup"
