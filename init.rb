require 'redmine'
require_relative 'lib/mail_receiver'
require_relative 'config/routes'

Redmine::Plugin.register :mail_receiver do
  name 'Mail Receiver Plugin'
  author 'Leander Kretschmer'
  description 'IMAP Mail Receiver + Reminder Scheduler for Redmine'
  version '1.8.1'
  url 'https://github.com/leanderkretschmer/redmine_mail_receiver'
  author_url 'https://github.com/leanderkretschmer'

  settings default: {
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

    # Reminder
    'reminder_enabled' => 'false',
    'reminder_time' => '09:00',

    # Dev Mode
    'dev_mode_enabled' => 'false',

    # Manual import
    'manual_import_enabled' => 'false',
    'manual_import_count' => '10',

    # Load Balancing
    'load_balancing_enabled' => 'false',
    'load_balancing_mails_per_hour' => '60',

    # Log
    'mail_log' => [],
    'detailed_log' => []
  }, partial: 'mail_receiver_settings/edit'
end



unless defined?(Rails::Console) || File.split($0).last == 'rake'
  Rails.application.config.after_initialize do
    MailReceiver.start
  end
end