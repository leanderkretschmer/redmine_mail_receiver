# Redmine Mail Receiver Plugin

## Features
- Holt Mails per IMAP in konfigurierbarem Intervall
- **Manueller Mail-Import** mit konfigurierbarer Anzahl
- **Plain Text Format** für bessere Lesbarkeit (statt Raw MIME)
- Fügt Kommentare zu Tickets hinzu oder erstellt neue Tickets
- Legt unbekannte User stillschweigend an (keine Mails)
- Reminder-Mail täglich um konfigurierbare Uhrzeit
- **Erweiterte Logging-Funktionen** mit verschiedenen Log-Levels

## Neue Features in Version 1.5.0

### Manueller Mail-Import
- Importieren Sie Mails manuell über die Einstellungen
- Konfigurierbare Anzahl von Mails (1-100)
- Sofortige Verarbeitung ohne Warten auf automatischen Import

### Verbessertes Mail-Format
- **Plain Text Format** als Standard (lesbar und sauber)
- Automatische HTML-zu-Text Konvertierung
- Rückwärtskompatibilität mit Raw MIME Format

### Erweiterte Logging-Funktionen
- Verschiedene Log-Levels: Debug, Info, Warn, Error
- Farbkodierte Log-Anzeige
- Log-Leeren Funktion
- Erweiterte Log-Kapazität (100 statt 50 Einträge)

## Installation
1. Plugin in `redmine/plugins/mail_receiver` ablegen
2. `bundle install`
3. Redmine neu starten
4. **Konfiguration**: 
   - Kopieren Sie `data/settings.yml.example` zu `data/settings.yml`
   - Passen Sie die Einstellungen in der Datei an
   - Oder konfigurieren Sie über Administration → Plugins → Mail Receiver

## Konfiguration

### Plugin-interne Speicherung
Das Plugin speichert alle Einstellungen in `data/settings.yml` statt in der Redmine-Datenbank. Dies bietet:
- **Bessere Portabilität**: Einstellungen bleiben beim Plugin
- **Sicherheit**: Sensible Daten nicht in der Datenbank
- **Einfache Backup/Restore**: Nur eine Datei zu sichern
- **Docker-Kompatibilität**: Automatischer Fallback auf temporäres Verzeichnis bei Schreibproblemen

### Manueller Import
- **Import-Format**: Wählen Sie zwischen "Plain Text" (Standard) und "Raw MIME"
- **Standard-Anzahl**: Anzahl der Mails für manuellen Import (Standard: 10)
- **Import starten**: Geben Sie eine Anzahl ein und klicken Sie auf "Import starten"

### Logging
- **Log-Level**: Wählen Sie die gewünschte Detailtiefe der Logs
  - Debug: Alle Informationen
  - Info: Wichtige Informationen (Standard)
  - Warn: Nur Warnungen und Fehler
  - Error: Nur Fehler
- **Log leeren**: Löscht alle gespeicherten Log-Einträge

## Verwendung

### Automatischer Import
Der automatische Import läuft im Hintergrund und verarbeitet neue Mails in dem konfigurierten Intervall.

### Manueller Import
1. Gehen Sie zu Administration → Plugins → Mail Receiver
2. Scrollen Sie zum Abschnitt "Manueller Mail-Import"
3. Geben Sie die gewünschte Anzahl von Mails ein (1-100)
4. Klicken Sie auf "Import starten"
5. Überprüfen Sie das Ergebnis im Mail-Log

### Log-Überwachung
- Alle Aktivitäten werden im Mail-Log protokolliert
- Farbkodierung für verschiedene Log-Levels
- Log kann jederzeit geleert werden