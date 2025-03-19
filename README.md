# Dux - Directory Usage Explorer

[![Bash](https://img.shields.io/badge/language-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/license-GPL--3.0-blue.svg)](LICENSE)

A set of efficient Bash utilities for exploring and visualizing directory sizes.

## Overview

The `dux` package consists of two complementary tools:

1. **dux**: A powerful wrapper for the `du` (disk usage) command that provides directory tree traversal, recursive size calculation, and customizable output formatting.

2. **dir-sizes**: A utility that displays directory sizes in human-readable format (KB, MB, GB, etc.) by using direct `du` calls for accurate measurements.

## Features

- **Fast Directory Traversal**: Efficiently scan directories and calculate sizes
- **Configurable Recursion**: Control how deep the directory tree is traversed
- **Human-Readable Output**: Convert raw bytes to human-readable formats
- **Customizable Display**: Sort by size, use number separators, and more
- **Error Handling**: Gracefully handle non-existent directories and edge cases

## Installation

1. Clone this repository:
   ```
   git clone https://github.com/username/dux.git
   ```

2. Make the scripts executable:
   ```
   chmod +x dux/dux dux/dir-sizes
   ```

3. Optionally, add to your PATH:
   ```
   export PATH="$PATH:$(pwd)/dux"
   ```

## Usage

### dux

Basic usage:
```
dux [options] [directory]
```

Example commands:
```bash
dux                     # Show sizes for current directory
dux -r 2 /home          # Recurse 2 levels into /home
dux -s -S /var          # Show sorted sizes with separators
dux --du -h /usr        # Pass -h to du for human-readable sizes
```

Options:
```
-r, --max_recurse depth  Maximum recursion depth
                         Use -1 for unlimited depth (max 99)
-s, --sep               Use number separator character in size output
-N, --nosep             Do not use number separator (default)
-f, --number_format fmt Set number format to 'sep' or 'nosep'
-R, --dir_root dir      Set the root directory for output
-S, --sort              Sort output by size (ascending)
-V, --version           Display version info
-h, --help              Display help message
--                      Treat all following arguments as directories
--du                    Pass all following arguments to 'du'
```

### dir-sizes

Basic usage:
```
dir-sizes [directory]
```

Example commands:
```bash
dir-sizes              # Show sizes for current directory subdirectories
dir-sizes /var         # Show sizes for /var subdirectories
dir-sizes | sort -h    # Sort by human-readable sizes
```

Options:
```
-h, --help    Display help message
```

## Output Format

### dux
```
<size> <level> <path> [<symlink-indicator>]
```

Where:
- `<size>` is the directory size in bytes
- `<level>` is the recursion level (0 for top level)
- `<path>` is the directory path
- `<symlink-indicator>` is * for symlinks

### dir-sizes
```
<size>  <path>
```

Where:
- `<size>` is the human-readable size (e.g., 128MB, 1.5GB)
- `<path>` is the directory path

## Testing

You can test the functionality with:

```bash
bash test-dux.sh        # Test all components
bash test-dux.sh dux    # Test only dux
bash test-dux.sh dir-sizes # Test only dir-sizes
```

## Author

Gary Dean, garydean@okusi.id

## License

This project is licensed under the GNU General Public License v3.0 (GPL-3.0) - see the [LICENSE](LICENSE) file for details.