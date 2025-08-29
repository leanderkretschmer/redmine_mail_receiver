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

## Neue Features in Version 1.8.2

### Verbesserte Benutzeroberfläche
- Saubere Unterteilung auf einer Seite ohne Tabs
- Entwicklungsmodus Sektion mit visueller Trennung
- Alle IMAP-Einstellungen wieder sichtbar und verfügbar
- Klare visuelle Trennung zwischen allgemeinen und Entwicklungsfunktionen

### Entwicklungsmodus Sektion
- Eigener Bereich mit roter Umrandung für den Dev Mode Toggle
- Erweiterte Funktionen nur sichtbar wenn Dev Mode aktiviert
- Visuelle Trennung durch Trennlinie und Abstand
- Bessere Übersichtlichkeit ohne Tab-Navigation

## Neue Features in Version 1.8.1

### Verbesserter Entwicklungsmodus (Dev Mode)
- Entwicklungsmodus ist jetzt ein eigener Tab in den Einstellungen
- Alle erweiterten Funktionen nur im Dev Mode Tab verfügbar
- Dev Mode Toggle direkt im Entwicklungs-Tab
- Klare Trennung zwischen allgemeinen und Entwicklungsfunktionen

### Tab-System
- **Allgemein Tab**: Grundlegende E-Mail-Konfiguration und Reminder
- **Entwicklung Tab**: Dev Mode Toggle und alle erweiterten Funktionen
- Bessere Organisation und Übersichtlichkeit

## Neue Features in Version 1.8.0

### Entwicklungsmodus (Dev Mode)
- Neuer Tab-basierter Entwicklungsmodus in den Einstellungen
- Erweiterte Funktionen nur im Dev Mode verfügbar
- Einfache Aktivierung über Checkbox am Ende der Einstellungen
- Rote Umrandung zur Kennzeichnung des Dev Mode

### Load Balancing
- Neue Load Balancing Option im Dev Mode
- Konfigurierbare Anzahl E-Mails pro Stunde (z.B. 60 E-Mails/Stunde)
- Automatische Berechnung des optimalen Intervalls
- Live-Anzeige der Berechnung (Intervall in Sekunden, E-Mails pro Minute)
- Verarbeitet nur eine E-Mail pro Durchlauf für gleichmäßige Lastverteilung

### Verbesserte Benutzeroberfläche
- Tab-System: "Allgemein" und "Entwicklung" Tabs
- Dev Mode Toggle mit auffälliger roter Umrandung
- Live-Berechnung der Load Balancing Parameter
- Bessere Organisation der erweiterten Funktionen

## Neue Features in Version 1.7.0

### Manueller Import
- Neuer Bereich in den Plugin-Einstellungen für manuellen Import
- Eingabefeld für Anzahl der zu importierenden E-Mails (1-100)
- Button zum Starten des manuellen Imports
- Detailliertes Logging des Import-Prozesses
- Perfekt für Tests und Debugging

### Erweitertes Logging
- Neuer "Erweitertes Log" Bereich in den Einstellungen
- Detaillierte Protokollierung aller Import-Schritte
- Kontinuierliche Aktualisierung während des Imports
- Zeigt Verbindungsstatus, E-Mail-Details und Verarbeitungsergebnisse
- Monospace-Font für bessere Lesbarkeit

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

### Entwicklungsmodus (Dev Mode)
- **Entwicklungsmodus Sektion**: Eigener Bereich mit visueller Trennung
- **Dev Mode Toggle**: Checkbox zum Aktivieren mit roter Umrandung
- **Erweiterte Funktionen**: Nur sichtbar wenn Dev Mode aktiviert
- **Visuelle Trennung**: Trennlinie und Abstand zwischen den Bereichen

### Manueller Import-Einstellungen (Dev Mode)
- **Aktivieren**: Checkbox zum Aktivieren der manuellen Import-Funktion
- **Standard-Anzahl**: Standard-Anzahl der zu importierenden E-Mails
- **Import starten**: Button zum Starten des manuellen Imports mit konfigurierbarer Anzahl

### Load Balancing-Einstellungen (Dev Mode)
- **Aktivieren**: Checkbox zum Aktivieren des Load Balancing
- **E-Mails pro Stunde**: Konfigurierbare Anzahl (z.B. 60 E-Mails/Stunde)
- **Live-Berechnung**: Automatische Anzeige des Intervalls und der Verarbeitungsrate
- **Gleichmäßige Verarbeitung**: Nur eine E-Mail pro Durchlauf

### Erweitertes Logging (Dev Mode)
- **Detaillierte Protokollierung**: Alle Import-Schritte und Load Balancing Aktivitäten
- **Kontinuierliche Aktualisierung**: Live-Updates während der Verarbeitung