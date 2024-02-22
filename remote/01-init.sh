#!/bin/bash
set -e
export PGPASSWORD=$POSTGRES_PASSWORD;
export PGUSER=$POSTGRES_USER;
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  CREATE USER $APP_DB_USER WITH PASSWORD '$APP_DB_PASS';
  CREATE DATABASE $APP_DB_NAME;
  GRANT ALL PRIVILEGES ON DATABASE $APP_DB_NAME TO $APP_DB_USER;
  \connect $APP_DB_NAME $POSTGRES_USER
  GRANT ALL ON SCHEMA public TO $APP_DB_USER;
  BEGIN;
    CREATE EXTENSION IF NOT EXISTS citext;

    CREATE TABLE IF NOT EXISTS movies (
      id bigserial PRIMARY KEY,
      created_at timestamp(0) with time zone NOT NULL DEFAULT NOW(),
      updated_at timestamp(0) with time zone NOT NULL DEFAULT NOW(),
      title text NOT NULL,
      year integer NOT NULL,
      runtime integer NOT NULL,
      genres text [] NOT NULL,
      version integer NOT NULL DEFAULT 1
    );

    ALTER TABLE
      movies
    ADD
      CONSTRAINT movies_runtime_check CHECK (runtime >= 0);

    ALTER TABLE
      movies
    ADD
      CONSTRAINT movies_year_check CHECK (
        year BETWEEN 1888
        AND date_part('year', now())
      );

    ALTER TABLE
      movies
    ADD
      CONSTRAINT genres_length_check CHECK (
        array_length(genres, 1) BETWEEN 1
        AND 5
      );

    CREATE INDEX IF NOT EXISTS movies_title_idx ON movies USING GIN (to_tsvector('simple', title));

    CREATE INDEX IF NOT EXISTS movies_genres_idx ON movies USING GIN (genres);

    CREATE TABLE IF NOT EXISTS users (
      id bigserial PRIMARY KEY,
      created_at timestamp(0) with time zone NOT NULL DEFAULT NOW(),
      name text NOT NULL,
      email citext UNIQUE NOT NULL,
      password_hash bytea NOT NULL,
      activated bool NOT NULL,
      version integer NOT NULL DEFAULT 1
    );

    CREATE TABLE IF NOT EXISTS tokens (
      hash bytea PRIMARY KEY,
      user_id bigint NOT NULL REFERENCES users ON DELETE CASCADE,
      expiry timestamp(0) with time zone NOT NULL,
      scope text NOT NULL
    );

    CREATE TABLE IF NOT EXISTS permissions (id bigserial PRIMARY KEY, code text NOT NULL);

    CREATE TABLE IF NOT EXISTS users_permissions (
      user_id bigint NOT NULL REFERENCES users ON DELETE CASCADE,
      permission_id bigint NOT NULL REFERENCES permissions ON DELETE CASCADE,
      PRIMARY KEY (user_id, permission_id)
    );

    -- Add the two permissions to the table.
    INSERT INTO
      permissions (code)
    VALUES 
      ('movies:read'),
      ('movies:write');
  COMMIT;
EOSQL
