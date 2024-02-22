#!/bin/sh
set -e

current_time=$(date -I'seconds');
git_description=$(git describe --always --dirty --tags --long);
# linker_flags="-s -X main.buildTime=$current_time -X main.version=$git_description";
go build \
  -ldflags="-s -X main.buildTime=$current_time -X main.version=$git_description" \
  -o=/app/api \
  ./cmd/api;