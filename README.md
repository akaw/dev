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

The script provides various commands to simplify development workflows. By default, all commands run within the ddev environment using `ddev exec`.

### Available Commands

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
- `help`, `-h`, `--help` - Show help message

## Version

1.0.0

## Author

André Witte

## Repository

https://github.com/akaw/dev/
