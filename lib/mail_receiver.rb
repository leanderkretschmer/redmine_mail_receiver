require 'rufus-scheduler'
require_relative 'mail_receiver/receiver'
require_relative 'mail_receiver/scheduler'
require_relative 'mail_receiver/test_mailer'

module MailReceiver
  def self.start
    return if @started
    @started = true

    scheduler = Rufus::Scheduler.singleton
    cfg = Setting.plugin_mail_receiver

    # Incoming mail
    if cfg['load_balancing_enabled'] == 'true' && cfg['load_balancing_mails_per_hour'].to_i > 0
      # Load Balancing Mode
      mails_per_hour = cfg['load_balancing_mails_per_hour'].to_i
      interval_seconds = (3600.0 / mails_per_hour).round(1)
      
      Rails.logger.info("[MailReceiver] Load balancing mode: #{mails_per_hour} emails/hour = #{interval_seconds}s interval")
      scheduler.every "#{interval_seconds}s" do
        begin
          MailReceiver::Receiver.process_load_balanced
        rescue => e
          Rails.logger.error("[MailReceiver] Load balancing error: #{e.message}")
        end
      end
    elsif cfg['interval_seconds'].to_i > 0 && cfg['imap_host'].present?
      # Standard Mode
      interval = cfg['interval_seconds'].to_i
      Rails.logger.info("[MailReceiver] Standard mode: Scheduling mail fetch every #{interval}s")
      scheduler.every "#{interval}s" do
        begin
          MailReceiver::Receiver.process
        rescue => e
          Rails.logger.error("[MailReceiver] Error: #{e.message}")
        end
      end
    end

    # Reminder
    if cfg['reminder_enabled'] == 'true'
      time = cfg['reminder_time'] || '09:00'
      cron = "#{time.split(':')[1]} #{time.split(':')[0]} * * *"
      scheduler.cron(cron) do
        MailReceiver::Scheduler.send_reminders
      end
    end
  end
end