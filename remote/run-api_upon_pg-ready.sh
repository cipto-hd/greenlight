#!/bin/sh
set -e

docker-entrypoint.sh $POSTGRES_USER &

while ! pg_isready; do
  echo "Check"
  sleep 1
done

/app/api -db-dsn=$GREENLIGHT_DB_DSN -port=$PORT -env=$ENV \
  -db-max-open-conns=$DB_MAX_OPEN_CONNS -db-max-idle-conns=$DB_MAX_IDLE_CONNS -db-max-idle-time=$DB_MAX_IDLE_TIME \ 
  -smtp-host=$SMTP_HOST -smtp-port=$SMTP_PORT -smtp-user=$SMTP_USER -smtp-pass=$SMTP_PASS -smtp-sender=$SMTP_SENDER \
  -limiter-rps=$LIMITER_RPS -limiter-burst=$LIMITER_BURST -limiter-enabled=$LIMITER_ENABLED &

# Wait for any process to exit
wait -n

# Exit with status of process that exited first
exit $?
