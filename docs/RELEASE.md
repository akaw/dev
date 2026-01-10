# Release-Strategie für dev.sh und admin.sh

Diese Dokumentation beschreibt die Release-Strategie für die Skripte `dev.sh` und `admin.sh`, damit diese einfach über den `upgrade` Befehl aktualisiert werden können.

## Überblick

Die Release-Strategie ermöglicht es, neue Versionen der Skripte automatisch zu erstellen, zu versionieren und zu veröffentlichen. Das Release-Script `release.sh` automatisiert den gesamten Prozess:

1. Versionsnummern werden automatisch aktualisiert
2. SHA256-Hash-Dateien werden automatisch generiert
3. Git-Tags werden erstellt
4. Änderungen werden automatisch gepusht

## Voraussetzungen

- Git Repository mit konfiguriertem Remote `origin`
- Sauberes Working Directory (keine uncommitted changes)
- Beide Skripte (`dev.sh` und `admin.sh`) müssen vorhanden sein
- SHA256-Hash-Utility (`shasum` auf macOS oder `sha256sum` auf Linux)

## Verwendung

### Grundlegende Syntax

```bash
./release.sh [type] [script]
```

**Parameter:**
- `type`: Release-Typ (`patch`, `minor`, `major`)
- `script`: Zu releasendes Skript (`dev`, `admin`, oder leer für beide)

### Beispiele

```bash
# Patch Release für dev.sh (Bugfix)
./release.sh patch dev

# Minor Release für admin.sh (neue Features)
./release.sh minor admin

# Major Release für beide Skripte (Breaking Changes)
./release.sh major

# Patch Release für beide Skripte (Standard wenn script leer)
./release.sh patch
```

### Release-Typen

**Patch Release (`patch`):**
- Für Bugfixes und kleine Korrekturen
- Inkrementiert Patch-Version: `1.1.0` → `1.1.1`

**Minor Release (`minor`):**
- Für neue Features, abwärtskompatibel
- Inkrementiert Minor-Version: `1.1.0` → `1.2.0`

**Major Release (`major`):**
- Für Breaking Changes
- Inkrementiert Major-Version: `1.1.0` → `2.0.0`

## Release-Workflow

### Automatischer Ablauf

Das `release.sh` Script führt folgende Schritte automatisch aus:

1. **Pre-Release Checks**
   - Prüft ob Git Repository vorhanden ist
   - Prüft ob Working Directory sauber ist
   - Prüft ob Remote origin konfiguriert ist
   - Prüft ob beide Skripte vorhanden sind

2. **Versionsnummer bestimmen**
   - Liest aktuelle Version aus Skript-Header (`# Version: X.Y.Z`)
   - Inkrementiert basierend auf Release-Typ
   - Zeigt Versionsänderung an

3. **Changelog generieren**
   - Analysiert Git-Commits seit letztem Release-Tag
   - Gruppiert Commits nach Typ (feat, fix, docs, etc.)
   - Erstellt strukturierte Changelog-Nachricht

4. **Versionsnummer aktualisieren**
   - Aktualisiert `# Version: X.Y.Z` im Skript-Header
   - Erstellt Backup vor Änderung
   - Validiert neue Versionsnummer

5. **SHA256-Hash generieren**
   - Berechnet SHA256-Hash für aktualisierte Skripte
   - Schreibt Hash in entsprechende `.sha256` Dateien
   - Unterstützt sowohl macOS (`shasum`) als auch Linux (`sha256sum`)

6. **Git-Commit erstellen**
   - Staged geänderte Dateien (Skripte + Hash-Dateien)
   - Erstellt Commit mit Message: `Release vX.Y.Z`

7. **Git-Tag erstellen**
   - Erstellt annotierten Tag: `vX.Y.Z`
   - Tag-Message enthält vollständigen Changelog

8. **Push zu Origin**
   - Pusht Commits zu `origin main` (oder `master`)
   - Pusht Tag zu `origin`

9. **Success-Message**
   - Zeigt Zusammenfassung des Releases
   - Gibt Anweisungen für Benutzer zum Upgrade

### Manueller Workflow (ohne Script)

Falls das Script nicht verwendet werden kann, kann der Release manuell erstellt werden:

```bash
# 1. Versionsnummer im Skript-Header aktualisieren
# In dev.sh oder admin.sh: # Version: 1.1.0 → # Version: 1.1.1

# 2. SHA256-Hash generieren
shasum -a 256 dev.sh > dev.sh.sha256
shasum -a 256 admin.sh > admin.sh.sha256

# 3. Git-Commit erstellen
git add dev.sh admin.sh dev.sh.sha256 admin.sh.sha256
git commit -m "Release v1.1.1"

# 4. Git-Tag erstellen
git tag -a v1.1.1 -m "Release v1.1.1"

# 5. Push
git push origin main
git push origin v1.1.1
```

## Upgrade-Mechanismus

### Wie funktioniert `upgrade`?

Die `upgrade` Funktion in beiden Skripten funktioniert folgendermaßen:

