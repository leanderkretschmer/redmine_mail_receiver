require 'rufus-scheduler'
require_relative 'mail_receiver/receiver'
require_relative 'mail_receiver/scheduler'

module MailReceiver
  def self.start
    return if @started
    @started = true

    scheduler = Rufus::Scheduler.singleton

    cfg = Setting.plugin_mail_receiver

    # Mail Polling
    interval = cfg['interval_seconds'].to_i
    if interval > 0 && cfg['imap_host'].present?
      Rails.logger.info("[MailReceiver] Scheduling mail fetch every #{interval}s")
      scheduler.every "#{interval}s" do
        begin
          MailReceiver::Receiver.process
        rescue => e
          Rails.logger.error("[MailReceiver] Error while processing mails: #{e.message}")
        end
      end
    else
      Rails.logger.info("[MailReceiver] Mail fetch disabled (no host or interval=0)")
    end

    # Reminder Mail
    if cfg['reminder_enabled'] == 'true'
      time = cfg['reminder_time'] || '09:00'
      cron = "#{time.split(':')[1]} #{time.split(':')[0]} * * *"
      Rails.logger.info("[MailReceiver] Scheduling reminders at #{time}")
      scheduler.cron(cron) do
        begin
          MailReceiver::Scheduler.send_reminders
        rescue => e
          Rails.logger.error("[MailReceiver] Error while sending reminders: #{e.message}")
        end
      end
    else
      Rails.logger.info("[MailReceiver] Reminders disabled")
    end
  end
end