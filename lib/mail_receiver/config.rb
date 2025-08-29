require 'yaml'
require 'fileutils'

module MailReceiver
  class Config
    # Verwende ein beschreibbares Verzeichnis im Plugin-Ordner
    CONFIG_FILE = File.join(Rails.root, 'plugins', 'mail_receiver', 'data', 'settings.yml')
    
    # Fallback für Docker-Umgebungen
    FALLBACK_CONFIG_FILE = File.join(Dir.tmpdir, 'mail_receiver_settings.yml')
    
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
      config_file = get_config_file
      
      if File.exist?(config_file)
        begin
          YAML.load_file(config_file) || DEFAULT_SETTINGS
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
      config_file = get_config_file
      
      # Stelle sicher, dass das Verzeichnis existiert
      FileUtils.mkdir_p(File.dirname(config_file))
      
      # Speichere Einstellungen
      File.write(config_file, settings.to_yaml)
      
      # Setze Dateiberechtigungen (nur für den Webserver lesbar/schreibbar)
      File.chmod(0600, config_file)
    rescue => e
      Rails.logger.error("[MailReceiver] Error saving config: #{e.message}")
      Rails.logger.error("[MailReceiver] Config file path: #{config_file}")
      Rails.logger.error("[MailReceiver] Directory writable: #{File.writable?(File.dirname(config_file))}")
      false
    end

    def self.get_config_file
      # Versuche zuerst das normale Verzeichnis
      if File.writable?(File.dirname(CONFIG_FILE))
        CONFIG_FILE
      else
        # Fallback auf temporäres Verzeichnis
        Rails.logger.warn("[MailReceiver] Using fallback config location: #{FALLBACK_CONFIG_FILE}")
        FALLBACK_CONFIG_FILE
      end
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
