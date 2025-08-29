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

    def manual_import
      count = params[:import_count].to_i
      count = [count, 1].max # Mindestens 1 Mail
      count = [count, 100].min # Maximal 100 Mails
      
      begin
        result = MailReceiver::Receiver.manual_import(count)
        flash[:notice] = "Manueller Import erfolgreich: #{result[:processed]} Mails verarbeitet, #{result[:errors]} Fehler"
      rescue => e
        flash[:error] = "Fehler beim manuellen Import: #{e.message}"
        Rails.logger.error("[MailReceiver] Manual import error: #{e.message}")
      end
      
      redirect_to plugin_settings_path(id: 'mail_receiver')
    end

    def clear_log
      Setting.plugin_mail_receiver = Setting.plugin_mail_receiver.merge('mail_log' => [])
      flash[:notice] = "Mail-Log erfolgreich geleert"
      redirect_to plugin_settings_path(id: 'mail_receiver')
    end
  end