#!/bin/bash

# server.sh
# This script contains helper functions for managing the server environment.
# Usage: admin [command]
# Available commands:
#   apache:restart | ap:rs   - Restart Apache server
#   apache:status  | ap:st   - Show Apache server status
#   apache:start   | ap:sp   - Start Apache server
#   apache:stop    | ap:ss   - Stop Apache server
#   apache:reload  | ap:rl   - Reload Apache server configuration
#   certbot:renew  | cb:rw   - Renew SSL certificates using Certbot
#   cert:status    | cb:st   - Show SSL certificate status
#   cert:help      | cb:hp   - Show Certbot help
#   cert:install   | cb:in   - Install new SSL certificates
#   cert:delete    | cb:dl   - Delete SSL certificates
#   cert:renewal-info | cb:ri - Show certificate renewal information
#   cert:refresh    | cb:rf   - Manually refresh wildcard SSL certificate
#   cc               - Clear Symfony cache
#   cw               - Warmup Symfony cache
#   ccw              - Clear and warmup Symfony cache
#   mc | messenger  - Consume Symfony messenger messages
#   a | assets      - Install and dump Symfony assets
#   l | logs        - View various logs
#       t | test         - View test log
#       a | srv | apache - View Apache error log
#       s | sec | security - View security log
#       (default)       - View production log
#   supervisor:reload | su:rd   - Reload supervisor configuration
#   supervisor:stop   | su:sp    - Stop all supervisor processes
#   supervisor:start  | su:st    - Start all supervisor processes
#   supervisor:status | su:ss    - Show status of supervisor processes  
#   -h | --help                  - Show this help
# Example: admin supervisor:reload
# Note: This script requires sudo privileges for supervisor commands.
# Make sure to run it in an environment where you have the necessary permissions.
# Version: 1.2.2

# Pfad-Variable für das aktuelle Deployment hinzufügen
if [[ -n "$CURRENT_PATH" ]]; then
    alias current="cd \"$CURRENT_PATH\""
else
    # ask for current path
    echo "Please set the current project path to the .bashrc or .zshrc file."
    echo "or run the command 'set:current' to set the current project path to the current directory."
    echo "Example: set:current"
    echo "Example: set:current /var/www/project/current/"
fi

