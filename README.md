# Redmine Mail Receiver Plugin

## Features
- Holt Mails per IMAP in konfigurierbarem Intervall
- Fügt Kommentare zu Tickets hinzu oder erstellt neue Tickets
- Legt unbekannte User stillschweigend an (keine Mails)
- Reminder-Mail täglich um konfigurierbare Uhrzeit (führt Redmine Rake Task aus)
- Testmail-Funktion zum Testen der E-Mail-Konfiguration

## Installation
1. Plugin in `redmine/plugins/mail_receiver` ablegen
2. `bundle install`
3. Redmine neu starten
4. Einstellungen unter Administration → Plugins → Mail Receiver konfigurieren

## Neue Features in Version 1.5.0

### Verbesserte Reminder-Funktion
- Die Reminder-Funktion führt jetzt die offizielle Redmine Rake Task `redmine:send_reminders` aus
- Bessere Integration mit dem Redmine-System
- Detailliertes Logging der Reminder-Ausführung

### Testmail-Funktion
- Neuer Bereich in den Plugin-Einstellungen für Testmails
- Eingabefeld für E-Mail-Adresse
- Sendet eine Testmail um die E-Mail-Konfiguration zu überprüfen
- Validierung der E-Mail-Adresse
- Erfolgs- und Fehlermeldungen
- Logging aller Testmail-Versuche

## Konfiguration

### Reminder-Einstellungen
- **Aktivieren**: Checkbox zum Aktivieren der täglichen Reminder
- **Uhrzeit**: Zeit im Format HH:MM (z.B. 09:00)

### Testmail-Einstellungen
- **E-Mail-Adresse**: Adresse für Testmail eingeben
- **Testmail senden**: Button zum Senden einer Testmail
- Die Testmail wird über die konfigurierte Redmine E-Mail-Einstellung gesendet