class MailReceiverSettingsController < ApplicationController
    layout 'admin'
    before_action :require_admin
  
    def edit
      @settings = MailReceiver::Config.all
    end
  
    def update
      MailReceiver::Config.merge(params[:settings])
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
      MailReceiver::Config.set('mail_log', [])
      flash[:notice] = "Mail-Log erfolgreich geleert"
      redirect_to plugin_settings_path(id: 'mail_receiver')
    end
  end