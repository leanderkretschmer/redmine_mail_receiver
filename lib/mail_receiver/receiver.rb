require 'net/imap'
require 'mail'

module MailReceiver
  class Receiver
    def self.process
      cfg = Setting.plugin_mail_receiver
      return if cfg['imap_host'].blank?

      imap = Net::IMAP.new(cfg['imap_host'], cfg['imap_port'].to_i, cfg['imap_ssl'] == 'true')
      imap.login(cfg['imap_user'], cfg['imap_password'])
      imap.select('INBOX')

      imap.search(['UNSEEN']).each do |msg_id|
        msg = imap.fetch(msg_id, 'RFC822')[0].attr['RFC822']
        mail = Mail.read_from_string(msg)
        handle_mail(mail)
        imap.store(msg_id, "+FLAGS", [:Seen])
      end

      imap.logout
      imap.disconnect
    rescue => e
      log_error("IMAP error: #{e.message}")
    end

    def self.manual_import(count = 10)
      cfg = Setting.plugin_mail_receiver
      return { processed: 0, errors: 1 } if cfg['imap_host'].blank?

      processed = 0
      errors = 0

      begin
        imap = Net::IMAP.new(cfg['imap_host'], cfg['imap_port'].to_i, cfg['imap_ssl'] == 'true')
        imap.login(cfg['imap_user'], cfg['imap_password'])
        imap.select('INBOX')

        # Alle ungelesenen Mails holen
        unseen_mails = imap.search(['UNSEEN'])
        mails_to_process = unseen_mails.first(count)

        log_info("Manueller Import gestartet: #{mails_to_process.length} von #{unseen_mails.length} ungelesenen Mails")

        mails_to_process.each do |msg_id|
          begin
            msg = imap.fetch(msg_id, 'RFC822')[0].attr['RFC822']
            mail = Mail.read_from_string(msg)
            handle_mail(mail)
            imap.store(msg_id, "+FLAGS", [:Seen])
            processed += 1
            log_info("Mail ##{msg_id} erfolgreich verarbeitet")
          rescue => e
            errors += 1
            log_error("Fehler bei Mail ##{msg_id}: #{e.message}")
          end
        end

        imap.logout
        imap.disconnect

        log_info("Manueller Import abgeschlossen: #{processed} verarbeitet, #{errors} Fehler")
        { processed: processed, errors: errors }
      rescue => e
        log_error("Fehler beim manuellen Import: #{e.message}")
        { processed: processed, errors: errors + 1 }
      end
    end

    def self.handle_mail(mail)
      subject = mail.subject.to_s
      body = extract_mail_body(mail)
      from = mail.from.first.downcase
      user = User.find_by_mail(from)
      ticket_id = subject[/\[#(\d+)\]/, 1]

      if ticket_id
        issue = Issue.find_by_id(ticket_id)
        if issue
          user ||= create_silent_user(from, mail)
          add_journal(issue, user, body)
          log_info("Kommentar zu ##{issue.id} von #{from} hinzugefügt")
        else
          log_warn("Ticket ##{ticket_id} nicht gefunden für Mail von #{from}")
        end
      else
        if user
          if Setting.plugin_mail_receiver['no_ticket_mode'] == 'comment'
            fallback_id = Setting.plugin_mail_receiver['fallback_issue_id'].to_i
            if fallback_id > 0 && (issue = Issue.find_by_id(fallback_id))
              add_journal(issue, user, "Keine Ticket-ID gefunden. Verschoben in Posteingang\n\n#{body}")
              log_info("Mail von #{from} zu Fallback-Ticket ##{issue.id} verschoben")
            else
              log_warn("Fallback-Ticket ##{fallback_id} nicht gefunden für Mail von #{from}")
            end
          else
            create_issue(user, subject, body)
            log_info("Neues Ticket von #{from} erstellt")
          end
        else
          log_warn("Mail von unbekanntem Benutzer #{from} ignoriert")
        end
      end
    end

    def self.extract_mail_body(mail)
      cfg = Setting.plugin_mail_receiver
      format = cfg['import_format'] || 'plain_text'

      if format == 'raw_mime'
        # Originales Raw MIME Format (für Rückwärtskompatibilität)
        mail.body.decoded
      else
        # Plain Text Format (Standard)
        if mail.text_part
          # HTML-Mail mit Text-Alternative
          mail.text_part.decoded
        elsif mail.html_part
          # Nur HTML-Mail - versuche HTML zu Text zu konvertieren
          html_to_text(mail.html_part.decoded)
        else
          # Einfache Text-Mail
          mail.body.decoded
        end
      end
    end

    def self.html_to_text(html)
      # Einfache HTML zu Text Konvertierung
      text = html.gsub(/<br\s*\/?>/i, "\n")
                 .gsub(/<\/p>/i, "\n\n")
                 .gsub(/<[^>]*>/, '')
                 .gsub(/&nbsp;/, ' ')
                 .gsub(/&amp;/, '&')
                 .gsub(/&lt;/, '<')
                 .gsub(/&gt;/, '>')
                 .gsub(/&quot;/, '"')
                 .strip
      
      # Mehrfache Leerzeilen reduzieren
      text.gsub(/\n\s*\n\s*\n/, "\n\n")
    end

    def self.add_journal(issue, user, body)
      issue.init_journal(user, body)
      issue.save
    end

    def self.create_issue(user, subject, body)
      project = Project.find_by_identifier(Setting.plugin_mail_receiver['default_project'])
      return unless project
      issue = Issue.new(
        project: project,
        tracker: project.trackers.first,
        author: user,
        subject: subject,
        description: body
      )
      issue.save
    end

    def self.create_silent_user(email, mail)
      user = User.new(
        login: email,
        mail: email,
        firstname: mail[:from].display_names.first || "Unknown",
        lastname: "User",
        language: Setting.default_language
      )
      user.random_password
      user.status = User::STATUS_REGISTERED
      user.save(validate: false)
      user
    end

    def self.log_mail(message)
      log = Setting.plugin_mail_receiver['mail_log'] || []
      log << "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] #{message}"
      log = log.last(100) # Die letzten 100 Einträge behalten
      Setting.plugin_mail_receiver = Setting.plugin_mail_receiver.merge('mail_log' => log)
    end

    def self.log_info(message)
      log_level = Setting.plugin_mail_receiver['log_level'] || 'info'
      return unless ['debug', 'info'].include?(log_level)
      log_mail("[INFO] #{message}")
    end

    def self.log_warn(message)
      log_level = Setting.plugin_mail_receiver['log_level'] || 'info'
      return unless ['debug', 'info', 'warn'].include?(log_level)
      log_mail("[WARN] #{message}")
    end

    def self.log_error(message)
      log_level = Setting.plugin_mail_receiver['log_level'] || 'info'
      return unless ['debug', 'info', 'warn', 'error'].include?(log_level)
      log_mail("[ERROR] #{message}")
    end

    def self.log_debug(message)
      log_level = Setting.plugin_mail_receiver['log_level'] || 'info'
      return unless log_level == 'debug'
      log_mail("[DEBUG] #{message}")
    end
  end
end