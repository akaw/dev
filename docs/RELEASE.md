# Release Strategy for dev.sh

This documentation describes the release strategy for the `dev.sh` script, enabling it to be easily updated via the `upgrade` command.

## Overview

The release strategy enables automatic creation, versioning, and publishing of new script versions. The `release.sh` script automates the entire process:

1. Version numbers are automatically updated
2. SHA256 hash files are automatically generated
3. Git tags are created
4. Changes are automatically pushed

## Prerequisites

- Git repository with configured remote `origin`
- Clean working directory (no uncommitted changes)
- The `dev.sh` script must exist
- SHA256 hash utility (`shasum` on macOS or `sha256sum` on Linux)

## Usage

### Basic Syntax

```bash
./release.sh [type]
```

**Parameters:**
- `type`: Release type (`patch`, `minor`, `major`)

### Examples

```bash
# Patch Release (Bugfix)
./release.sh patch

# Minor Release (new features)
./release.sh minor

# Major Release (Breaking Changes)
./release.sh major
```

### Release Types

**Patch Release (`patch`):**
- For bugfixes and small corrections
- Increments patch version: `1.1.0` → `1.1.1`

**Minor Release (`minor`):**
- For new features, backward compatible
- Increments minor version: `1.1.0` → `1.2.0`

**Major Release (`major`):**
- For breaking changes
- Increments major version: `1.1.0` → `2.0.0`

## Release Workflow

### Automatic Process

The `release.sh` script automatically executes the following steps:

1. **Pre-Release Checks**
   - Checks if Git repository exists
   - Checks if working directory is clean
   - Checks if remote origin is configured
   - Checks if the script exists

2. **Determine Version Number**
   - Reads current version from script header (`# Version: X.Y.Z`)
   - Increments based on release type
   - Displays version change

3. **Generate Changelog**
   - Analyzes Git commits since last release tag
   - Groups commits by type (feat, fix, docs, etc.)
   - Creates structured changelog message

4. **Update Version Number**
   - Updates `# Version: X.Y.Z` in script header
   - Creates backup before change
   - Validates new version number

5. **Generate SHA256 Hash**
   - Calculates SHA256 hash for updated scripts
   - Writes hash to corresponding `.sha256` files
   - Supports both macOS (`shasum`) and Linux (`sha256sum`)

6. **Create Git Commit**
   - Stages changed files (scripts + hash files)
   - Creates commit with message: `Release vX.Y.Z`

7. **Create Git Tag**
   - Creates annotated tag: `vX.Y.Z`
   - Tag message contains full changelog

8. **Push to Origin**
   - Pushes commits to `origin main` (or `master`)
   - Pushes tag to `origin`

9. **Success Message**
   - Displays release summary
   - Provides upgrade instructions for users

### Manual Workflow (without script)

If the script cannot be used, the release can be created manually:

```bash
# 1. Update version number in script header
# In dev.sh: # Version: 1.1.0 → # Version: 1.1.1

# 2. Generate SHA256 hash
shasum -a 256 dev.sh > dev.sh.sha256

# 3. Create Git commit
git add dev.sh dev.sh.sha256
git commit -m "Release v1.1.1"

# 4. Create Git tag
git tag -a v1.1.1 -m "Release v1.1.1"

# 5. Push
git push origin main
git push origin v1.1.1
```

## Upgrade Mechanism

### How does `upgrade` work?

The `upgrade` function in the script works as follows:

1. **Read Version Number**
   - Reads current version from script header: `# Version: 1.1.0`
   - Loads latest version from GitHub repository

2. **Compare**
   - Compares current with new version
   - If equal → already up to date
   - If different → update available

3. **Download**
   - Downloads new script version: `https://raw.githubusercontent.com/akaw/dev/main/dev.sh`
   - Downloads SHA256 hash: `https://raw.githubusercontent.com/akaw/dev/main/dev.sh.sha256`

4. **Verification**
   - Calculates SHA256 hash of downloaded file
   - Compares with expected hash
   - On mismatch → error, update is not installed

5. **Installation**
   - Creates backup of current version
   - Installs new version
   - Sets executable permissions

### User Upgrade

Users can update the script with:

```bash
dev upgrade
```

## Best Practices

### When to use which release type?

**Patch Release:**
- Bugfixes
- Small corrections
- Documentation updates
- Performance improvements without API changes

**Minor Release:**
- New features
- Adding new commands
- Backward compatible changes
- Improvements to existing functions

**Major Release:**
- Breaking changes
- Removing commands
- Changes to existing commands that are not backward compatible
- Major restructuring

### Commit Messages

Use conventional commit messages for better changelog generation:

```
feat: Add new command for cache clearing
fix: Fix version parsing in upgrade function
docs: Update README with new examples
chore: Update dependencies
```

### Release Frequency

- **Patch Releases**: As often as needed (bugfixes)
- **Minor Releases**: Regularly with new features
- **Major Releases**: Sparingly, only for breaking changes

### Before Release

- [ ] All changes tested
- [ ] Working directory clean (no uncommitted changes)
- [ ] Git repository up to date
- [ ] Script works correctly
- [ ] Version number is correct

## Troubleshooting

### "Working directory has uncommitted changes"

**Problem:** There are uncommitted changes in the repository.

**Solution:**
```bash
# Commit changes
git add .
git commit -m "Your commit message"

# Or stash changes
git stash
```

### "Failed to push commits"

**Problem:** Push to origin fails.

**Solution:**
- Check if remote origin is correctly configured: `git remote -v`
- Check if you have push permissions
- Check if the branch is correct (main/master)

### "Failed to generate SHA256 hash"

**Problem:** SHA256 hash cannot be generated.

**Solution:**
- Check if `shasum` (macOS) or `sha256sum` (Linux) is installed
- Check if script files exist and are readable

### "Invalid version format"

**Problem:** Version number has incorrect format.

**Solution:**
- Version number must have format `major.minor.patch` (e.g. `1.2.3`)
- Check if version number in script header is correct: `# Version: 1.1.0`

### Upgrade doesn't work

**Problem:** Users cannot upgrade.

**Solution:**
- Check if Git tag was correctly pushed: `git push origin vX.Y.Z`
- Check if SHA256 hash file is in repository and is correct
- Check if GitHub repository is publicly accessible
- Check if version number in script header is correct

## File Structure

```
.
├── dev.sh                    # Main script for local development
├── dev.sh.sha256             # SHA256 hash for dev.sh (generated on release)
├── release.sh                # Release management script
├── docs/
│   └── RELEASE.md            # This documentation
└── CHANGELOG.md              # Optional: Automatically generated changelog
```

## Further Information

- Repository: https://github.com/akaw/dev/
- Issues: https://github.com/akaw/dev/issues
- Pull Requests: https://github.com/akaw/dev/pulls

## Version

This documentation describes release strategy version 1.0.0.
