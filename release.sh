#!/usr/bin/env bash

# release.sh
# Release management script for dev.sh and admin.sh
# Usage: ./release.sh [type] [script]
#   type: patch, minor, major
#   script: dev, admin, or empty (both)
#
# Author: Andre Witte
# Version: 1.0.0

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script files
DEV_SCRIPT="dev.sh"
ADMIN_SCRIPT="admin.sh"
DEV_HASH="dev.sh.sha256"
ADMIN_HASH="admin.sh.sha256"

# Hilfsfunktion: Liest aktuelle Versionsnummer aus Skript-Header
_get_current_version() {
    local script_file="$1"
    
    if [[ ! -f "$script_file" ]]; then
        echo "Error: Script file not found: $script_file" >&2
        return 1
    fi
    
    local version=$(grep -m 1 "^# Version:" "$script_file" 2>/dev/null | awk '{print $NF}' || echo "")
    
    if [[ -z "$version" ]]; then
        echo "Error: Could not find version in $script_file" >&2
        return 1
    fi
    
    echo "$version"
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
    
    if ! _validate_version "$version"; then
        return 1
    fi
    
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
            echo "Error: Invalid release type: $release_type. Must be patch, minor, or major" >&2
            return 1
            ;;
    esac
    
    echo "$major.$minor.$patch"
}

# Hilfsfunktion: Aktualisiert Versionsnummer im Skript-Header
_update_script_version() {
    local script_file="$1"
    local new_version="$2"
    
    if ! _validate_version "$new_version"; then
        return 1
    fi
    
    if [[ ! -f "$script_file" ]]; then
        echo "Error: Script file not found: $script_file" >&2
        return 1
    fi
    
    # Backup erstellen
    local backup_file="${script_file}.backup"
    cp "$script_file" "$backup_file"
    
    # Versionsnummer aktualisieren (kompatibel mit macOS und Linux)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if sed -i '' "s/^# Version:.*/# Version: ${new_version}/" "$script_file" 2>/dev/null; then
            rm -f "$backup_file"
            echo "Updated version in $script_file to $new_version"
            return 0
        else
            echo "Error: Failed to update version in $script_file" >&2
            mv "$backup_file" "$script_file"
            return 1
        fi
    else
        # Linux und andere Unix-Systeme
        if sed -i "s/^# Version:.*/# Version: ${new_version}/" "$script_file" 2>/dev/null; then
            rm -f "$backup_file"
            echo "Updated version in $script_file to $new_version"
            return 0
        else
            echo "Error: Failed to update version in $script_file" >&2
            mv "$backup_file" "$script_file"
            return 1
        fi
    fi
}

# Hilfsfunktion: Generiert SHA256-Hash für ein Skript
_generate_sha256_hash() {
    local script_file="$1"
    local hash_file="$2"
    
    if [[ ! -f "$script_file" ]]; then
        echo "Error: Script file not found: $script_file" >&2
        return 1
    fi
    
    local hash
    
    if command -v shasum >/dev/null 2>&1; then
        # macOS typically uses shasum
        hash=$(shasum -a 256 "$script_file" 2>/dev/null | awk '{print $1}')
    elif command -v sha256sum >/dev/null 2>&1; then
        # Linux typically uses sha256sum
        hash=$(sha256sum "$script_file" 2>/dev/null | awk '{print $1}')
    else
        echo "Error: No SHA256 utility found (shasum or sha256sum required)" >&2
        return 1
    fi
    
    if [[ -z "$hash" ]]; then
        echo "Error: Failed to calculate SHA256 hash" >&2
        return 1
    fi
    
    # Validiere Hash-Format
    if [[ ! "$hash" =~ ^[a-f0-9]{64}$ ]]; then
        echo "Error: Invalid hash format: $hash" >&2
        return 1
    fi
    
    # Schreibe Hash in Datei
    echo "$hash" > "$hash_file"
    echo "Generated SHA256 hash: $hash_file"
    return 0
}

# Hilfsfunktion: Prüft Release-Voraussetzungen
_check_release_prerequisites() {
    local errors=0
    
    # Prüfe ob Git Repository vorhanden ist
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}Error: Not a git repository${NC}" >&2
        errors=$((errors + 1))
    fi
    
    # Prüfe ob Working Directory sauber ist
    if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
        echo -e "${YELLOW}Warning: Working directory has uncommitted changes${NC}" >&2
        echo "Please commit or stash your changes before creating a release." >&2
        errors=$((errors + 1))
    fi
    
    # Prüfe ob Remote origin konfiguriert ist
    if ! git remote get-url origin > /dev/null 2>&1; then
        echo -e "${YELLOW}Warning: No remote 'origin' configured${NC}" >&2
    fi
    
    # Prüfe ob Skripte existieren
    if [[ ! -f "$DEV_SCRIPT" ]]; then
        echo -e "${RED}Error: $DEV_SCRIPT not found${NC}" >&2
        errors=$((errors + 1))
    fi
    
    if [[ ! -f "$ADMIN_SCRIPT" ]]; then
        echo -e "${RED}Error: $ADMIN_SCRIPT not found${NC}" >&2
        errors=$((errors + 1))
    fi
    
    if [[ $errors -gt 0 ]]; then
        return 1
    fi
    
    return 0
}

