# dDEV Symfony Dev Shortening Tools

Bash-Skripte die Shortcuts für häufig verwendete `ddev`, `symfony` und Server-Management-Befehle bereitstellen.

Dieses Repository enthält zwei Hauptskripte:

- **`dev.sh`** - Für lokale Entwicklung mit ddev/Symfony
- **`admin.sh`** - Für Server-Management und Production-Operationen

## Features

- Vereinfachte Befehle für ddev-Operationen
- Server-Management-Befehle (Apache, Supervisor, Certbot, etc.)
- Release-Versionsverwaltung via Git-Tags
- Automatische Versionsnummerierung (z.B. release:patch => v1.0.(1+1))
- Automatische Updates via `upgrade` Befehl

## Installation

### dev.sh (Lokale Entwicklung)

1. Repository klonen
2. Skript ausführbar machen:
   ```bash
   chmod +x dev.sh
   ```
3. In `.bashrc` oder `.zshrc` einbinden:
   ```bash
   if [ -f /pfad/zum/dev.sh ]; then
       source /pfad/zum/dev.sh
   fi
   ```
4. Skript verwenden:
   ```bash
   dev [command]
   ```

### admin.sh (Server-Management)

**Wichtig:** Das Skript muss am Ende der `.bashrc` gesourced werden, damit Umgebungsvariablen bereits gesetzt sind.

1. Skript auf den Server kopieren (z.B. nach `/root/bin/admin.sh`)
2. Ausführbar machen:
   ```bash
   chmod +x /root/bin/admin.sh
   ```
3. In `.bashrc` am Ende einbinden (nach den Export-Zeilen!):
   ```bash
   export DEPLOY_PATH=/var/www/example.com/deploy
   export DEPLOY_USER=deploy
   export WEB_USER=www-data
   
   export CURRENT_PATH=$DEPLOY_PATH/current
   export SHARED_PATH=$DEPLOY_PATH/shared
   
   # admin.sh am Ende sourcen
   if [ -f /root/bin/admin.sh ]; then
       source /root/bin/admin.sh
   fi
   ```
4. Nach dem Login kann das Skript verwendet werden:
   ```bash
   admin [command]
   ```

**Hinweis:** Die Reihenfolge ist wichtig! Die Export-Zeilen müssen vor dem Sourcing von `admin.sh` stehen, damit `CURRENT_PATH` korrekt gesetzt ist.

## Umgebungsvariablen (admin.sh)

Folgende Variablen sollten in `.bashrc` gesetzt werden:

- `DEPLOY_PATH` - Basis-Pfad für Deployments (z.B. `/var/www/example.com/deploy`)
- `DEPLOY_USER` - Benutzer für Deployments (z.B. `deploy`)
- `WEB_USER` - Web-Server-Benutzer (z.B. `www-data`)
- `CURRENT_PATH` - Pfad zum aktuellen Deployment (z.B. `$DEPLOY_PATH/current`)
- `SHARED_PATH` - Pfad für gemeinsam genutzte Dateien (z.B. `$DEPLOY_PATH/shared`)

Das Skript erstellt automatisch ein `current`-Alias, das zu `CURRENT_PATH` navigiert.

## Upgrade

Beide Skripte können mit dem `upgrade` Befehl aktualisiert werden:

```bash
# dev.sh aktualisieren
dev upgrade

# admin.sh aktualisieren
admin upgrade
```

Der Befehl prüft automatisch auf Updates vom Repository und installiert sie mit SHA256-Hash-Verifizierung.

## Sourcing vs. PATH-basierte Installation

Beide Skripte sind als Shell-Funktionen konzipiert und sollten via `source` in `.bashrc` oder `.zshrc` eingebunden werden, nicht über PATH.

### Warum Sourcing?

**Vorteile:**
- ✅ Schneller: Funktionen werden direkt in den Shell-Prozess geladen
- ✅ Shell-Features: Kann Completion-Funktionen für Bash/Zsh definieren
- ✅ Alias-Support: Kann Aliasse definieren (z.B. `current`-Alias in admin.sh)
- ✅ Shell-Variablen: Direkter Zugriff auf Shell-Variablen wie `CURRENT_PATH`
- ✅ Kein Subshell-Overhead bei jedem Aufruf

**PATH-basierte Installation wäre:**
- ❌ Langsamer (Subshell bei jedem Aufruf)
- ❌ Kann keine Shell-Funktionen/Aliasse direkt definieren
- ❌ Completion muss anders konfiguriert werden
- ❌ Mehr Isolation, aber weniger Shell-Integration

**Fazit:** Für interaktive Shell-Tools wie `dev` und `admin` ist **Sourcing die empfohlene Methode**.

## Usage

### dev.sh (Lokale Entwicklung)

Alle Befehle laufen standardmäßig innerhalb der ddev-Umgebung über `ddev exec`.

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

---

### admin.sh (Server-Management)

Befehle für Production-Server-Management mit Apache, Supervisor, Certbot und Symfony.

### Available Commands (admin.sh)

#### Apache
- `apache:restart`, `ap:rs` - Restart Apache server
- `apache:status`, `ap:st` - Show Apache server status
- `apache:start`, `ap:sp` - Start Apache server
- `apache:stop`, `ap:ss` - Stop Apache server
- `apache:reload`, `ap:rl` - Reload Apache server configuration
- `apache:test`, `ap:te` - Test Apache configuration

#### Supervisor
- `supervisor:reload`, `su:rd` - Reload supervisor configuration
- `supervisor:stop`, `su:sp` - Stop all supervisor processes
- `supervisor:start`, `su:st` - Start all supervisor processes
- `supervisor:status`, `su:ss` - Show status of supervisor processes

#### SSL Certificates (Certbot)
- `cert:renew`, `cb:rw` - Renew SSL certificates using Certbot
- `cert:status`, `cb:st` - Show SSL certificate status
- `cert:help`, `cb:hp` - Show Certbot help
- `cert:install`, `cb:in` - Install new SSL certificates
- `cert:delete`, `cb:dl` - Delete SSL certificates
- `cert:renewal-info`, `cb:ri` - Show certificate renewal information
- `cert:refresh`, `cb:rf` - Manually refresh wildcard SSL certificate

#### Symfony Cache
- `cache:clear`, `cc` - Clear Symfony cache
- `cache:warmup`, `cw` - Warmup Symfony cache
- `cache:clear:warmup`, `ccw` - Clear and warmup Symfony cache

#### Symfony Messenger & Assets
- `messenger:consume`, `mc`, `me:co` - Consume Symfony messenger messages
- `messenger:stats`, `me:st`, `ms` - Show messenger queue stats
- `assets:install`, `as:in`, `ai` - Install and dump Symfony assets

#### Logs (supports date argument YYYY-MM-DD)
- `logs:show`, `l`, `logs`, `lo:sh` - View Symfony logs
- `logs:tail`, `tl`, `lo:ta` - Tail Symfony logs

#### Other
- `set:current`, `se:cu`, `sc` - Set CURRENT_PATH path interactively
- `reload` - Reload admin environment
- `upgrade` - Upgrade script to latest version
- `-h`, `--help` - Show help message

**Hinweis:** Viele Befehle benötigen `sudo`-Rechte. Stellen Sie sicher, dass Sie die entsprechenden Berechtigungen haben.

**Alias:** Das Skript erstellt automatisch ein `current`-Alias, das zu `CURRENT_PATH` navigiert, wenn die Variable gesetzt ist.

## Version

- dev.sh: 1.2.6
- admin.sh: 1.2.6

## Author

Andre Witte

## Repository

https://github.com/akaw/dev/
