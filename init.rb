require 'redmine'
require_relative 'lib/mail_receiver'
require_relative 'lib/mail_receiver/config'

Redmine::Plugin.register :mail_receiver do
  name 'Mail Receiver Plugin'
  author 'leanderkretschmer'
  description 'IMAP Mail Receiver + Reminder Scheduler for Redmine'
  version '1.5.2'
  url 'https://github.com/leanderkretschmer/redmine_mail_receiver'
  author_url 'https://github.com/leanderkretschmer'

  # Verwende plugin-interne Konfiguration statt Redmine-Einstellungen
  settings default: {}, partial: 'mail_receiver_settings/edit'
end

unless defined?(Rails::Console) || File.split($0).last == 'rake'
  Rails.application.config.after_initialize do
    MailReceiver.start
  end
end