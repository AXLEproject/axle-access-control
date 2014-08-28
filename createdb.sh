#!/bin/bash
set -e

usage() {
cat << EOF
usage: $0 options

(Re)create a database, load a mini rim and load a use case.

OPTIONS:
   -r      (Re)create database with mini-rim
   -d      database name
   -u      Base use case SQL file         (use_cases_data.sql)
   -x      Extra use case file to include (consent_data.sql)
   -f      Run test SQL file              (use_cases_rlstest.sql)
   -h      This message

EXAMPLES:
   ./createdb.sh -rd rim -u use_cases_data.sql                          # new database and use case data
   ./createdb.sh -d rim -f use_cases_rlstest.sql                        # run test on a database
   ./createdb.sh -rd rim -u use_cases_data.sql -f use_cases_rlstest.sql # both steps above combined
   ./createdb.sh -rd rim -u use_cases_data.sql -x consent_data.sql      # new database with use case and consent data

EOF
}

test -n "${2}" || usage

redis=localhost
while getopts "hrd:u:x:f:" opt; do
	case $opt in
	h)
		usage
		exit 1
	;;
	r)
		DROPCREATE="yes"
	;;
	d)
		DATABASE="$OPTARG"
	;;
	u)
		BASEUSECASE="$OPTARG"
	;;
	x)
		EXTRAUSECASE="$OPTARG"
	;;
	f)
		RUNTEST="$OPTARG"
	;;

	\?)
		echo "Invalid option: -$OPTARG" >&2
	;;
	esac
done

if [ "X" != "X${DROPCREATE}" ]; then
    psql -qc "DROP DATABASE IF EXISTS \"${DATABASE}\"" postgres
    createdb ${DATABASE}
    echo "Creating mini rim"
    sed -e "s/_DB_/$DATABASE/g" mini-rim.sql | psql -q -vON_ERROR_STOP=yes ${DATABASE}
fi

if [ "X" != "X${BASEUSECASE}" ]; then
    if [ "X" = "X${EXTRAUSECASE}" ]; then
        EXTRAUSECASE=/dev/null
    else
        echo "Adding extra use case ${EXTRAUSECASE}"
    fi
    SQL=/tmp/rlstemp.sql
    echo -e "\e[92mPreparing SQL file into temporary file ${SQL}\e[0m"
    sed -e "/_EXTRAUSECASE_/{r $EXTRAUSECASE" \
        -e 'd}' ${BASEUSECASE} > ${SQL}
    psql -f ${SQL} -q -vON_ERROR_STOP=yes ${DATABASE}
fi

if [ "X" != "X${RUNTEST}" ]; then
    psql -f ${RUNTEST} -q -vON_ERROR_STOP=yes ${DATABASE}
fi
