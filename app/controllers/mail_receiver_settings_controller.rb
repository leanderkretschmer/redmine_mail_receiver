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
  end