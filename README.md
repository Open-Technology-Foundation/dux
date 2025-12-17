# dux - Quick Directory Size Overview

[![Bash](https://img.shields.io/badge/Bash-5.2+-green.svg)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/license-GPL--3.0-blue.svg)](LICENSE)

**Find out where your disk space is going in seconds.**

```bash
$ dux /var
4.0KiB    /var/empty
52.0KiB   /var/mail
1.2MiB    /var/backups
23.4MiB   /var/cache
156.8MiB  /var/lib
512.3MiB  /var/log
```

## What It Does

`dux` shows you the size of each subdirectory, sorted smallest to largest. Use it to:

- **Find space hogs** - Quickly identify which directories are consuming disk space
- **Plan cleanup** - See at a glance what to delete or archive
- **Monitor growth** - Check which directories are growing over time

## Installation

```bash
git clone https://github.com/Open-Technology-Foundation/dux.git
cd dux
chmod +x dir-sizes

# Add to PATH (choose one):
sudo ln -s "$(pwd)/dir-sizes" /usr/local/bin/dux
# or
echo "export PATH=\"\$PATH:$(pwd)\"" >> ~/.bashrc
```

## Usage

```bash
dux [directory]    # Analyze directory (defaults to current)
dux -h             # Show help
dux -V             # Show version
```

### Common Tasks

**Where is my disk space going?**
```bash
dux ~              # Check home directory
dux /              # Check entire filesystem (may need sudo)
```

**Find the largest directories:**
```bash
dux /var | tail -5         # Show 5 largest in /var
sudo dux / | tail -10      # Show 10 largest on system
```

**Check a project for bloat:**
```bash
dux ~/projects/myapp       # Find large folders in project
```

**Pipe to other tools:**
```bash
dux . | grep -v node_modules   # Exclude node_modules
dux /home | tee sizes.txt      # Save output to file
```

## Output Format

```
<size>    <path>
```

- Sizes use IEC units: B, KiB, MiB, GiB, TiB
- Output is tab-separated (easy to parse with `cut`, `awk`)
- Sorted smallest to largest (largest at bottom for visibility)

## Handling Permissions

Permission errors appear on stderr but don't stop execution:

```bash
dux /var                   # Shows errors inline
dux /var 2>/dev/null       # Suppress errors (sizes may be incomplete)
sudo dux /var              # Full access to all directories
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error (invalid directory, failed to read) |
| 2 | Too many arguments |
| 22 | Invalid option |

## Requirements

- Bash 5.2+
- GNU coreutils (du, sort, numfmt)

## Why dux?

| | dux | du -h | ncdu | dust |
|--|-----|-------|------|------|
| Sorted output | Yes | No* | Yes | Yes |
| Human-readable | Yes | Yes | Yes | Yes |
| One command | Yes | No* | Yes | Yes |
| Interactive | No | No | Yes | No |
| Dependencies | coreutils | coreutils | ncurses | Rust |

*`du` requires piping through `sort -h` for sorted human-readable output

`dux` fills the gap between raw `du` output and full-featured tools like `ncdu`. It's the quick answer to "what's using my disk space?" without installing additional software.

## License

GPL-3.0 - See [LICENSE](LICENSE)

## See Also

- [ncdu](https://dev.yorhel.nl/ncdu) - Interactive disk usage analyzer
- [dust](https://github.com/bootandy/dust) - du + rust = dust
- [BASH Coding Standard](https://github.com/Open-Technology-Foundation/bash-coding-standard) - Coding standard used by this project
