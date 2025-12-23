#!/usr/bin/env bash

# This script provides shortcuts for common ddev, symfony and other tools commands.
#
# Author: Andre Witte
#
# Description: dDEV symfony dev shortening tools
# Usage: dev [OPTIONS]
# Version: 1.0.0
# https://github.com/akaw/dev/

VERSION="1.0.0"

# Hilfsfunktion: Liest die neueste Versionsnummer aus Git-Tags
_get_latest_version() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "0.0.0"
        return 1
    fi
    
    # Finde alle Tags die dem Format vX.Y.Z entsprechen und sortiere sie
    local latest_tag=$(git tag -l | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n 1)
    
    if [[ -z "$latest_tag" ]]; then
        echo "0.0.0"
        return 0
    fi
    
    # Entferne das 'v' Präfix
    local version="${latest_tag#v}"
    
    # Validiere dass das Ergebnis korrekt ist
    if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "$version"
    else
        echo "0.0.0"
    fi
}

# Hilfsfunktion: Validiert Versionsnummer-Format
_validate_version() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Invalid version format. Expected format: major.minor.patch (e.g., 1.2.3)" >&2
        return 1
    fi
    return 0
}

# Hilfsfunktion: Inkrementiert Versionsnummer basierend auf Release-Typ
_increment_version() {
    local version="$1"
    local release_type="$2"
    
    IFS='.' read -r major minor patch <<< "$version"
    
    case "$release_type" in
        patch)
            patch=$((patch + 1))
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        *)
            echo "Error: Invalid release type: $release_type" >&2
            return 1
            ;;
    esac
    
    echo "$major.$minor.$patch"
}

# Hilfsfunktion: Erstellt Release-Tag und pusht ihn
_create_release_tag() {
    local version="$1"
    local release_type="$2"
    
    # Validiere Versionsnummer
    if ! _validate_version "$version"; then
        return 1
    fi
    
    local tag_name="v$version"
    
    # Prüfe ob Tag bereits existiert
    if git rev-parse "$tag_name" > /dev/null 2>&1; then
        echo "Error: Tag $tag_name already exists" >&2
        return 1
    fi
    
    # Erstelle annotierten Tag
    if ! git tag -a "$tag_name" -m "Release version $version ($release_type)"; then
        echo "Error: Failed to create tag $tag_name" >&2
        return 1
    fi
    
    # Push Tag zu origin
    if ! git push origin "$tag_name"; then
        echo "Error: Failed to push tag $tag_name to origin" >&2
        echo "Tag was created locally but push failed. You can try: git push origin $tag_name" >&2
        return 1
    fi
    
    echo "Successfully created and pushed tag $tag_name"
    return 0
}

