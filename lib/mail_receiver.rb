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
    interval = cfg['interval_seconds'].to_i
    if interval > 0 && cfg['imap_host'].present?
      Rails.logger.info("[MailReceiver] Scheduling mail fetch every #{interval}s")
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