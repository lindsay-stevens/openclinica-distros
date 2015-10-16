# Copy the default configurations in, as an alternative to sed madness
# Subsequent changes can be made via mounting the container volume
cp -f /docker-entrypoint-initdb.d/pg_hba.conf $PGDATA
cp -f /docker-entrypoint-initdb.d/postgresql.conf $PGDATA
