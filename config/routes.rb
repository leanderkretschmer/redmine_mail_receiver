# Plugin Routes
Rails.application.routes.draw do
  post 'plugin_settings/mail_receiver/send_test_mail', to: 'mail_receiver_settings#send_test_mail'
end
