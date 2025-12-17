#!/bin/bash
# Test exit codes of dux
set -uo pipefail
shopt -s inherit_errexit

declare -- SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
declare -r SCRIPT_DIR

# shellcheck source=test-helpers.sh
source "$SCRIPT_DIR/test-helpers.sh"

declare -r DUX="${1:-$SCRIPT_DIR/../dir-sizes}"

# Create temp directory for tests
declare -- TEST_DIR
TEST_DIR=$(mktemp -d "/tmp/dux-test-exit-XXXXXX")
declare -r TEST_DIR
trap 'rm -rf "$TEST_DIR"' EXIT

# Setup test fixtures
mkdir -p "$TEST_DIR/with-subdirs/sub1" "$TEST_DIR/with-subdirs/sub2"
mkdir -p "$TEST_DIR/empty-dir"
touch "$TEST_DIR/regular-file.txt"

test_section "Exit Codes"

# Test: Exit 0 on success
output=$("$DUX" "$TEST_DIR/with-subdirs" 2>&1); ec=$?
assert_exit_code 0 "$ec" "Exit 0 on success"

# Test: Exit 0 on --help
"$DUX" --help >/dev/null 2>&1; ec=$?
assert_exit_code 0 "$ec" "Exit 0 on --help"

# Test: Exit 0 on --version
"$DUX" --version >/dev/null 2>&1; ec=$?
assert_exit_code 0 "$ec" "Exit 0 on --version"

# Test: Exit 1 on non-existent directory
output=$("$DUX" "/nonexistent/path/that/does/not/exist" 2>&1); ec=$?
assert_exit_code 1 "$ec" "Exit 1 on non-existent directory"
assert_contains "$output" "Not a directory" "Shows 'not a directory' error"

# Test: Exit 1 on file (not directory)
output=$("$DUX" "$TEST_DIR/regular-file.txt" 2>&1); ec=$?
assert_exit_code 1 "$ec" "Exit 1 when path is a file"
assert_contains "$output" "Not a directory" "Shows 'not a directory' for file"

# Test: Exit 2 on too many arguments
output=$("$DUX" "$TEST_DIR" "$TEST_DIR" 2>&1); ec=$?
assert_exit_code 2 "$ec" "Exit 2 on too many arguments"

# Test: Exit 22 on invalid option
output=$("$DUX" --invalid-option 2>&1); ec=$?
assert_exit_code 22 "$ec" "Exit 22 on invalid option"

# Test: Empty directory shows itself (find returns the dir itself)
# Note: dux always finds at least the target directory, so empty dirs don't error
output=$("$DUX" "$TEST_DIR/empty-dir" 2>&1); ec=$?
assert_exit_code 0 "$ec" "Empty directory exits 0 (returns itself)"
assert_contains "$output" "empty-dir" "Empty dir shows in output"

print_summary
exit $?

#fin
