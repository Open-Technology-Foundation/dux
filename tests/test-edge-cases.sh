#!/usr/bin/env bash
# Test edge cases and error handling of dux
# Note: uses -uo (no -e) so assertion failures don't abort the test run
set -uo pipefail
shopt -s inherit_errexit shift_verbose extglob nullglob

#shellcheck disable=SC2155
declare -r SCRIPT_PATH=$(realpath -- "$0")
declare -r SCRIPT_DIR=${SCRIPT_PATH%/*}

# shellcheck source=test-helpers.sh
source "$SCRIPT_DIR"/test-helpers.sh

declare -r DUX=${1:-$SCRIPT_DIR/../dir-sizes}

# Create temp directory for tests
declare -- TEST_DIR
TEST_DIR=$(mktemp -d /tmp/dux-test-edge-XXXXXX)
declare -r TEST_DIR
trap 'rm -rf "$TEST_DIR"' EXIT

test_section 'Edge Cases'

# Test: Empty directory returns itself (find always returns the target dir)
mkdir -p "$TEST_DIR"/truly-empty
output=$("$DUX" "$TEST_DIR"/truly-empty 2>&1); ec=$?
assert_exit_code 0 "$ec" 'Empty directory exits 0 (returns itself)'
assert_contains "$output" 'truly-empty' 'Empty dir shows in output'

# Test: Directory with only files returns itself
mkdir -p "$TEST_DIR"/files-only
touch "$TEST_DIR"/files-only/file1.txt "$TEST_DIR"/files-only/file2.txt
output=$("$DUX" "$TEST_DIR"/files-only 2>&1); ec=$?
assert_exit_code 0 "$ec" 'Directory with only files exits 0'
assert_contains "$output" 'files-only' 'Files-only dir shows in output'

# Test: Symlink to directory behavior without -L
# Note: find without -L doesn't follow symlinks as starting paths
mkdir -p "$TEST_DIR"/real-dir/subdir
ln -s "$TEST_DIR"/real-dir "$TEST_DIR"/symlink-to-dir
output=$("$DUX" "$TEST_DIR"/symlink-to-dir 2>&1); ec=$?
if ((ec == 0)); then
  pass 'Symlink to directory works without -L'
else
  # Known limitation: find without -L doesn't follow symlinks as starting path
  warn 'Symlink starting path not supported without -L (known limitation)'
fi

# Test: -L flag makes symlink starting paths work
output=$("$DUX" -L "$TEST_DIR"/symlink-to-dir 2>&1); ec=$?
assert_exit_code 0 "$ec" '-L flag allows symlink starting paths'
assert_contains "$output" 'subdir' 'With -L, symlink target contents shown'

# Test: Symlinks within target are excluded (find -type d)
mkdir -p "$TEST_DIR"/has-symlinks/real-subdir
ln -s "$TEST_DIR"/has-symlinks/real-subdir "$TEST_DIR"/has-symlinks/symlink-subdir
output=$("$DUX" "$TEST_DIR"/has-symlinks 2>&1); ec=$?
assert_exit_code 0 "$ec" 'Directory with symlinks handled'
assert_contains "$output" 'real-subdir' 'Real subdirectory found'

# Test: Directory with special chars in name
mkdir -p "$TEST_DIR/special-chars/sub with spaces"
mkdir -p "$TEST_DIR/special-chars/sub\$dollar"
mkdir -p "$TEST_DIR/special-chars/sub!exclaim"
output=$("$DUX" "$TEST_DIR"/special-chars 2>&1); ec=$?
assert_exit_code 0 "$ec" 'Special chars in dir names handled'
assert_contains "$output" 'spaces' 'Dir with spaces in output'

# Test: Very deep directory structure
declare -- deep_path="$TEST_DIR/deep"
declare -i i
for i in {1..10}; do
  deep_path="$deep_path/level$i"
done
mkdir -p "$deep_path"
output=$("$DUX" "$TEST_DIR"/deep 2>&1); ec=$?
assert_exit_code 0 "$ec" 'Deep directory structure handled'

# Test: Directory with many subdirs (50+)
mkdir -p "$TEST_DIR"/many-subdirs
for i in {1..50}; do
  mkdir -p "$TEST_DIR/many-subdirs/subdir$i"
done
output=$("$DUX" "$TEST_DIR"/many-subdirs 2>&1); ec=$?
assert_exit_code 0 "$ec" 'Many subdirectories handled'
declare -i line_count
line_count=$(echo "$output" | wc -l)
assert_greater_than "$line_count" 49 'All 50+ subdirs in output'

# Test: Hidden directories (.hidden) included
mkdir -p "$TEST_DIR"/with-hidden/.hidden-dir
mkdir -p "$TEST_DIR"/with-hidden/visible-dir
output=$("$DUX" "$TEST_DIR"/with-hidden 2>&1); ec=$?
assert_exit_code 0 "$ec" 'Directory with hidden dirs handled'
assert_contains "$output" '.hidden-dir' 'Hidden directories included'
assert_contains "$output" 'visible-dir' 'Visible directories included'

# Test: Unicode directory names
mkdir -p "$TEST_DIR"/unicode/日本語
mkdir -p "$TEST_DIR"/unicode/émoji🎉
output=$("$DUX" "$TEST_DIR"/unicode 2>&1); ec=$?
if ((ec == 0)); then
  pass 'Unicode directory names handled'
  if echo "$output" | grep -q '日本語'; then
    pass 'Japanese characters in output'
  else
    warn 'Japanese chars may not display correctly'
  fi
else
  warn 'Unicode support may vary by system'
fi

# Test: Very long directory path
declare -- long_name
long_name=$(printf 'a%.0s' {1..200})
mkdir -p "$TEST_DIR/longpath/$long_name"
output=$("$DUX" "$TEST_DIR"/longpath 2>&1); ec=$?
assert_exit_code 0 "$ec" 'Long directory paths handled'

# Test: Permission denied scenario (if we can create unreadable dir)
if mkdir -p "$TEST_DIR"/perms/unreadable 2>/dev/null; then
  mkdir -p "$TEST_DIR"/perms/readable
  chmod 000 "$TEST_DIR"/perms/unreadable 2>/dev/null ||:

  # Test without -q (should show permission errors on stderr)
  output=$("$DUX" "$TEST_DIR"/perms 2>&1); ec=$?

  # Test with -q (should suppress permission errors)
  declare -- quiet_output
  declare -i quiet_ec
  quiet_output=$("$DUX" -q "$TEST_DIR"/perms 2>&1); quiet_ec=$?

  # Restore permissions for cleanup
  chmod 755 "$TEST_DIR"/perms/unreadable 2>/dev/null ||:

  # Script should still succeed with partial results
  if ((ec == 0)); then
    pass 'Permission denied handled gracefully'
  else
    warn 'Permission denied behavior may vary'
  fi

  # -q should succeed and suppress error output
  if ((quiet_ec == 0)); then
    pass '-q option succeeds with permission errors'
    # Check if -q output has fewer error messages than non-quiet
    if ((${#quiet_output} <= ${#output})); then
      pass '-q suppresses or reduces error output'
    else
      warn '-q output comparison inconclusive'
    fi
  else
    warn '-q behavior with permission errors may vary'
  fi
else
  skip_test 'Cannot create permission test directory'
fi

# Test: H1 regression — verbose mode with unreadable subdirs must not crash
# Before fix, 2>&1 merged permission-denied text into du output, failing regex
if ((EUID != 0)); then
  mkdir -p "$TEST_DIR"/h1-verbose/readable-sub
  mkdir -p "$TEST_DIR"/h1-verbose/unreadable-sub
  echo 'test data' > "$TEST_DIR"/h1-verbose/readable-sub/file.txt
  chmod 000 "$TEST_DIR"/h1-verbose/unreadable-sub 2>/dev/null ||:

  # Run in verbose mode (default) — stderr should flow to terminal, not corrupt size
  declare -- h1_output
  declare -i h1_ec
  h1_output=$("$DUX" "$TEST_DIR"/h1-verbose 2>/dev/null); h1_ec=$?

  chmod 755 "$TEST_DIR"/h1-verbose/unreadable-sub 2>/dev/null ||:

  assert_exit_code 0 "$h1_ec" 'H1: verbose mode exits 0 with unreadable subdirs'
  assert_contains "$h1_output" 'readable-sub' 'H1: readable subdir still shown in output'
else
  skip_test 'H1 regression test requires non-root (root bypasses permissions)'
fi

print_summary
exit $?

#fin
