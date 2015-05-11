#!/bin/bash

export PGUSER="${PGUSER:-zabbix}"
export PGPASSWORD="${PGPASSWORD:-zabbix}"
export PGDATABASE="${PGDB:-zabbix}"

# Get these variables either from PGPORT and PGHOST, or from
# linked "pg" container.
export PGPORT="${PGPORT:-$( echo "${PG_PORT_5432_TCP_PORT:-5432}" )}"
export PGHOST="${PGHOST:-$( echo "${PG_PORT_5432_TCP_ADDR:-127.0.0.1}" )}"

set -e

function zabbix_check_db_accessible () {
    psql -c 'select 1' | grep 1 > /dev/null
}

function zabbix_check_db_initialized () {
    psql -c "select 'yes' from pg_class where relname = 'hosts'" | grep yes > /dev/null
}

function zabbix_initialize_db () {
    for zfile in /usr/share/zabbix-server-pgsql/{schema,images,data}.sql.gz; do
        local tempfile=$(mktemp)
        zcat "${zfile}" > "${tempfile}"
        psql -f "${tempfile}" -1
        rm "${tempfile}"
    done
}

function zabbix_write_configs () {
    cat > /etc/zabbix/zabbix_server.conf <<EOF
DBHost=${PGHOST}
DBPort=${PGPORT}
DBName=${PGDATABASE}
DBUser=${PGUSER}
DBPassword=${PGPASSWORD}
EOF
}

function start_server () {
    echo "Starting zabbix server in foreground..."
    echo "Starting zabbix agent in foreground..."
    zabbix_server &
    zabbix_agentd &
    while ps aux | awk '$11 == "zabbix_server"' > /dev/null; do
        sleep 1
    done
    echo "Looks like zabbix terminated. Aborting" >&2
    return 1
}

function main () {
    zabbix_check_db_accessible || {
        echo "Cannot access zabbix database. Aborting." >&2
        exit 1
    }
    zabbix_check_db_initialized || zabbix_initialize_db
    zabbix_write_configs
    if [[ ! "$1" ]]; then
        start_server
        exit $?
    fi
    exec "${@}"
}

main "${@}"
