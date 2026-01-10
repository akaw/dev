# ddev developer shortcuts

Bash script that provides shortcuts for frequently used `ddev` and `symfony` commands.

**Version:** 1.3.0

This repository contains:

- **`dev.sh`** - For local development with ddev/Symfony

## Features

- Simplified commands for ddev operations
- Release version management via Git tags
- Automatic version numbering (e.g. release:patch => v1.0.(1+1))
- Automatic updates via `upgrade` command

## Installation

1. Clone the repository
2. Include in `.bashrc` or `.zshrc`:
   ```bash
   if [ -f /path/to/dev.sh ]; then
       source /path/to/dev.sh
   fi
   ```
3. Use the script:
   ```bash
   dev [command]
   ```

## Upgrade

The script can be updated using the `upgrade` command:

```bash
dev upgrade
```

The command automatically checks for updates from the repository and installs them with SHA256 hash verification.

## Usage

### dev.sh (Local Development)

Running dev without known commands executes `ddev exec`.

### Available Commands (dev.sh)

#### Cache & Build
- `cc`, `ca:cl`, `cache:clear`, `cacl` - Clear cache
- `b`, `build`, `np:bu`, `npm:build` - Build assets
- `ccb`, `ca:cl:bu`, `cache:clear:build` - Clear cache and build assets
- `cr`, `ca:rm`, `cache:remove`, `carm` - Remove cache directory

#### Development
- `u`, `up` - Start OrbStack, ddev, Sequel Ace, Mailpit, Website and Cursor
- `d`, `down` - Stop ddev and OrbStack
- `r`, `restart` - Restart ddev
- `s` - SSH into container
- `st` `status`, `stat` - Show status
- `e`, `exec` - Execute command in container
- `c`, `console` - Run console command
- `ow`, `web`, `site`, `website`, `open:website`  - Open website
- `l`, `logs`, `show:logs`, `lo:sh` - View logs
- `tl`, `tail:logs`, `lo:ta`, `lota` - Tail logs

#### Database & Migrations
- `mm`, `dmm`, `migrate`, `mig`, `do:mi:mi` - Run migrations
- `sql`, `query`, `dbquery`, `dqs`, `do:qu:sq` - Execute SQL query

#### Messenger
- `mc`, `me:co`, `messenger:consume` - Consume all queues
- `mf`, `me:fa`, `messenger:failed` - Consume failed queue
- `mh`, `me:hi`, `messenger:high` - Consume high priority queue
- `mn`, `me:no`, `messenger:normal` - Consume normal priority queue
- `md`, `me:de`, `messenger:default` - Consume scheduler queue
- `ma`, `me:al`, `messenger:all` - Consume all queues
- `ms`, `me:st`, `messenger:stats` - Show messenger queue stats

#### Services
- `seq`, `start:sequelace`, `se` - Run Sequel Ace
- `mail`, `mailhog`, `op:ma`, `open:mailhog` - Open Mailhog

#### Testing
- `t`, `test`, `tests`, `phpunit`, `php:phpunit` - Run PHPUnit tests

#### Release Management
- `release:version`, `re:ve`, `reve` - Show latest version
- `release:patch`, `re:pa`, `repa` - Create patch release
- `release:minor`, `re:mi`, `remi` - Create minor release
- `release:major`, `re:ma`, `rema` - Create major release

#### Other
- `reload` - Reload dev environment
- `upgrade` - Upgrade script to latest version
- `help`, `-h`, `--help` - Show help message

## Repository

https://github.com/akaw/dev/

## Version

Current Version: **1.3.0**

Versions can be retrieved directly from the script:

```bash
grep "^# Version:" admin.sh
```