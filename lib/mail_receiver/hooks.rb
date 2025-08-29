module MailReceiver
  module Hooks
    class ViewHookListener < Redmine::Hook::ViewListener
      def view_layouts_base_html_head(context = {})
        return unless context[:controller].is_a?(SettingsController)
        return unless context[:controller].action_name == 'plugin'
        return unless context[:controller].params[:id] == 'mail_receiver'
        
        # Füge JavaScript für die Aktionen hinzu
        javascript_include_tag('mail_receiver', plugin: 'mail_receiver')
      end
    end
  end
end
