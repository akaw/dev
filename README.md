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
2. **(Optional)** Skript ausführbar machen (beim Sourcing nicht technisch erforderlich, aber empfohlen):
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

**Hinweis:** Beim Sourcing wird das Skript nicht als ausführbares Programm gestartet, sondern direkt in die Shell geladen. Daher ist `chmod +x` technisch nicht erforderlich, aber wird als gute Praxis empfohlen.

### admin.sh (Server-Management)

**Wichtig:** Das Skript muss am Ende der `.bashrc` gesourced werden, damit Umgebungsvariablen bereits gesetzt sind.

1. Skript auf den Server kopieren (z.B. nach `/root/bin/admin.sh`)
2. **(Optional)** Ausführbar machen (beim Sourcing nicht technisch erforderlich, aber empfohlen):
   ```bash
   chmod +x /root/bin/admin.sh
   ```
3. In `.bashrc` am Ende einbinden (nach der CURRENT_PATH Variable!):
   ```bash
   # CURRENT_PATH setzen (erforderlich für admin.sh)
   export CURRENT_PATH=/var/www/example.com/deploy/current
   
   # Oder mit Variablen-Expansion:
   # export DEPLOY_PATH=/var/www/example.com/deploy
   # export CURRENT_PATH=$DEPLOY_PATH/current
   
   # admin.sh am Ende sourcen
   if [ -f /root/bin/admin.sh ]; then
       source /root/bin/admin.sh
   fi
   ```
4. Nach dem Login kann das Skript verwendet werden:
   ```bash
   admin [command]
   ```

**Hinweis:** Die Reihenfolge ist wichtig! `CURRENT_PATH` muss vor dem Sourcing von `admin.sh` gesetzt werden, damit das Skript korrekt funktioniert.

## Umgebungsvariablen (admin.sh)

Für die Nutzung von `admin.sh` ist **nur `CURRENT_PATH` erforderlich**. Diese Variable sollte in `.bashrc` gesetzt werden:

- `CURRENT_PATH` - Pfad zum aktuellen Deployment (z.B. `/var/www/example.com/deploy/current`)

Das Skript verwendet `CURRENT_PATH` für alle Symfony-Befehle (Cache, Console, Messenger, Logs, etc.).

**Beispiel in `.bashrc`:**
```bash
export CURRENT_PATH=/var/www/example.com/deploy/current
```

Oder mit Variablen-Expansion:
```bash
export DEPLOY_PATH=/var/www/example.com/deploy
export CURRENT_PATH=$DEPLOY_PATH/current
```

**Hinweis:** Die Variablen `DEPLOY_PATH`, `DEPLOY_USER`, `WEB_USER` und `SHARED_PATH` werden von `admin.sh` **nicht verwendet**. Sie können jedoch für andere Deployment-Skripte oder Tools nützlich sein.

Das Skript erstellt automatisch ein `current`-Alias, das zu `CURRENT_PATH` navigiert, wenn die Variable gesetzt ist.

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
- ✅ Kein `chmod +x` erforderlich: Beim Sourcing wird das Skript direkt in die Shell geladen, nicht als ausführbares Programm gestartet

**PATH-basierte Installation wäre:**
- ❌ Langsamer (Subshell bei jedem Aufruf)
- ❌ Kann keine Shell-Funktionen/Aliasse direkt definieren
- ❌ Completion muss anders konfiguriert werden
- ❌ Mehr Isolation, aber weniger Shell-Integration
- ❌ Benötigt `chmod +x` und Shebang (`#!/bin/bash`)

**Wichtig beim Sourcing:**
- Das Skript wird nicht als ausführbares Programm gestartet, sondern direkt in die Shell geladen
- Daher ist `chmod +x` **technisch nicht erforderlich**, wird aber als gute Praxis empfohlen
- Das Shebang (`#!/bin/bash`) wird beim Sourcing ignoriert, aber schadet auch nicht

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
- `set:current`, `se:cu`, `sc` - Set CURRENT_PATH path temporarily for the current shell session (for switching between different web projects)
- `reload` - Reload admin environment
- `upgrade` - Upgrade script to latest version
- `-h`, `--help` - Show help message

**Hinweis:** Viele Befehle benötigen `sudo`-Rechte. Stellen Sie sicher, dass Sie die entsprechenden Berechtigungen haben.

### Sudo-Befehle für admin.sh

Alle `admin.sh`-Befehle, die `sudo`-Rechte benötigen, und die von ihnen ausgeführten sudo-Befehle:

#### Supervisor-Befehle

- **`supervisor:reload`**, `su:rd`
  - `sudo supervisorctl reread && sudo supervisorctl update && sudo supervisorctl restart all && sudo supervisorctl status`

- **`supervisor:stop`**, `su:sp`
  - `sudo supervisorctl stop all && sudo supervisorctl status`

- **`supervisor:start`**, `su:st`
  - `sudo supervisorctl start all && sudo supervisorctl status`

- **`supervisor:status`**, `su:ss`
  - `sudo supervisorctl status`

#### Apache-Befehle

- **`apache:restart`**, `ap:rs`
  - `sudo systemctl restart apache2`

- **`apache:status`**, `ap:st`
  - `sudo systemctl status apache2`

- **`apache:start`**, `ap:sp`
  - `sudo systemctl start apache2`

- **`apache:stop`**, `ap:ss`
  - `sudo systemctl stop apache2`

- **`apache:reload`**, `ap:rl`
  - `sudo systemctl reload apache2`

- **`apache:test`**, `ap:te`
  - `sudo apache2ctl configtest`

#### Certbot/SSL-Befehle

- **`cert:renew`**, `cb:rw`
  - `sudo certbot renew --quiet --deploy-hook "sudo systemctl reload apache2"`

- **`cert:status`**, `cb:st`
  - `sudo certbot certificates`

- **`cert:install`**, `cb:in`
  - `sudo certbot --apache -d $domains --email $email --agree-tos --no-eff-email`

- **`cert:delete`**, `cb:dl`
  - `sudo certbot delete --cert-name $domain`

- **`cert:renewal-info`**, `cb:ri`
  - `sudo cat /etc/letsencrypt/renewal/*.conf`

- **`cert:refresh`**, `cb:rf`
  - `sudo certbot --manual --preferred-challenges dns --server https://acme-v02.api.letsencrypt.org/directory --email admin@calpager.com --domains *.calpager.com --agree-tos certonly`

**Hinweis zu `set:current`:** Dieser Befehl setzt `CURRENT_PATH` nur **temporär** für die aktuelle Shell-Session. Nach dem Schließen der Shell ist der Wert weg. Für eine dauerhafte Konfiguration muss `CURRENT_PATH` manuell in `.bashrc` gesetzt werden (siehe Installation oben).

**Alias:** Das Skript erstellt automatisch ein `current`-Alias, das zu `CURRENT_PATH` navigiert, wenn die Variable gesetzt ist.

## Author

Andre Witte and cursor

## Repository

https://github.com/akaw/dev/
