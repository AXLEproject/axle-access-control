#!/bin/bash
#
# Use this script to set PostgreSQL environment variables.
# To prevent accidents this scripts modifies the current prompt
# so it displays the active database.
#
OPTIND=1;
# The default values
PGHOST="localhost";
PGPORT="5432";
PGDATABASE="minirim";
PGUSER="postgres";

_PROMPT='';
while getopts "h:p:d:u:" flag
do
    case "$flag" in
        "h")
            PGHOST="$OPTARG";
            _PROMPT=${_PROMPT}:$PGHOST
            ;;
        "p")
            PGPORT="$OPTARG";
            _PROMPT=${_PROMPT}:$PGPORT
            ;;
        "d")
            PGDATABASE="$OPTARG";
            _PROMPT=${_PROMPT}:$PGDATABASE
            ;;
        "u")
            PGUSER="$OPTARG";
            _PROMPT=${_PROMPT}:$PGUSER
            ;;
        *)
            echo "Usage: source set_pg_environment [-h <host>] [-p <port>] [-d <database>] [-u <user>]";
            exit;
            ;;
    esac;
done;

export PGHOST="$PGHOST";
export PGPORT="$PGPORT";
export PGDATABASE="$PGDATABASE";
export PGUSER="$PGUSER";
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\[\033[01;36m\]$_PROMPT\[\033[00m\]$ ';
