#!/bin/bash
# Test install.sh functionality
set -uo pipefail
shopt -s inherit_errexit

declare -- SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
declare -r SCRIPT_DIR

# shellcheck source=test-helpers.sh
source "$SCRIPT_DIR/test-helpers.sh"

# Always use install.sh from parent directory (ignore any arguments)
declare -r INSTALL="$SCRIPT_DIR/../install.sh"

# Create isolated test environment
declare -- TEST_ROOT
TEST_ROOT=$(mktemp -d "/tmp/dux-test-install-XXXXXX")
declare -r TEST_ROOT
declare -r TEST_HOME="$TEST_ROOT/home"
declare -r TEST_BIN="$TEST_HOME/.local/bin"
declare -r TEST_COMP="$TEST_HOME/.local/share/bash-completion/completions"
declare -r TEST_MAN="$TEST_HOME/.local/share/man/man1"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

# Helper: assert symlink exists and points to target
assert_symlink() {
  local -- link="$1"
  local -- target="$2"
  local -- test_name="${3:-Symlink $link -> $target}"

  TESTS_RUN+=1

  if [[ -L "$link" ]]; then
    local -- actual_target
    actual_target=$(readlink "$link")
    if [[ "$actual_target" == "$target" ]]; then
      TESTS_PASSED+=1
      echo "${GREEN}✓${NC} $test_name"
      return 0
    else
      TESTS_FAILED+=1
      FAILED_TESTS+=("$test_name")
      echo "${RED}✗${NC} $test_name"
      echo "  Expected target: $target"
      echo "  Actual target: $actual_target"
      return 1
    fi
  else
    TESTS_FAILED+=1
    FAILED_TESTS+=("$test_name")
    echo "${RED}✗${NC} $test_name"
    echo "  Not a symlink: $link"
    return 1
  fi
}

# Helper: assert file does not exist
assert_file_not_exists() {
  local -- file="$1"
  local -- test_name="${2:-File should not exist: $file}"

  TESTS_RUN+=1

  if [[ ! -e "$file" ]] && [[ ! -L "$file" ]]; then
    TESTS_PASSED+=1
    echo "${GREEN}✓${NC} $test_name"
    return 0
  else
    TESTS_FAILED+=1
    FAILED_TESTS+=("$test_name")
    echo "${RED}✗${NC} $test_name"
    echo "  File exists: $file"
    return 1
  fi
}

# Helper: assert file is executable
assert_executable() {
  local -- file="$1"
  local -- test_name="${2:-File is executable: $file}"

  TESTS_RUN+=1

  if [[ -x "$file" ]]; then
    TESTS_PASSED+=1
    echo "${GREEN}✓${NC} $test_name"
    return 0
  else
    TESTS_FAILED+=1
    FAILED_TESTS+=("$test_name")
    echo "${RED}✗${NC} $test_name"
    echo "  File not executable: $file"
    return 1
  fi
}

# Setup fake HOME environment for user-mode install tests
setup_test_env() {
  mkdir -p "$TEST_HOME"
  export HOME="$TEST_HOME"
}

test_section "Help and Version"

# Test: --help exits 0
output=$("$INSTALL" --help 2>&1); ec=$?
assert_exit_code 0 "$ec" "--help exits 0"
assert_contains "$output" "Install dux utility" "--help shows description"
assert_contains "$output" "USAGE" "--help shows usage"
assert_contains "$output" "--uninstall" "--help mentions uninstall"
assert_contains "$output" "--dry-run" "--help mentions dry-run"

# Test: -h exits 0
output=$("$INSTALL" -h 2>&1); ec=$?
assert_exit_code 0 "$ec" "-h exits 0"

# Test: Invalid option fails
output=$("$INSTALL" --invalid 2>&1); ec=$?
assert_failure "$ec" "Invalid option exits non-zero"
assert_contains "$output" "Unknown option" "Shows unknown option error"

test_section "Dry Run Mode"

setup_test_env

# Test: --dry-run shows what would be installed
output=$("$INSTALL" --dry-run 2>&1); ec=$?
assert_exit_code 0 "$ec" "--dry-run exits 0"
assert_contains "$output" "Would install" "--dry-run shows 'Would install'"
assert_contains "$output" "Would symlink" "--dry-run shows 'Would symlink'"
assert_contains "$output" "dry-run mode" "--dry-run confirms mode"

