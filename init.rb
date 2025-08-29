require 'redmine'
require_relative 'lib/mail_receiver'
require_relative 'lib/mail_receiver/config'
require_relative 'lib/mail_receiver/hooks'

Redmine::Plugin.register :mail_receiver do
  name 'Mail Receiver Plugin'
  author 'leanderkretschmer'
  description 'IMAP Mail Receiver + Reminder Scheduler for Redmine'
  version '1.5.6'
  url 'https://github.com/leanderkretschmer/redmine_mail_receiver'
  author_url 'https://github.com/leanderkretschmer'

  # Verwende plugin-interne Konfiguration statt Redmine-Einstellungen
  settings default: {}, partial: 'mail_receiver_settings/edit'
end

# Lokalisierungsdateien laden
Rails.application.config.after_initialize do
  I18n.load_path += Dir[File.join(File.dirname(__FILE__), 'locales', '*.yml')]
end

unless defined?(Rails::Console) || File.split($0).last == 'rake'
  Rails.application.config.after_initialize do
    MailReceiver.start
  end
end