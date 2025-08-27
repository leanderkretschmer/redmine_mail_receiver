require 'redmine'
require_relative 'lib/mail_receiver'

Redmine::Plugin.register :mail_receiver do
  name 'Mail Receiver Plugin'
  author 'leanderkretschmer'
  description 'IMAP Mail Receiver + Reminder Scheduler for Redmine'
  version '1.3.1'
  url 'https://github.com/leanderkretschmer/redmine_mail_receiver'
  author_url 'https://github.com/leanderkretschmer'

  settings default: {
    'imap_host' => '',
    'imap_port' => '993',
    'imap_ssl' => 'true',
    'imap_user' => '',
    'imap_password' => '',
    'default_project' => '',
    'interval_seconds' => '300',
    'reminder_enabled' => 'false',
    'reminder_time' => '09:00'
  }, partial: 'mail_receiver_settings/edit'
end

# Scheduler nur im Produktionsmodus starten, nicht bei Rake-Tasks oder Migrations
unless defined?(Rails::Console) || File.split($0).last == 'rake'
  Rails.application.config.after_initialize do
    MailReceiver.start
  end
end