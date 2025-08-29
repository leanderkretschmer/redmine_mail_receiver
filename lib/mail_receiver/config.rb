require 'yaml'
require 'fileutils'

module MailReceiver
  class Config
    CONFIG_FILE = File.join(Rails.root, 'plugins', 'mail_receiver', 'config', 'settings.yml')
    
    DEFAULT_SETTINGS = {
      # Incoming mail
      'imap_host' => '',
      'imap_port' => '993',
      'imap_ssl' => 'true',
      'imap_user' => '',
      'imap_password' => '',
      'interval_seconds' => '300',
      'default_project' => '',
      'no_ticket_mode' => 'comment', # 'comment' oder 'new_ticket'
      'fallback_issue_id' => '',

      # Manual import
      'manual_import_count' => '10',
      'import_format' => 'plain_text', # 'plain_text' oder 'raw_mime'

      # Reminder
      'reminder_enabled' => 'false',
      'reminder_time' => '09:00',

      # Log
      'mail_log' => [],
      'log_level' => 'info' # 'debug', 'info', 'warn', 'error'
    }

    def self.load
      if File.exist?(CONFIG_FILE)
        begin
          YAML.load_file(CONFIG_FILE) || DEFAULT_SETTINGS
        rescue => e
          Rails.logger.error("[MailReceiver] Error loading config: #{e.message}")
          DEFAULT_SETTINGS
        end
      else
        # Erstelle Standard-Konfiguration beim ersten Start
        save(DEFAULT_SETTINGS)
        DEFAULT_SETTINGS
      end
    end

    def self.save(settings)
      # Stelle sicher, dass das Verzeichnis existiert
      FileUtils.mkdir_p(File.dirname(CONFIG_FILE))
      
      # Speichere Einstellungen
      File.write(CONFIG_FILE, settings.to_yaml)
      
      # Setze Dateiberechtigungen (nur für den Webserver lesbar/schreibbar)
      File.chmod(0600, CONFIG_FILE)
    rescue => e
      Rails.logger.error("[MailReceiver] Error saving config: #{e.message}")
      false
    end

    def self.get(key)
      load[key]
    end

    def self.set(key, value)
      settings = load
      settings[key] = value
      save(settings)
    end

    def self.merge(new_settings)
      settings = load
      settings.merge!(new_settings)
      save(settings)
    end

    def self.all
      load
    end
  end
end
