# Changelog

All notable changes to dux are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.1] - 2025-12-18

### Changed
- Shebangs updated to `#!/usr/bin/env bash` for BCS compliance and portability
- Added `shift_verbose` shopt to install.sh for better error detection

### Fixed
- File permissions for root installs (chmod 644 for manpage and completion)
- Manpage accessibility for user installs (run mandb after install)
- ShellCheck warnings in test files (SC2155, SC2076, SC2034)
- Shebang test pattern to accept both `#!/bin/bash` and `#!/usr/bin/env bash`

## [1.4.0] - 2025-12-18

### Added
- `-L` option to follow symbolic links when finding directories
- `-q, --quiet` option to suppress permission error messages
- `install.sh` for easy installation and uninstallation
- Bash completion (`dux.bash_completion`) for both `dux` and `dir-sizes` commands
- Man page (`dux.1`) with full documentation
- Comprehensive test suite (131 tests across 6 test files)

### Changed
- Updated README with user-focused documentation
- Improved help text for clarity and brevity
- Bash completion now uses `mapfile` pattern (shellcheck compliant)

### Fixed
- Shellcheck warnings in bash completion file (SC2207)

## [1.3.0] - 2025-12-18

### Changed
- Rewrote README to be user-focused (reduced from 208 to 128 lines)
- Streamlined help text (reduced from 50 to 33 lines)
- Updated internal documentation

## [1.2.1] - 2025-12-17

### Added
- PATH security hardening
- Secure temporary file handling with `mktemp`
- Signal handling for clean interruption (SIGINT, SIGTERM)
- Proper exit codes (0=success, 1=error, 2=too many args, 22=invalid option)

### Changed
- Follows BCS (Bash Coding Standard) v1.2.0
- Uses `du -sb` for accurate byte-level size calculation
- Output sorted smallest to largest (largest at bottom for easy viewing)

## [1.0.0] - 2025-12-01

### Added
- Initial release
- Display directory sizes in human-readable format (IEC units)
- Tab-separated output for easy parsing
- Support for relative and absolute paths
- Permission error handling (continues with accessible content)

[1.4.1]: https://github.com/Open-Technology-Foundation/dux/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/Open-Technology-Foundation/dux/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/Open-Technology-Foundation/dux/compare/v1.2.1...v1.3.0
[1.2.1]: https://github.com/Open-Technology-Foundation/dux/compare/v1.0.0...v1.2.1
[1.0.0]: https://github.com/Open-Technology-Foundation/dux/releases/tag/v1.0.0
