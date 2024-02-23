#!/bin/sh
set -e

go generate ./...
current_time=$(date -I'seconds');
# linker_flags="-s -X main.buildTime=$current_time";
go build \
  -ldflags="-s -X main.buildTime=$current_time" \
  -o=/app/api \
  ./cmd/api;