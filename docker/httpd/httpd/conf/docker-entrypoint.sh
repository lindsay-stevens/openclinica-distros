#!/bin/bash
set -e

# If the HTTPD_INSECURE environment variable is set, then define the flag for it.
if [ "$HTTPD_INSECURE" == "yes" ]; then
    define_insecure = "-DInsecure"
fi

if [ "$*" = 'httpd -DFOREGROUND' ]; then
    # Apache gets grumpy about PID files pre-existing
    rm -f /usr/local/apache2/logs/httpd.pid
    
    # Make sure httpd user owns everything
    # In particular so it can write logs to the httpdfiles volume.
    chown -R httpd:httpd $HTTPD_PREFIX
    chmod g+s $HTTPD_PREFIX
    chmod -R 775 $HTTPD_PREFIX
    
    exec gosu httpd "$@" $define_insecure
fi

exec "$@"