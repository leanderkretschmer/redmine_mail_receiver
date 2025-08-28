module MailReceiver
  class Scheduler
    def self.send_reminders
      Rails.logger.info("[MailReceiver] Sending reminders...")
      
      # Führe die Redmine Rake Task für Mail Reminders aus
      begin
        # Setze das Rails Environment
        ENV['RAILS_ENV'] = Rails.env
        
        # Führe die Rake Task aus
        system("bundle exec rake redmine:send_reminders")
        
        if $?.success?
          Rails.logger.info("[MailReceiver] Reminders sent successfully")
          # Log zur Plugin-Einstellung hinzufügen
          add_log_entry("Reminders sent successfully at #{Time.current}")
        else
          Rails.logger.error("[MailReceiver] Failed to send reminders")
          add_log_entry("Failed to send reminders at #{Time.current}")
        end
      rescue => e
        Rails.logger.error("[MailReceiver] Error sending reminders: #{e.message}")
        add_log_entry("Error sending reminders: #{e.message} at #{Time.current}")
      end
    end
    
    private
    
    def self.add_log_entry(message)
      settings = Setting.plugin_mail_receiver
      log = settings['mail_log'] || []
      log << "[#{Time.current.strftime('%Y-%m-%d %H:%M:%S')}] #{message}"
      
      # Behalte nur die letzten 100 Einträge
      log = log.last(100)
      
      settings['mail_log'] = log
      Setting.plugin_mail_receiver = settings
    end
  end
end