#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/touchpane-connection-tests.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT

xcrun clang -std=c11 -fblocks \
  -framework CoreFoundation -framework CoreGraphics -framework IOKit \
  "$ROOT_DIR/Tests/HIDConnectionTests.c" \
  -o "$TEST_DIR/HIDConnectionTests"
"$TEST_DIR/HIDConnectionTests"