# Test: --dry-run doesn't create files
assert_file_not_exists "$TEST_BIN/dir-sizes" "--dry-run doesn't create binary"
assert_file_not_exists "$TEST_BIN/dux" "--dry-run doesn't create symlink"

# Test: -n works same as --dry-run
output=$("$INSTALL" -n 2>&1); ec=$?
assert_exit_code 0 "$ec" "-n exits 0"
assert_contains "$output" "Would install" "-n shows 'Would install'"

test_section "User Installation"

setup_test_env

# Test: Install as user
output=$("$INSTALL" 2>&1); ec=$?
assert_exit_code 0 "$ec" "Install exits 0"
assert_contains "$output" "Installation complete" "Shows completion message"

# Test: Files are installed
assert_file_exists "$TEST_BIN/dir-sizes" "dir-sizes binary installed"
assert_executable "$TEST_BIN/dir-sizes" "dir-sizes is executable"
assert_symlink "$TEST_BIN/dux" "dir-sizes" "dux symlink created"
assert_file_exists "$TEST_COMP/dux" "Bash completion installed"
assert_file_exists "$TEST_MAN/dux.1" "Manpage installed"

# Test: Directories were created
assert_dir_exists "$TEST_BIN" "Binary directory created"
assert_dir_exists "$TEST_COMP" "Completion directory created"
assert_dir_exists "$TEST_MAN" "Manpage directory created"

# Test: Binary content is correct (spot check)
if head -1 "$TEST_BIN/dir-sizes" | grep -qE "^#!.*bash"; then
  pass "dir-sizes has correct shebang"
else
  fail "dir-sizes missing shebang"
fi

test_section "Reinstallation"

# Test: Reinstall over existing files works
output=$("$INSTALL" 2>&1); ec=$?
assert_exit_code 0 "$ec" "Reinstall exits 0"
assert_file_exists "$TEST_BIN/dir-sizes" "dir-sizes still exists after reinstall"
assert_symlink "$TEST_BIN/dux" "dir-sizes" "dux symlink still correct after reinstall"

test_section "Uninstallation"

# Test: Uninstall dry-run
output=$("$INSTALL" --uninstall --dry-run 2>&1); ec=$?
assert_exit_code 0 "$ec" "Uninstall dry-run exits 0"
assert_contains "$output" "Would remove" "Uninstall dry-run shows 'Would remove'"
assert_file_exists "$TEST_BIN/dir-sizes" "Dry-run doesn't remove binary"

# Test: Actual uninstall
output=$("$INSTALL" --uninstall 2>&1); ec=$?
assert_exit_code 0 "$ec" "Uninstall exits 0"
assert_contains "$output" "Uninstallation complete" "Shows uninstall completion"

# Test: Files are removed
assert_file_not_exists "$TEST_BIN/dir-sizes" "dir-sizes removed"
assert_file_not_exists "$TEST_BIN/dux" "dux symlink removed"
assert_file_not_exists "$TEST_COMP/dux" "Completion removed"
assert_file_not_exists "$TEST_MAN/dux.1" "Manpage removed"

# Test: Uninstall when already uninstalled (idempotent)
output=$("$INSTALL" --uninstall 2>&1); ec=$?
assert_exit_code 0 "$ec" "Uninstall when already uninstalled exits 0"

test_section "Source File Validation"

# Test: Install fails if source files missing
BAD_DIR=$(mktemp -d)
cp "$INSTALL" "$BAD_DIR/install.sh"
chmod +x "$BAD_DIR/install.sh"
output=$(cd "$BAD_DIR" && ./install.sh 2>&1); ec=$?
assert_failure "$ec" "Install fails when source files missing"
assert_contains "$output" "Missing" "Shows missing file error"
rm -rf "$BAD_DIR"

test_section "Separate Options"

setup_test_env

# Test: -u -n (uninstall + dry-run as separate options)
"$INSTALL" >/dev/null 2>&1  # Install first
output=$("$INSTALL" -u -n 2>&1); ec=$?
assert_exit_code 0 "$ec" "-u -n (uninstall dry-run) exits 0"
assert_contains "$output" "Would remove" "-u -n shows 'Would remove'"
assert_file_exists "$TEST_BIN/dir-sizes" "-u -n doesn't actually remove files"

# Clean up for next test
"$INSTALL" --uninstall >/dev/null 2>&1 || true

print_summary
exit $?

#fin
