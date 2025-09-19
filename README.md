# dir-sizes - Directory Size Analyzer

[![Bash](https://img.shields.io/badge/language-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/license-GPL--3.0-blue.svg)](LICENSE)

A fast and efficient Bash utility for analyzing and displaying directory sizes in human-readable format.

## Overview

`dir-sizes` is a streamlined directory size analyzer that calculates the total size of each subdirectory within a specified directory. It presents the results sorted by size in an easy-to-read format, making it simple to identify which directories are consuming the most disk space.

## Features

- **Recursive Size Calculation**: Accurately calculates the total size including all nested subdirectories
- **Human-Readable Output**: Automatically converts bytes to appropriate units (KB, MB, GB, etc.)
- **Sorted Results**: Displays directories sorted by size (smallest to largest) for easy analysis
- **Permission Handling**: Gracefully handles permission errors, showing warnings while continuing execution
- **Fast Performance**: Efficient implementation using native `du` command
- **Standards Compliant**: Follows strict BASH coding standards for reliability and safety
- **Security Hardened**: Implements PATH locking, secure temp files, and proper signal handling

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/username/dux.git
   cd dux
   ```

2. Make the script executable:
   ```bash
   chmod +x dir-sizes
   ```

3. Optionally, add to your PATH:
   ```bash
   # Add to ~/.bashrc or ~/.bash_profile
   export PATH="$PATH:/path/to/dux"
   ```

   Or create a symlink:
   ```bash
   sudo ln -s /path/to/dux/dir-sizes /usr/local/bin/dir-sizes
   ```

## Usage

Basic usage:
```bash
dir-sizes [directory]
```

### Examples

```bash
# Analyze current directory
dir-sizes

# Analyze specific directory
dir-sizes /var

# Analyze and show only the 10 largest directories
dir-sizes /usr | tail -10
```

### Command-Line Options

```
Options:
  -h, --help     Display help message and exit
  -V, --version  Display version information and exit

Arguments:
  directory      Directory to analyze (defaults to current directory)
```

### Output Format

```
<size>  <path>
```

Where:
- `<size>` is the human-readable size with IEC units (e.g., 128.5MiB, 1.2GiB)
- `<path>` is the absolute or relative path to the directory

Example output:
```
0.0B      	./.cache
56.7KB    	./.git
102.6KB   	./src
1.5MB     	./docs
23.4MB    	./data
```

## Behavior

### Size Calculation
- Uses `du -sb` to calculate actual disk usage in bytes
- Includes all nested subdirectories in the size calculation
- Provides the total recursive size for each immediate subdirectory

### Permission Handling
- Permission errors are reported to stderr but don't stop execution
- Directories that can't be fully read show the size of accessible contents

### Performance Notes
- Large directories with many files may take time to analyze
- The script must recursively calculate sizes, which involves reading directory metadata
- For very large filesystems, consider analyzing specific subdirectories

## Exit Codes

- `0` - Success
- `1` - General error (invalid directory, complete failure)
- `22` - Invalid command-line option

## Requirements

- Bash 5.2 or higher (uses modern Bash features)
- GNU coreutils 8.32+ (for numfmt IEC units)
- GNU coreutils (`du`, `cut`, `sort`, `numfmt`)
- Standard POSIX utilities

## Technical Details

The script follows strict BASH coding standards (v1.2.0 improvements):
- Uses `set -euo pipefail` with `shopt -s inherit_errexit` for robust error handling
- Implements proper variable scoping with typed declarations (`declare -i`, `declare --`)
- Secure temporary file handling with `mktemp` and automatic cleanup via traps
- PATH security hardening to prevent command injection
- Signal handling for clean interruption (SIGINT, SIGTERM)

## Comparison with Similar Tools

| Feature | dir-sizes | du | ncdu | dust |
|---------|-----------|-----|------|------|
| Human-readable | ✓ (IEC) | With -h | ✓ | ✓ |
| Sorted output | ✓ | With sort | ✓ | ✓ |
| Interactive | ✗ | ✗ | ✓ | ✗ |
| Recursive totals | ✓ | ✓ | ✓ | ✓ |
| Security hardened | ✓ | ✗ | ✗ | ✗ |
| Signal handling | ✓ | ✗ | ✓ | ✗ |
| Dependencies | Minimal | None | ncurses | Rust |
| Speed | Fast | Fast | Moderate | Fast |

## Troubleshooting

### Permission Denied Errors
If you see many "Permission denied" errors:
```bash
# Run with sudo for system directories
sudo dir-sizes /var

# Or suppress errors (not recommended, total sizes will be incorrect)
dir-sizes /var 2>/dev/null
```

### Slow Performance
For very large directories:
```bash
# Analyze specific subdirectories instead
dir-sizes /large/dir/specific-subdir

# Use timeout to limit execution time
timeout 30 dir-sizes /very/large/dir
```

## Development

### Running Tests
```bash
# Basic functionality test
dir-sizes /tmp

# Test with various directories
for dir in /tmp /var/log /home; do
  echo "Testing $dir:"
  dir-sizes "$dir" 2>/dev/null | head -5
done
```

### Code Style
This project follows the organization's BASH coding standards as defined in [BASH-CODING-STYLE](https://github.com/Open-Technology-Foundation/bash-coding-standard), including:
- Proper shebang (`#!/bin/bash`) with script description
- Critical safety settings (`inherit_errexit`, `shift_verbose`, `extglob`, `nullglob`)
- Consistent variable declarations with proper typing
- Standard utility functions (error handling, messaging)
- Comprehensive inline and usage documentation
- Security-first approach (PATH locking, mktemp usage)

## License

This project is licensed under the GNU General Public License v3.0 (GPL-3.0) - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built on GNU coreutils' robust `du` command
- Follows best practices from the Bash scripting community
- Inspired by the need for a simple, fast directory size analyzer

## See Also

- `du(1)` - The underlying disk usage command
- `ncdu` - Interactive ncurses-based disk usage analyzer
- `dust` - Modern du replacement written in Rust
- `duf` - Modern df replacement with better UI

