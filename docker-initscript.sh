#!/bin/bash

set -euo pipefail

POSTGRESQL_HOST=${POSTGRESQL_HOST:-localhost}
POSTGRESQL_POSRT=${POSTGRESQL_PORT:-5432}

DB_NAME=${DB_NAME:-}
DB_USER=${DB_USER:-}
DB_PASS=${DB_PASS:-}

POOL_MODE=${PGBOUNCER_POOL_MODE:-session}
SERVER_RESET_QUERY=${PGBOUNCER_SERVER_RESET_QUERY:-}
PGBOUNCER_PREPARED_STATEMENTS=${PGBOUNCER_PREPARED_STATEMENTS:-}
# if the SERVER_RESET_QUERY and pool mode is session, pgbouncer recommends DISCARD ALL be the default
# http://pgbouncer.projects.pgfoundry.org/doc/faq.html#_what_should_my_server_reset_query_be
if [ -z "${SERVER_RESET_QUERY}" ] &&  [ "$POOL_MODE" == "session" ]; then
    SERVER_RESET_QUERY="DISCARD ALL;"
fi
if [ "$1" = 'pgbouncer' ]; then
    rm -rf /etc/pgbouncer/pgbouncer.ini
    rm -rf /etc/pgbouncer/users.txt

    mkdir -p /etc/pgbouncer/
    cat >> /etc/pgbouncer/pgbouncer.ini << EOFEOF
[pgbouncer]
listen_addr = 0.0.0.0
listen_port = 5432
auth_type = md5
auth_file = /etc/pgbouncer/users.txt
unix_socket_dir = /tmp
; When server connection is released back to pool:
;   session      - after client disconnects
;   transaction  - after transaction finishes
;   statement    - after statement finishes
pool_mode = ${POOL_MODE}
server_reset_query = ${SERVER_RESET_QUERY}
max_client_conn = ${PGBOUNCER_MAX_CLIENT_CONN:-100}
default_pool_size = ${PGBOUNCER_DEFAULT_POOL_SIZE:-1}
reserve_pool_size = ${PGBOUNCER_RESERVE_POOL_SIZE:-1}
reserve_pool_timeout = ${PGBOUNCER_RESERVE_POOL_TIMEOUT:-5.0}
log_connections = ${PGBOUNCER_LOG_CONNECTIONS:-1}
log_disconnections = ${PGBOUNCER_LOG_DISCONNECTIONS:-1}
log_pooler_errors = ${PGBOUNCER_LOG_POOLER_ERRORS:-1}
stats_period = ${PGBOUNCER_STATS_PERIOD:-60}
ignore_startup_parameters = ${PGBOUNCER_IGNORE_STARTUP_PARAMETER:-extra_float_digits}
[databases]
EOFEOF

    DB_MD5_PASS="md5"`echo -n ${DB_PASS}${DB_USER} | md5sum | awk '{print $1}'`

    echo "Setting ${DB_NAME}_PGBOUNCER config var"

    if [ "$PGBOUNCER_PREPARED_STATEMENTS" == "false" ]
    then
        export ${DB_NAME}_PGBOUNCER=postgres://$DB_USER:$DB_PASS@127.0.0.1:5432/$DB_NAME?prepared_statements=false
    else
        export ${DB_NAME}_PGBOUNCER=postgres://$DB_USER:$DB_PASS@127.0.0.1:5432/$DB_NAME
    fi

    cat >> /etc/pgbouncer/users.txt << EOFEOF
"$DB_USER" "$DB_MD5_PASS"
EOFEOF

    cat >> /etc/pgbouncer/pgbouncer.ini << EOFEOF
$DB_NAME= host=${POSTGRESQL_HOST} port=${POSTGRESQL_PORT} user=${DB_USER}
EOFEOF

    su - postgres -c "/usr/sbin/pgbouncer /etc/pgbouncer/pgbouncer.ini"
else
    exec "$@"
fi;
