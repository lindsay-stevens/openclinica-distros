#!/bin/bash
set -e

if [ "$*" = 'httpd -DFOREGROUND' ]; then
    # Apache gets grumpy about PID files pre-existing
    rm -f /usr/local/apache2/logs/httpd.pid
    
    # Make sure httpd user owns everything
    # In particular so it can write logs to the httpdfiles volume.
    chown -R httpd:httpd $HTTPD_PREFIX
    chmod g+s $HTTPD_PREFIX
    chmod -R 775 $HTTPD_PREFIX
    
    exec gosu httpd "$@"
fi

exec "$@"