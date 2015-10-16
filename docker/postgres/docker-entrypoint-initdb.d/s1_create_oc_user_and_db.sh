# Create the openclinica user and database
export PGPASSWORD="$POSTGRES_PASSWORD"
psql --username="$POSTGRES_USER" --dbname="$POSTGRES_DB" --no-password \
    --command="CREATE USER $OC_USER LOGIN PASSWORD '$OC_PASSWORD' SUPERUSER;"
psql --username="$POSTGRES_USER" --dbname="$POSTGRES_DB" --no-password \
    --command="CREATE DATABASE $OC_DATABASE OWNER $OC_USER;"
