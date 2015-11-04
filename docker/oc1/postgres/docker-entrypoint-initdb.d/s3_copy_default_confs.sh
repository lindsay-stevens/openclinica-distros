# Copy the default configurations in, as an alternative to sed madness
# Subsequent changes can be made via mounting the container volume
cp -f /docker-entrypoint-initdb.d/*.conf $PGDATA