# Function to upgrade the script
_upgrade() {
    local script_path="${BASH_SOURCE[0]}"
    echo "[INFO] Checking for updates..."

    # Temporary files for downloads
    local temp_script="/tmp/dev_new_version"
    local temp_hash="/tmp/dev_new_version.sha256"

    # Check current version against latest version first
    local latest_version
    if ! latest_version=$(curl -s -m 5 "https://raw.githubusercontent.com/akaw/dev/main/dev.sh" | grep -m 1 "^# Version:" | awk '{print $NF}'); then
        echo "[ERROR] Could not check for updates. Please check your internet connection." >&2
        echo "[INFO] Possible solutions:" >&2
        echo "[INFO]   - Check your internet connection" >&2
        echo "[INFO]   - Verify firewall settings" >&2
        echo "[INFO]   - Try again later" >&2
        return 1
    fi
    
    # Validate version format
    if [[ ! "$latest_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "[ERROR] Invalid version format received from server: $latest_version" >&2
        return 1
    fi

    if [[ "$latest_version" == "$VERSION" ]]; then
        echo "[INFO] You already have the latest version ($VERSION)."
        return 0
    fi

    echo "[INFO] New version found: $latest_version (current: $VERSION)"
    echo "[INFO] Downloading update..."

    # Download new version with better error handling
    if ! curl -s -o "$temp_script" "https://raw.githubusercontent.com/akaw/dev/main/dev.sh"; then
        echo "[ERROR] Download of new version failed" >&2
        echo "[INFO] Please check your internet connection and try again" >&2
        return 1
    fi

    if ! curl -s -o "$temp_hash" "https://raw.githubusercontent.com/akaw/dev/main/dev.sh.sha256"; then
        echo "[ERROR] Download of hash file failed" >&2
        rm -f "$temp_script"
        echo "[INFO] Please check your internet connection and try again" >&2
        return 1
    fi
    
    # Verify downloaded files are not empty
    if [[ ! -s "$temp_script" ]]; then
        echo "[ERROR] Downloaded script file is empty" >&2
        rm -f "$temp_script" "$temp_hash"
        return 1
    fi
    
    if [[ ! -s "$temp_hash" ]]; then
        echo "[ERROR] Downloaded hash file is empty" >&2
        rm -f "$temp_script" "$temp_hash"
        return 1
    fi

    # Verify hash
    local expected_hash
    expected_hash=$(cat "$temp_hash")
    local actual_hash

    # Validate expected hash format
    if [[ ! "$expected_hash" =~ ^[a-f0-9]{64}$ ]]; then
        echo "[ERROR] Invalid hash format received: $expected_hash" >&2
        rm -f "$temp_script" "$temp_hash"
        return 1
    fi

    if command -v shasum >/dev/null 2>&1; then
        # macOS typically uses shasum
        if ! actual_hash=$(shasum -a 256 "$temp_script" 2>/dev/null | awk '{print $1}'); then
            echo "[ERROR] Failed to calculate SHA256 hash using shasum" >&2
            rm -f "$temp_script" "$temp_hash"
            return 1
        fi
    elif command -v sha256sum >/dev/null 2>&1; then
        # Linux typically uses sha256sum
        if ! actual_hash=$(sha256sum "$temp_script" 2>/dev/null | awk '{print $1}'); then
            echo "[ERROR] Failed to calculate SHA256 hash using sha256sum" >&2
            rm -f "$temp_script" "$temp_hash"
            return 1
        fi
    else
        echo "[ERROR] No SHA256 utility found (shasum or sha256sum required)" >&2
        echo "[INFO] Please install a SHA256 utility and try again" >&2
        rm -f "$temp_script" "$temp_hash"
        return 1
    fi

    if [[ "$actual_hash" != "$expected_hash" ]]; then
        echo "[ERROR] Hash verification failed! The update might be compromised." >&2
        echo "[ERROR] Expected: $expected_hash" >&2
        echo "[ERROR] Actual: $actual_hash" >&2
        echo "[INFO] This could indicate:" >&2
        echo "[INFO]   - Network corruption during download" >&2
        echo "[INFO]   - Compromised update server" >&2
        echo "[INFO]   - Man-in-the-middle attack" >&2
        rm -f "$temp_script" "$temp_hash"
        return 1
    fi

    # Create backup with error handling
    if ! cp "$script_path" "${script_path}.backup"; then
        echo "[ERROR] Failed to create backup of current script" >&2
        rm -f "$temp_script" "$temp_hash"
        return 1
    fi

    # Remove update marker to force version check on next run
    rm -f "/tmp/dev_update_check_$(date +%Y%m%d)" 2>/dev/null

    # Install new version
    if mv "$temp_script" "$script_path"; then
        if ! chmod +x "$script_path"; then
            echo "[ERROR] Failed to set executable permissions on updated script" >&2
            # Restore backup
            mv "${script_path}.backup" "$script_path"
            rm -f "$temp_hash"
            return 1
        fi
        
        rm -f "$temp_hash"
        echo "[INFO] Update successful!"
        
        # Get the new version directly from the script
        local new_version
        if new_version=$(grep -m 1 "^VERSION=" "$script_path" | cut -d'"' -f2); then
            VERSION="$new_version"
            echo "[INFO] New version: ${VERSION}"
        else
            echo "[WARN] Could not determine new version from updated script" >&2
        fi
        
        echo "[INFO] Please restart your shell or run 'hash -r' to clear command cache."
    else
        echo "[ERROR] Failed to install updated script" >&2
        echo "[INFO] Restoring backup..." >&2
        if ! mv "${script_path}.backup" "$script_path"; then
            echo "[ERROR] CRITICAL: Failed to restore backup! Script may be corrupted." >&2
            echo "[INFO] Please manually restore from: ${script_path}.backup" >&2
        fi
        rm -f "$temp_script" "$temp_hash"
        return 1
    fi

    rm -f "${script_path}.backup"
    return 0
}

dev() {
    case "$1" in
        s)
            command ddev ssh
            ;;
        u|up)
            command open -g -a OrbStack && sleep 5 && command ddev start && command ddev status && command ddev sequelace && command ddev mailpit && command ddev launch && command cursor .
            ;;
        d|down)
            command ddev stop && command close -a OrbStack
            ;;
        e)
            shift
            command ddev exec "$@"
            ;;
        c)
            shift
            command ddev console "$@"
            ;;
        r)
            command ddev restart
            ;;
        stat|st)
            command ddev status
            ;;
        open:sequelace|op:se|opse|os|se|seq)
            command ddev sequelace
            ;;
        open:website|op:we|opwe|ow|website|site|web)
            command ddev launch
            ;;
        open:mailhog|op:ma|opma|om|mail)
            command ddev mailhog
            ;;
        cache:clear|ca:cl|cacl|cc)
            command ddev exec bin/console cache:clear
            ;;
        cache:clear:build|ca:cl:bu|caclbu|ccb)
            command ddev exec bin/console cache:clear && command ddev exec npm run build
            ;;
        cache:remove|ca:rm|carm|cr)
            command ddev exec rm -rf var/cache/*
            ;;
        npm:build|np:bu|build|b)
            command ddev exec npm run build
            ;;
        messenger:consume|me:co|mc)
            command ddev exec bin/console messenger:consume -vv
            ;;
        messenger:failed|me:fa|mf)
            command ddev exec bin/console messenger:consume failed -vv
            ;;
        messenger:high|me:hi|mh)
            command ddev exec bin/console messenger:consume async_priority_high -vv
            ;;
        messenger:normal|me:no|mn)
            command ddev exec bin/console messenger:consume async_priority_normal -vv
            ;;
        messenger:default|me:de|md)
            command ddev exec bin/console messenger:consume scheduler_default -vv
            ;;
        messenger:all|me:al|ma)
            command ddev exec bin/console messenger:consume async_priority_high async_priority_normal scheduler_default failed -vv
            ;;
        messenger:stats|me:st|ms)
            command ddev exec bin/console messenger:stats 
            ;;
        logs:show|lo:sh|losh|ls|show:logs|sh:lo|shlo|l|logs)
            local log_date="${2:-$(date +%Y-%m-%d)}"
            if command ddev exec test -f "/var/www/html/var/log/dev-${log_date}.log"; then
                command ddev exec tail "/var/www/html/var/log/dev-${log_date}.log"
            else
                command ddev exec tail "/var/www/html/var/log/dev.log"
            fi
            ;;
        logs:tail|lo:ta|lota|lt|tail:logs|ta:lo|talo|tl)
            local log_date="${2:-$(date +%Y-%m-%d)}"
            if command ddev exec test -f "/var/www/html/var/log/dev-${log_date}.log"; then
                command ddev exec tail -f "/var/www/html/var/log/dev-${log_date}.log"
            else
                command ddev exec tail -f "/var/www/html/var/log/dev.log"
            fi
            ;;
        doctrine:migrations:migrate|do:mi:mi|domimi|dmm|migrate|mig|mm)
            command ddev exec bin/console doctrine:migrations:migrate --no-interaction
            ;;
        doctrine:query:sql|do:qu:sq|dqs|dbquery|query|sql)
            command ddev exec bin/console doctrine:query:sql "$2"
            ;;
        php:phpunit|phpunit|test|tests|t)
            command ddev exec php vendor/bin/phpunit
            ;;
        release:version|re:ve|reve)
            echo "Latest version: $(_get_latest_version)"
            ;;
        release:patch|re:pa|repa)
            if [[ -z "$2" ]]; then
                # Automatische Versionsnummern-Verwaltung
                local current_version=$(_get_latest_version)
                local new_version=$(_increment_version "$current_version" "patch")
                echo "Creating patch release: $current_version -> $new_version"
                _create_release_tag "$new_version" "patch"
            else
                # Manuelle Versionsnummer
                _create_release_tag "$2" "patch"
            fi
            ;;
        release:minor|re:mi|remi)
            if [[ -z "$2" ]]; then
                # Automatische Versionsnummern-Verwaltung
                local current_version=$(_get_latest_version)
                local new_version=$(_increment_version "$current_version" "minor")
                echo "Creating minor release: $current_version -> $new_version"
                _create_release_tag "$new_version" "minor"
            else
                # Manuelle Versionsnummer
                _create_release_tag "$2" "minor"
            fi
            ;;
        release:major|re:ma|rema)
            if [[ -z "$2" ]]; then
                # Automatische Versionsnummern-Verwaltung
                local current_version=$(_get_latest_version)
                local new_version=$(_increment_version "$current_version" "major")
                echo "Creating major release: $current_version -> $new_version"
                _create_release_tag "$new_version" "major"
            else
                # Manuelle Versionsnummer
                _create_release_tag "$2" "major"
            fi
            ;;
        reload)
            source ~/bin/dev.sh
            ;;
        upgrade)
            _upgrade
            ;;
        help|-h|--help)
            echo "Usage: dev [command]"
            echo "Default command: ddev exec [command]."
            echo ""
            echo "Cache & Build:"
            echo "  cc, ca:cl, cache:clear, cacl           - Clear cache"
            echo "  b, build, np:bu, npm:build             - Build assets"
            echo "  ccb, ca:cl:bu, cache:clear:build       - Clear cache and build assets"
            echo "  cr, ca:rm, cache:remove, carm          - Remove cache directory"
            echo ""
            echo "Development:"
            echo "  u, up                                  - Start OrbStack, ddev, Sequel Ace, Mailpit, Website and Cursor"
            echo "  d, down                                - Stop ddev and OrbStack"
            echo "  r, restart                             - Restart ddev"
            echo "  s                                      - SSH into container"
            echo "  status, stat, st                       - Show status"
            echo "  e, exec                                - Execute command in container"
            echo "  c, console                             - Run console command"
            echo "  web, site, website, open:website, ow   - Open website"
            echo "  l, logs, show:logs, lo:sh              - View logs"
            echo "  tl, tail:logs, lo:ta, lota             - Tail logs"
            echo ""
            echo "Database & Migrations:"
            echo "  mm, dmm, migrate, mig, do:mi:mi        - Run migrations"
            echo "  sql, query, dbquery, dqs, do:qu:sq     - Execute SQL query"
            echo ""
            echo "Messenger:"
            echo "  mc, me:co, messenger:consume           - Consume all queues"
            echo "  mcfa, me:co:fa, messenger:failed       - Consume failed queue"
            echo "  mh, me:hi, messenger:high              - Consume high priority queue"
            echo "  mn, me:no, messenger:normal            - Consume normal priority queue"
            echo "  md, me:de, messenger:default           - Consume scheduler queue"
            echo "  ma, me:al, messenger:all               - Consume all queues"
            echo "  ms, me:st, messenger:stats             - Show messenger queue stats"
            echo ""
            echo "Services:"
            echo "  seq, se, open:sequelace                - Run Sequel Ace"
            echo "  mail, mailhog, op:ma, open:mailhog     - Open Mailhog"
            echo ""
            echo "Testing:"
            echo "  t, test, tests, phpunit, php:phpunit   - Run PHPUnit tests"
            echo ""
            echo "Release Management:"
            echo "  release:version, re:ve, reve           - Show latest version"
            echo "  release:patch, re:pa, repa             - Create patch release"
            echo "  release:minor, re:mi, remi             - Create minor release"
            echo "  release:major, re:ma, rema             - Create major release"
            echo ""
            echo "Other:"
            echo "  upgrade                                - Upgrade dev script to latest version"
            echo "  reload                                 - Reload dev environment"
            echo "  help, -h, --help                       - Show this help"
            ;;
        *)
            command ddev exec "$@"
            ;;
    esac
}

# zsh completion for dev
if [[ -n $ZSH_VERSION ]]; then
    _dev() {
        local -a cmds
        cmds=(
            cache:clear
            cache:clear:build
            build
            up down
            status
            mailhog
            open:mailhog
            open:website
            open:sequelace
            seq
            messenger:consume
            messenger:failed
            messenger:high
            messenger:normal
            messenger:default
            messenger:all
            messenger:stats
            logs
            show:logs
            tail:logs
            logs:tail
            logs:show
            cache:remove
            npm:build
            doctrine:migrations:migrate
            migrate
            sql dbquery query
            phpunit php:phpunit test tests
            release:version
            release:patch
            release:minor
            release:major
            reload
            -h --help
        )
        compadd -a cmds
    }
    compdef _dev dev
fi