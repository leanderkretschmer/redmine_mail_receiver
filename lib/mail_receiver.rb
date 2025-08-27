require 'rufus-scheduler'
require_relative 'mail_receiver/receiver'
require_relative 'mail_receiver/scheduler'

module MailReceiver
  def self.start
    return if @started
    @started = true

    scheduler = Rufus::Scheduler.singleton

    # Mail Polling
    interval = Setting.plugin_mail_receiver['interval_seconds'].to_i
    scheduler.every "#{interval}s" do
      MailReceiver::Receiver.process
    end

    # Reminder Mail
    if Setting.plugin_mail_receiver['reminder_enabled'] == 'true'
      time = Setting.plugin_mail_receiver['reminder_time'] || '09:00'
      scheduler.cron("#{time.split(':')[1]} #{time.split(':')[0]} * * *") do
        MailReceiver::Scheduler.send_reminders
      end
    end
  end
end