1. **Versionsnummer lesen**
   - Liest aktuelle Version aus Skript-Header: `# Version: 1.1.0`
   - Lädt neueste Version vom GitHub Repository

2. **Vergleich**
   - Vergleicht aktuelle mit neuer Version
   - Wenn gleich → bereits aktuell
   - Wenn unterschiedlich → Update verfügbar

3. **Download**
   - Lädt neue Skript-Version: `https://raw.githubusercontent.com/akaw/dev/main/dev.sh`
   - Lädt SHA256-Hash: `https://raw.githubusercontent.com/akaw/dev/main/dev.sh.sha256`

4. **Verifizierung**
   - Berechnet SHA256-Hash der heruntergeladenen Datei
   - Vergleicht mit erwartetem Hash
   - Bei Mismatch → Fehler, Update wird nicht installiert

5. **Installation**
   - Erstellt Backup der aktuellen Version
   - Installiert neue Version
   - Setzt ausführbare Berechtigungen

### Benutzer-Upgrade

Benutzer können ihre Skripte aktualisieren mit:

```bash
# dev.sh aktualisieren
dev upgrade

# admin.sh aktualisieren
admin upgrade
```

## Best Practices

### Wann welchen Release-Typ verwenden?

**Patch Release:**
- Bugfixes
- Kleine Korrekturen
- Dokumentations-Updates
- Performance-Verbesserungen ohne API-Änderungen

**Minor Release:**
- Neue Features
- Neue Kommandos hinzufügen
- Abwärtskompatible Änderungen
- Verbesserungen bestehender Funktionen

**Major Release:**
- Breaking Changes
- Entfernen von Kommandos
- Änderungen an bestehenden Kommandos die nicht abwärtskompatibel sind
- Große Umstrukturierungen

### Commit-Messages

Verwende konventionelle Commit-Messages für bessere Changelog-Generierung:

```
feat: Add new command for cache clearing
fix: Fix version parsing in upgrade function
docs: Update README with new examples
chore: Update dependencies
```

### Release-Frequenz

- **Patch Releases**: So oft wie nötig (Bugfixes)
- **Minor Releases**: Regelmäßig bei neuen Features
- **Major Releases**: Sparsam, nur bei Breaking Changes

### Vor dem Release

- [ ] Alle Änderungen getestet
- [ ] Working Directory sauber (keine uncommitted changes)
- [ ] Git Repository auf neuestem Stand
- [ ] Beide Skripte funktionieren korrekt
- [ ] Versionsnummern sind konsistent

## Troubleshooting

### "Working directory has uncommitted changes"

**Problem:** Es gibt uncommitted Änderungen im Repository.

**Lösung:**
```bash
# Änderungen committen
git add .
git commit -m "Your commit message"

# Oder Änderungen stashen
git stash
```

### "Failed to push commits"

**Problem:** Push zu origin schlägt fehl.

**Lösung:**
- Prüfe ob Remote origin korrekt konfiguriert ist: `git remote -v`
- Prüfe ob du Push-Berechtigung hast
- Prüfe ob der Branch korrekt ist (main/master)

### "Failed to generate SHA256 hash"

**Problem:** SHA256-Hash kann nicht generiert werden.

**Lösung:**
- Prüfe ob `shasum` (macOS) oder `sha256sum` (Linux) installiert ist
- Prüfe ob die Skript-Dateien existieren und lesbar sind

### "Invalid version format"

**Problem:** Versionsnummer hat falsches Format.

**Lösung:**
- Versionsnummer muss Format `major.minor.patch` haben (z.B. `1.2.3`)
- Prüfe ob Versionsnummer im Skript-Header korrekt ist: `# Version: 1.1.0`

### Upgrade funktioniert nicht

**Problem:** Benutzer können nicht upgraden.

**Lösung:**
- Prüfe ob Git-Tag korrekt gepusht wurde: `git push origin vX.Y.Z`
- Prüfe ob SHA256-Hash-Datei im Repository ist und korrekt ist
- Prüfe ob GitHub Repository öffentlich zugänglich ist
- Prüfe ob Versionsnummer im Skript-Header korrekt ist

## Datei-Struktur

```
.
├── dev.sh                    # Hauptskript für lokale Entwicklung
├── admin.sh                  # Hauptskript für Webserver/Produktion
├── dev.sh.sha256             # SHA256-Hash für dev.sh (wird bei Release generiert)
├── admin.sh.sha256           # SHA256-Hash für admin.sh (wird bei Release generiert)
├── release.sh                # Release-Management-Script
├── RELEASE.md                # Diese Dokumentation
└── CHANGELOG.md              # Optional: Automatisch generiertes Changelog
```

## Weitere Informationen

- Repository: https://github.com/akaw/dev/
- Issues: https://github.com/akaw/dev/issues
- Pull Requests: https://github.com/akaw/dev/pulls

## Version

Diese Dokumentation beschreibt die Release-Strategie Version 1.0.0.
