# dDEV Symfony Dev Shortening Tools

A Bash script that provides shortcuts for commonly used `ddev`, `symfony` and other CLI commands.

## Features

- Simplified commands for ddev operations (e.g., )
- Release version management via Git tags
- Automatic version numbering (e.g., release:patch => v1.0.(1+1))

## Installation

1. Clone the repository
2. Make the script executable:
   ```bash
   chmod +x dev.sh
   ```
3. Use the script with:
   ```bash
   ./dev.sh [OPTIONS]
   ```

## Upgrade

Use `dev upgrade` to update the script to the latest version. This command checks for updates from the repository and installs them automatically.

```bash
./dev.sh upgrade
```

## Usage

### Available Commands

The script provides various commands to simplify development workflows:

- **ddev commands**: Execute ddev operations without typing the full `ddev exec` prefix
- **symfony commands**: Quick access to Symfony CLI tools (e.g., `cc` for `cache:clear`)
- **dev u**: 
- **release commands**: Manage version releases with automatic Git tagging
    - `release:major` - Increment major version and push new tag
    - `release:minor` - Increment minor version and push new tag
    - `release:patch` - Increment patch version and push new tag

By default, all commands run within the ddev environment using `ddev exec`.


```bash
dev [OPTIONS]
```

## Version

1.0.0

## Author

André Witte

## Repository

https://github.com/akaw/dev/
