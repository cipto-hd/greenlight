#build stage
FROM golang:1.21-alpine3.19 AS builder
WORKDIR /app
COPY . .
RUN go build -o /app/api -v ./cmd/api

#final stage
FROM postgres:15.0-alpine3.16
WORKDIR /app
RUN apk --no-cache add ca-certificates
RUN apk add --no-cache procps
COPY --from=builder /app/api /app/api
RUN chmod +x /app/api
COPY ./remote/run-api_upon_pg-ready.sh /app/run-api_upon_pg-ready.sh
RUN chmod +x /app/run-api_upon_pg-ready.sh
COPY ./remote/01-init.sh /docker-entrypoint-initdb.d/

ENV POSTGRES_USER="postgres"
ENV POSTGRES_PASSWORD="password"
ENV APP_DB_USER="greenlight"
ENV APP_DB_PASS="greenlight"
ENV APP_DB_NAME="greenlight"
ENV GREENLIGHT_DB_DSN=postgres://$APP_DB_USER:$APP_DB_PASS@127.0.0.1:5432/$APP_DB_NAME?sslmode=disable
ENV PORT=4000
ENV ENV="production"
ENV DB_MAX_OPEN_CONNS=25
ENV DB_MAX_IDLE_CONNS=25
ENV DB_MAX_IDLE_TIME="15m"
ENV SMTP_HOST="127.0.0.1"
ENV SMTP_PORT=1025
ENV SMTP_USER="null"
ENV SMTP_PASS="null"
ENV SMTP_SENDER="Greenlight <no-reply@greenlight.test>"
ENV LIMITER_RPS=2
ENV LIMITER_BURST=4
ENV LIMITER_ENABLED=true

LABEL Name=greenlight Version=0.0.1
EXPOSE 4000

CMD [ "sh","-c","/app/run-api_upon_pg-ready.sh" ]