# Function to upgrade the script
_upgrade() {
    local script_path="${1:-}"
    
    # Determine script path if not provided
    if [[ -z "$script_path" || ! -f "$script_path" ]]; then
        script_path=""
        
        # Try BASH_SOURCE first
        [[ -n "${BASH_SOURCE[0]}" && -f "${BASH_SOURCE[0]}" ]] && script_path="${BASH_SOURCE[0]}"
        
        # Try common locations
        if [[ -z "$script_path" ]]; then
            for path in ~/bin/admin.sh "$HOME/bin/admin.sh" /usr/local/bin/admin.sh /opt/dev/admin.sh; do
                if [[ -f "$path" ]] && grep -q "^# Version:" "$path" 2>/dev/null; then
                    script_path="$path"
                    break
                fi
            done
        fi
        
        # Try which/command
        if [[ -z "$script_path" ]] && command -v admin >/dev/null 2>&1; then
            local which_path=$(which admin 2>/dev/null || command -v admin 2>/dev/null)
            [[ -f "$which_path" ]] && head -n 1 "$which_path" 2>/dev/null | grep -q "^#!" && script_path="$which_path"
        fi
        
        # Try $0 as fallback
        [[ -z "$script_path" && -n "$0" && "$0" != "-"* && -f "$0" ]] && script_path="$0"
    fi
    
    # Validate script path
    if [[ -z "$script_path" || ! -f "$script_path" ]]; then
        echo "[ERROR] Could not determine script path. Please specify manually: admin upgrade /path/to/admin.sh" >&2
        return 1
    fi
    
    # Resolve to absolute path
    script_path=$(cd "$(dirname "$script_path")" && pwd)/$(basename "$script_path")
    
    echo "[INFO] Checking for updates..."
    local temp_script="/tmp/admin_new_version"
    local temp_hash="/tmp/admin_new_version.sha256"

    # Fetch and validate latest version
    local latest_version
    if ! latest_version=$(curl -s -m 5 "https://raw.githubusercontent.com/akaw/dev/main/admin.sh" | grep -m 1 "^# Version:" | awk '{print $NF}'); then
        echo "[ERROR] Could not check for updates. Please check your internet connection." >&2
        return 1
    fi
    
    [[ -z "$latest_version" || ! "$latest_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && {
        echo "[ERROR] Invalid version format: $latest_version" >&2
        return 1
    }

    # Check current version
    local current_version=$(grep -m 1 "^# Version:" "$script_path" 2>/dev/null | awk '{print $NF}')
    [[ ! "$current_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && current_version="0.0.0"

    if [[ "$latest_version" == "$current_version" ]]; then
        echo "[INFO] You already have the latest version ($current_version)."
        return 0
    fi

    echo "[INFO] New version found: $latest_version (current: $current_version)"
    echo "[INFO] Downloading update..."

    # Download files
    if ! curl -s -o "$temp_script" "https://raw.githubusercontent.com/akaw/dev/main/admin.sh" || [[ ! -s "$temp_script" ]]; then
        echo "[ERROR] Download failed" >&2
        rm -f "$temp_script"
        return 1
    fi

    if ! curl -s -o "$temp_hash" "https://raw.githubusercontent.com/akaw/dev/main/admin.sh.sha256" || [[ ! -s "$temp_hash" ]]; then
        echo "[ERROR] Hash download failed" >&2
        rm -f "$temp_script" "$temp_hash"
        return 1
    fi

    # Verify hash
    local expected_hash=$(cat "$temp_hash")
    [[ ! "$expected_hash" =~ ^[a-f0-9]{64}$ ]] && {
        echo "[ERROR] Invalid hash format" >&2
        rm -f "$temp_script" "$temp_hash"
        return 1
    }

    local actual_hash
    if command -v shasum >/dev/null 2>&1; then
        actual_hash=$(shasum -a 256 "$temp_script" 2>/dev/null | awk '{print $1}')
    elif command -v sha256sum >/dev/null 2>&1; then
        actual_hash=$(sha256sum "$temp_script" 2>/dev/null | awk '{print $1}')
    else
        echo "[ERROR] No SHA256 utility found" >&2
        rm -f "$temp_script" "$temp_hash"
        return 1
    fi

    if [[ "$actual_hash" != "$expected_hash" ]]; then
        echo "[ERROR] Hash verification failed!" >&2
        echo "[ERROR] Expected: $expected_hash" >&2
        echo "[ERROR] Actual: $actual_hash" >&2
        rm -f "$temp_script" "$temp_hash"
        return 1
    fi

    # Install update
    rm -f "/tmp/admin_update_check_$(date +%Y%m%d)" 2>/dev/null
    
    if ! cp "$script_path" "${script_path}.backup"; then
        echo "[ERROR] Failed to create backup" >&2
        rm -f "$temp_script" "$temp_hash"
        return 1
    fi

    if mv "$temp_script" "$script_path" && chmod +x "$script_path"; then
        rm -f "$temp_hash"
        local new_version=$(grep -m 1 "^# Version:" "$script_path" 2>/dev/null | awk '{print $NF}')
        echo "[INFO] Update successful! New version: ${new_version:-unknown}"
        echo "[INFO] Please restart your shell or run 'hash -r' to clear command cache."
        rm -f "${script_path}.backup"
        return 0
    else
        echo "[ERROR] Installation failed. Restoring backup..." >&2
        mv "${script_path}.backup" "$script_path" 2>/dev/null
        rm -f "$temp_script" "$temp_hash"
        return 1
    fi
}

_set_current_path_interactive() {
    local new_path
    if [ -n "$2" ]; then
        new_path="$2"
        if [ ! -d "$new_path" ]; then
            echo "Error: Directory does not exist: $new_path" >&2
            return 1
        fi
    else
        echo "Use current directory as CURRENT_PATH? (y/n) [default: n]"
        read -r use_pwd
        if [ "$use_pwd" = "y" ]; then
            new_path="$PWD"
        else
            echo "Please enter the current project path:"
            read -r current_project_input
            if [ ! -d "$current_project_input" ]; then
                echo "Error: Directory does not exist: $current_project_input" >&2
                return 1
            fi
            new_path="$current_project_input"
        fi
    fi

    export CURRENT_PATH="$new_path"
    echo "CURRENT_PATH path set to $CURRENT_PATH"

    # Persist to shell config file
    local rc_file
    if [ -f ~/.bashrc ]; then
        rc_file=~/.bashrc
    elif [ -f ~/.zshrc ]; then
        rc_file=~/.zshrc
    else
        echo "~/.bashrc or ~/.zshrc not found"
        echo "Please create the file and add the following line:"
        echo "export CURRENT_PATH=\"$CURRENT_PATH\""
        return 1
    fi

    if grep -q "export CURRENT_PATH=" "$rc_file"; then
        # Update existing export line
        sed -i.bak '/export CURRENT_PATH=/c\export CURRENT_PATH="'"$CURRENT_PATH"'"' "$rc_file"
        echo "Updated CURRENT_PATH in $rc_file"
    else
        echo "Adding CURRENT_PATH to $rc_file"
        echo "export CURRENT_PATH=\"$CURRENT_PATH\"" >> "$rc_file"
    fi

    return 0
}

admin() {
    case "$1" in
        supervisor:reload|supervisor-reload|su:rd|surd)
            sudo supervisorctl reread && sudo supervisorctl update && sudo supervisorctl restart all && sudo supervisorctl status
            ;;
        supervisor:stop|supervisor-stop|su:sp|susp)
            sudo supervisorctl stop all && sudo supervisorctl status
            ;;
        supervisor:start|supervisor-start|su:st|sust)
            sudo supervisorctl start all && sudo supervisorctl status
            ;;
        supervisor:status|supervisor-status|su:ss|suss)
            sudo supervisorctl status
            ;;
        apache:restart|apache-restart|ap:rs|aprs)
            sudo systemctl restart apache2
            ;;
        apache:status|apache-status|ap:st|apst)
            sudo systemctl status apache2
            ;;
        apache:start|apache-start|ap:sp|apsp)
            sudo systemctl start apache2
            ;;
        apache:stop|apache-stop|ap:ss|apss)
            sudo systemctl stop apache2
            ;;
        apache:reload|apache-reload|ap:rl|aprl)
            sudo systemctl reload apache2
            ;;
        apache:test|apache-test|ap:te|apte)
            sudo apache2ctl configtest
            ;;
        cert:renew|cert-renew|cb:rw|cbrw)
            sudo certbot renew --quiet --deploy-hook "sudo systemctl reload apache2"
            ;;
        cert:status|cert-status|cb:st|cbst)
            sudo certbot certificates
            ;;
        cert:help|cert-help|cb:hp|cbhp)
            certbot --help
            ;;
        cert:install|cert-install|cb:in|cbin)
            echo "Please provide the domain names (space-separated):"
            read -r domains
            echo "Please provide your email address:"
            read -r email
            sudo certbot --apache -d $domains --email $email --agree-tos --no-eff-email
            ;;
        cert:delete|cert-delete|cb:dl|cbdl)
            echo "Please provide the domain name to delete:"
            read -r domain
            sudo certbot delete --cert-name $domain
            ;;
        cert:renewal-info|cert-renewal-info|cb:ri|cbri|cri)
            sudo cat /etc/letsencrypt/renewal/*.conf
            ;;
        cert:refresh|cert-refresh|cb:rf|cbrf|cr)
            sudo certbot --manual --preferred-challenges dns --server https://acme-v02.api.letsencrypt.org/directory --email admin@calpager.com --domains *.calpager.com --agree-tos certonly
            ;;
        cache:clear|cache-clear|ca:cl|cc)
            command "$CURRENT_PATH/bin/console" cache:clear
        ;;
        cache:warmup|cache-warmup|ca:wp|cw)
            command "$CURRENT_PATH/bin/console" cache:warmup --env=prod
            ;;
        cache:clear:warmup|cache-clear-warmup|ca:cl:wp|ccw)
            command "$CURRENT_PATH/bin/console" cache:clear && "$CURRENT_PATH/bin/console" cache:warmup --env=prod
            ;;
        messenger:consume|messenger-consume|me:co|mc)
            command "$CURRENT_PATH/bin/console" messenger:consume -vv
            ;;
        messenger:stats|messenger-stats|me:st|ms)
            command "$CURRENT_PATH/bin/console" messenger:stats 
            ;;    
        assets:install|assets-install|as:in|asin|ai)
            command "$CURRENT_PATH/bin/console" assets:install public --symlink && "$CURRENT_PATH/bin/console" assetic:dump
            ;;
        logs:show|logs-show|lo:sh|losh|ls|show:logs|sh:lo|shlo|l|logs)
            local log_date="${2:-$(date +%Y-%m-%d)}"
            if command test -f "$CURRENT_PATH/var/log/prod-${log_date}.log"; then
                command cat "$CURRENT_PATH/var/log/prod-${log_date}.log"
            else
                command cat "$CURRENT_PATH/var/log/prod.log"
            fi
            ;;
        logs:tail|logs-tail|lo:ta|lota|lt|tail:logs|ta:lo|talo|tl)
            local log_date="${2:-$(date +%Y-%m-%d)}"
            if command test -f "$CURRENT_PATH/var/log/prod-${log_date}.log"; then
                command tail -f "$CURRENT_PATH/var/log/prod-${log_date}.log"
            else
                command tail -f "$CURRENT_PATH/var/log/prod.log"
            fi
            ;;
        reload)
            local script_path="${BASH_SOURCE[0]}"
            # Fallback to $0 if BASH_SOURCE is not available (shouldn't happen in sourced scripts)
            if [[ -z "$script_path" ]]; then
                script_path="$0"
            fi
            # Get absolute path if it's a relative path
            if [[ ! "$script_path" =~ ^/ ]]; then
                local script_dir="$(dirname "$script_path")"
                local abs_dir
                if ! abs_dir="$(cd "$script_dir" 2>/dev/null && pwd)"; then
                    echo "[ERROR] Failed to resolve absolute path for script directory: $script_dir" >&2
                    return 1
                fi
                script_path="$abs_dir/$(basename "$script_path")"
            fi
            if [[ -f "$script_path" ]]; then
                source "$script_path"
                echo "[INFO] Admin script reloaded from: $script_path"
            else
                echo "[ERROR] Could not find admin script at: $script_path" >&2
                return 1
            fi
            ;;
        upgrade)
            # Allow optional script path as argument
            _upgrade "${2:-}"
            ;;
        set:current|set-current|se:cu|setcurrent|sc)
            _set_current_path_interactive "$@"
            ;;
        -h|--help)
            echo "Usage: admin [command]"
            echo ""
            echo "Apache:"
            echo "  apache:restart, ap:rs     - Restart Apache server"
            echo "  apache:status, ap:st      - Show Apache server status"
            echo "  apache:start, ap:sp       - Start Apache server"
            echo "  apache:stop, ap:ss        - Stop Apache server"
            echo "  apache:reload, ap:rl      - Reload Apache server configuration"
            echo "  apache:test, ap:te        - Test Apache configuration"
            echo ""
            echo "Supervisor:"
            echo "  supervisor:reload, su:rd  - Reload supervisor configuration"
            echo "  supervisor:stop, su:sp    - Stop all supervisor processes"
            echo "  supervisor:start, su:st   - Start all supervisor processes"
            echo "  supervisor:status, su:ss  - Show status of supervisor processes"
            echo ""
            echo "SSL Certificates:"
            echo "  certbot:renew, cb:rw      - Renew SSL certificates using Certbot"
            echo "  cert:status, cb:st        - Show SSL certificate status"
            echo "  cert:help, cb:hp          - Show Certbot help"
            echo "  cert:install, cb:in       - Install new SSL certificates"
            echo "  cert:delete, cb:dl        - Delete SSL certificates"
            echo "  cert:renewal-info, cb:ri  - Show certificate renewal information"
            echo "  cert:refresh, cb:rf       - Manually refresh wildcard SSL certificate"
            echo ""
            echo "Cache:"
            echo "  cache:clear, cc           - Clear Symfony cache"
            echo "  cache:warmup, cw          - Warmup Symfony cache"
            echo "  cache:clear:warmup, ccw   - Clear and warmup Symfony cache"
            echo ""
            echo "Messenger & Assets:"
            echo "  messenger:consume, mc, me:co - Consume Symfony messenger messages"
            echo "  messenger:stats, me:st, ms   - Show messenger queue stats"
            echo "  assets:install, as:in, ai    - Install and dump Symfony assets"
            echo ""
            echo "Logs (supports date argument YYYY-MM-DD):"
            echo "  logs:show, l, logs, lo:sh  - View Symfony logs"
            echo "  logs:tail, tl, lo:ta       - Tail Symfony logs"
            echo ""
            echo "Other:"
            echo "  set:current, se:cu, sc     - Set CURRENT_PATH path"
            echo "  reload                     - Reload admin environment"
            echo "  upgrade                    - Upgrade admin script to latest version"
            echo "  -h, --help                 - Show this help"
            ;;
        *)
            echo "Unknown command: $1"
            admin --help
            ;;
    esac
}

# Completion for admin command in bash
if [[ -n $BASH_VERSION ]]; then 
    _admin_completion() {
        local cur prev opts
        COMPREPLY=()
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"
        
        opts="supervisor-reload supervisor-stop supervisor-start supervisor-status apache-restart apache-status apache-start apache-stop apache-reload apache-test cert-renew cert-status cert-help cert-install cert-delete cert-renewal-info cert-refresh cache-clear cache-warmup cache-clear-warmup messenger-consume messenger-stats assets-install logs-show logs-tail set-current reload upgrade -h --help set-current"
        
        COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
        return 0
    }
    complete -F _admin_completion admin
fi

# zsh completion for dev
if [[ -n $ZSH_VERSION ]]; then
    _dev() {
        local -a cmds
        cmds=(
            supervisor:reload
            supervisor:stop
            supervisor:start
            supervisor:status
            apache:restart
            apache:status
            apache:start
            apache:stop
            apache:reload
            apache:test
            cert:renew
            cert:status
            cert:help
            cert:install
            cert:delete
            cert:renewal-info
            cert:refresh
            cache:clear
            cache:warmup
            cache:clear:warmup
            messenger:consume
            messenger:stats
            assets:install
            logs:show
            logs:tail
            set:current
            reload
            upgrade
            -h --help
        )
        compadd -a cmds
    }
    compdef _dev dev
fi

# End of server.sh