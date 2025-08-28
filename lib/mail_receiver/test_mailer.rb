module MailReceiver
  class TestMailer < ActionMailer::Base
    def send_test_mail(email)
      @site_name = Setting.app_title || 'Redmine'
      @timestamp = Time.current.strftime('%Y-%m-%d %H:%M:%S')
      
      mail(
        to: email,
        from: Setting.mail_from,
        subject: "[#{@site_name}] Testmail vom Mail Receiver Plugin"
      ) do |format|
        format.text { render plain: test_mail_content }
        format.html { render html: test_mail_content.html_safe }
      end
    end
    
    private
    
    def test_mail_content
      content = <<~EMAIL
        Hallo,
        
        dies ist eine Testmail vom Mail Receiver Plugin für #{@site_name}.
        
        Diese E-Mail wurde automatisch generiert um zu testen, ob die E-Mail-Konfiguration korrekt funktioniert.
        
        Zeitstempel: #{@timestamp}
        
        Wenn Sie diese E-Mail erhalten, funktioniert die E-Mail-Konfiguration korrekt.
        
        Mit freundlichen Grüßen
        Ihr #{@site_name} System
      EMAIL
      
      content
    end
  end
end