# Hilfsfunktion: Generiert Changelog aus Git-Commits
_generate_changelog() {
    local current_version="$1"
    local new_version="$2"
    local release_type="$3"
    
    local tag_name="v${current_version}"
    local changelog=""
    
    # Prüfe ob Tag existiert
    if git rev-parse "$tag_name" > /dev/null 2>&1; then
        # Hole Commits seit letztem Tag
        local commits=$(git log "${tag_name}..HEAD" --pretty=format:"%s" 2>/dev/null)
        
        if [[ -n "$commits" ]]; then
            changelog="## Changes since ${tag_name}\n\n"
            
            # Gruppiere Commits nach Typ (konventionelle Commits)
            local features=""
            local fixes=""
            local docs=""
            local other=""
            
            while IFS= read -r commit; do
                if [[ "$commit" =~ ^feat(\(.+\))?: ]]; then
                    features="${features}- ${commit}\n"
                elif [[ "$commit" =~ ^fix(\(.+\))?: ]]; then
                    fixes="${fixes}- ${commit}\n"
                elif [[ "$commit" =~ ^(docs|doc)(\(.+\))?: ]]; then
                    docs="${docs}- ${commit}\n"
                else
                    other="${other}- ${commit}\n"
                fi
            done <<< "$commits"
            
            if [[ -n "$features" ]]; then
                changelog="${changelog}### Added\n${features}\n"
            fi
            
            if [[ -n "$fixes" ]]; then
                changelog="${changelog}### Fixed\n${fixes}\n"
            fi
            
            if [[ -n "$docs" ]]; then
                changelog="${changelog}### Documentation\n${docs}\n"
            fi
            
            if [[ -n "$other" ]]; then
                changelog="${changelog}### Other\n${other}\n"
            fi
        else
            changelog="## Changes since ${tag_name}\n\nNo changes detected.\n"
        fi
    else
        changelog="## Initial Release\n\nFirst release of the scripts.\n"
    fi
    
    echo -e "$changelog"
}

# Hauptfunktion: Erstellt Release
_create_release() {
    local release_type="$1"
    local target_script="$2"
    
    echo -e "${BLUE}=== Release Process Started ===${NC}\n"
    
    # Pre-Release Checks
    echo -e "${BLUE}Running pre-release checks...${NC}"
    if ! _check_release_prerequisites; then
        echo -e "${RED}Pre-release checks failed. Aborting.${NC}" >&2
        return 1
    fi
    echo -e "${GREEN}Pre-release checks passed${NC}\n"
    
    # Bestimme welche Skripte aktualisiert werden sollen
    local scripts_to_update=()
    
    case "$target_script" in
        dev)
            scripts_to_update=("$DEV_SCRIPT")
            ;;
        admin)
            scripts_to_update=("$ADMIN_SCRIPT")
            ;;
        ""|both|all)
            scripts_to_update=("$DEV_SCRIPT" "$ADMIN_SCRIPT")
            ;;
        *)
            echo -e "${RED}Error: Invalid script name: $target_script${NC}" >&2
            echo "Valid options: dev, admin, or empty (both)" >&2
            return 1
            ;;
    esac
    
    # Bestimme neue Versionsnummern für alle Skripte
    # Verwende parallele Arrays statt associative arrays für Kompatibilität
    local new_versions=()
    local current_versions=()
    
    for script in "${scripts_to_update[@]}"; do
        local current_version=$(_get_current_version "$script")
        if [[ -z "$current_version" ]]; then
            echo -e "${RED}Error: Could not determine current version for $script${NC}" >&2
            return 1
        fi
        
        current_versions+=("$current_version")
        local new_version=$(_increment_version "$current_version" "$release_type")
        
        if [[ -z "$new_version" ]]; then
            echo -e "${RED}Error: Failed to increment version for $script${NC}" >&2
            return 1
        fi
        
        new_versions+=("$new_version")
        
        echo -e "${BLUE}$script:${NC} ${current_version} -> ${GREEN}${new_version}${NC} (${release_type})"
    done
    
    echo ""
    
    # Verwende die erste neue Version für Tag (oder beide wenn unterschiedlich)
    local tag_version="${new_versions[0]}"
    
    # Generiere Changelog
    local oldest_current_version="${current_versions[0]}"
    local changelog=$(_generate_changelog "$oldest_current_version" "$tag_version" "$release_type")
    
    echo -e "${BLUE}Changelog:${NC}"
    echo -e "$changelog"
    echo ""
    
    # Bestätigung
    echo -e "${YELLOW}This will:${NC}"
    echo "  1. Update version numbers in script files"
    echo "  2. Generate SHA256 hash files"
    echo "  3. Create git commit"
    echo "  4. Create git tag v${tag_version}"
    echo "  5. Push to origin"
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Release cancelled${NC}"
        return 1
    fi
    
    # Aktualisiere Versionsnummern
    echo -e "\n${BLUE}Updating version numbers...${NC}"
    local idx=0
    for script in "${scripts_to_update[@]}"; do
        if ! _update_script_version "$script" "${new_versions[$idx]}"; then
            echo -e "${RED}Error: Failed to update version in $script${NC}" >&2
            return 1
        fi
        idx=$((idx + 1))
    done
    
    # Generiere SHA256-Hashes
    echo -e "\n${BLUE}Generating SHA256 hashes...${NC}"
    for script in "${scripts_to_update[@]}"; do
        local hash_file
        if [[ "$script" == "$DEV_SCRIPT" ]]; then
            hash_file="$DEV_HASH"
        else
            hash_file="$ADMIN_HASH"
        fi
        
        if ! _generate_sha256_hash "$script" "$hash_file"; then
            echo -e "${RED}Error: Failed to generate hash for $script${NC}" >&2
            return 1
        fi
    done
    
    # Git Commit
    echo -e "\n${BLUE}Creating git commit...${NC}"
    local commit_message="Release v${tag_version}"
    
    # Stage geänderte Dateien
    for script in "${scripts_to_update[@]}"; do
        git add "$script"
    done
    
    for script in "${scripts_to_update[@]}"; do
        local hash_file
        if [[ "$script" == "$DEV_SCRIPT" ]]; then
            hash_file="$DEV_HASH"
        else
            hash_file="$ADMIN_HASH"
        fi
        git add "$hash_file"
    done
    
    if ! git commit -m "$commit_message"; then
        echo -e "${RED}Error: Failed to create git commit${NC}" >&2
        return 1
    fi
    
    # Git Tag
    echo -e "\n${BLUE}Creating git tag...${NC}"
    local tag_message="Release v${tag_version}

