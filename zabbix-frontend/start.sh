#!/bin/bash

export PGUSER="${PGUSER:-zabbix}"
export PGPASSWORD="${PGPASSWORD:-zabbix}"
export PGDATABASE="${PGDB:-zabbix}"

# Get these variables either from PGPORT and PGHOST, or from
# linked "pg" container.
export PGPORT="${PGPORT:-$( echo "${PG_PORT_5432_TCP_PORT:-5432}" )}"
export PGHOST="${PGHOST:-$( echo "${PG_PORT_5432_TCP_ADDR:-127.0.0.1}" )}"

export ZABBIX_SERVER_HOST="${ZABBIX_SERVER_HOST:-zabbix-server}"

set -e

function zabbix_check_db_accessible () {
    psql -c 'select 1' > /dev/null
}

function zabbix_frontend_write_config () {
    cat > /etc/zabbix/zabbix.conf.php <<EOF
<?php
// Zabbix GUI configuration file
global \$DB;

\$DB['TYPE']     = 'POSTGRESQL';
\$DB['SERVER']   = '$PGHOST';
\$DB['PORT']     = '$PGPORT';
\$DB['DATABASE'] = '$PGDATABASE';
\$DB['USER']     = '$PGUSER';
\$DB['PASSWORD'] = '$PGPASSWORD';

// SCHEMA is relevant only for IBM_DB2 database
\$DB['SCHEMA'] = '';

\$ZBX_SERVER      = '$ZABBIX_SERVER_HOST';
\$ZBX_SERVER_PORT = '10051';
\$ZBX_SERVER_NAME = '';

\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
?>
EOF


    grep '^date.timezone' "${PHP5_FPM_INI}" || echo "date.timezone = ${TIMEZONE:-UTC}" >> "${PHP5_FPM_INI}"
}

function main () {
    zabbix_check_db_accessible || {
        echo "Cannot connect to zabbix database, aborting."
        exit 1
    }
    zabbix_frontend_write_config
    if [[ ! "${1}" ]]; then
        exec supervisord -c /supervisor.conf
    fi
    "${@}"
}

main "${@}"
