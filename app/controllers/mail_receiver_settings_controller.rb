class MailReceiverSettingsController < ApplicationController
  layout 'admin'
  before_action :require_admin

  def edit
    @settings = Setting.plugin_mail_receiver
  end

  def update
    Setting.plugin_mail_receiver = params[:settings]
    flash[:notice] = l(:notice_successful_update)
    redirect_to plugin_settings_path(id: 'mail_receiver')
  end
  
  def send_test_mail
    email = params[:test_email]
    
    if email.blank?
      flash[:error] = l('mail_receiver.test_mail.email_required')
      redirect_to plugin_settings_path(id: 'mail_receiver')
      return
    end
    
    unless email =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
      flash[:error] = l('mail_receiver.test_mail.invalid_email')
      redirect_to plugin_settings_path(id: 'mail_receiver')
      return
    end
    
    begin
      # Sende Testmail
      MailReceiver::TestMailer.send_test_mail(email).deliver_now
      
      # Log zur Plugin-Einstellung hinzufügen
      add_log_entry("Test mail sent to #{email}")
      
      flash[:notice] = l('mail_receiver.test_mail.sent_successfully', email: email)
    rescue => e
      Rails.logger.error("[MailReceiver] Error sending test mail: #{e.message}")
      add_log_entry("Error sending test mail to #{email}: #{e.message}")
      flash[:error] = l('mail_receiver.test_mail.send_failed', error: e.message)
    end
    
    redirect_to plugin_settings_path(id: 'mail_receiver')
  end
  
  private
  
  def add_log_entry(message)
    settings = Setting.plugin_mail_receiver
    log = settings['mail_log'] || []
    log << "[#{Time.current.strftime('%Y-%m-%d %H:%M:%S')}] #{message}"
    
    # Behalte nur die letzten 100 Einträge
    log = log.last(100)
    
    settings['mail_log'] = log
    Setting.plugin_mail_receiver = settings
  end
end