${changelog}"
    
    if ! git tag -a "v${tag_version}" -m "$tag_message"; then
        echo -e "${RED}Error: Failed to create git tag${NC}" >&2
        return 1
    fi
    
    # Push
    echo -e "\n${BLUE}Pushing to origin...${NC}"
    if ! git push origin main 2>/dev/null && ! git push origin master 2>/dev/null; then
        echo -e "${YELLOW}Warning: Failed to push commits. Trying current branch...${NC}" >&2
        local current_branch=$(git rev-parse --abbrev-ref HEAD)
        git push origin "$current_branch" || {
            echo -e "${RED}Error: Failed to push commits${NC}" >&2
            return 1
        }
    fi
    
    if ! git push origin "v${tag_version}"; then
        echo -e "${RED}Error: Failed to push tag${NC}" >&2
        return 1
    fi
    
    # Success
    echo -e "\n${GREEN}=== Release Successful ===${NC}"
    echo -e "${GREEN}Released version: v${tag_version}${NC}"
    echo ""
    echo "Updated scripts:"
    local idx=0
    for script in "${scripts_to_update[@]}"; do
        echo "  - $script: ${current_versions[$idx]} -> ${new_versions[$idx]}"
        idx=$((idx + 1))
    done
    echo ""
    echo "Tag: v${tag_version}"
    echo "Commit: $(git rev-parse HEAD)"
    echo ""
    echo "Users can now update with:"
    for script in "${scripts_to_update[@]}"; do
        if [[ "$script" == "$DEV_SCRIPT" ]]; then
            echo "  dev upgrade"
        else
            echo "  admin upgrade"
        fi
    done
    
    return 0
}

# Hauptfunktion: Zeigt Hilfe
_show_help() {
    cat << EOF
Release Management Script for dev.sh and admin.sh

Usage: ./release.sh [type] [script]

Arguments:
  type          Release type: patch, minor, or major
  script        Script to release: dev, admin, or empty (both)

Examples:
  ./release.sh patch dev      Create patch release for dev.sh
  ./release.sh minor admin    Create minor release for admin.sh
  ./release.sh major          Create major release for both scripts
  ./release.sh patch          Create patch release for both scripts

Release Process:
  1. Pre-release checks (git repo, clean working directory)
  2. Determine new version numbers
  3. Update version numbers in script headers
  4. Generate SHA256 hash files
  5. Create git commit
  6. Create git tag with changelog
  7. Push to origin

EOF
}

# Main
main() {
    local release_type="$1"
    local target_script="${2:-}"
    
    # Validiere Release-Typ
    case "$release_type" in
        patch|minor|major)
            ;;
        help|-h|--help)
            _show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Invalid release type: $release_type${NC}" >&2
            echo "Valid types: patch, minor, major" >&2
            _show_help
            exit 1
            ;;
    esac
    
    # Erstelle Release
    if _create_release "$release_type" "$target_script"; then
        exit 0
    else
        exit 1
    fi
}

# Script starten
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 1 ]]; then
        _show_help
        exit 1
    fi
    
    main "$@"
fi
