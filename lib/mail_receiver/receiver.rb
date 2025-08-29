require 'net/imap'
require 'mail'

module MailReceiver
  class Receiver
    def self.process
      cfg = Setting.plugin_mail_receiver
      return if cfg['imap_host'].blank?

      imap = Net::IMAP.new(
        cfg['imap_host'], 
        port: cfg['imap_port'].to_i, 
        ssl: cfg['imap_ssl'] == 'true'
      )
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
      Rails.logger.error("[MailReceiver] IMAP error: #{e.message}")
      add_detailed_log("IMAP error: #{e.message}")
    end
    
    def self.process_manual(count = 10)
      cfg = Setting.plugin_mail_receiver
      return { success: false, error: 'IMAP not configured' } if cfg['imap_host'].blank?

      add_detailed_log("Starting manual import for #{count} emails")
      
      begin
        imap = Net::IMAP.new(
          cfg['imap_host'], 
          port: cfg['imap_port'].to_i, 
          ssl: cfg['imap_ssl'] == 'true'
        )
        add_detailed_log("Connected to IMAP server: #{cfg['imap_host']}:#{cfg['imap_port']}")
        
        imap.login(cfg['imap_user'], cfg['imap_password'])
        add_detailed_log("Logged in as: #{cfg['imap_user']}")
        
        imap.select('INBOX')
        add_detailed_log("Selected INBOX")

        # Hole alle ungelesenen E-Mails
        unseen_messages = imap.search(['UNSEEN'])
        add_detailed_log("Found #{unseen_messages.length} unseen messages")
        
        # Begrenze auf die gewünschte Anzahl
        messages_to_process = unseen_messages.first(count)
        processed_count = 0
        
        messages_to_process.each_with_index do |msg_id, index|
          add_detailed_log("Processing message #{index + 1}/#{messages_to_process.length} (ID: #{msg_id})")
          
          begin
            msg = imap.fetch(msg_id, 'RFC822')[0].attr['RFC822']
            mail = Mail.read_from_string(msg)
            
            add_detailed_log("  From: #{mail.from&.first || 'Unknown'}")
            add_detailed_log("  Subject: #{mail.subject || 'No subject'}")
            
            handle_mail(mail)
            imap.store(msg_id, "+FLAGS", [:Seen])
            
            processed_count += 1
            add_detailed_log("  ✓ Successfully processed")
          rescue => e
            add_detailed_log("  ✗ Error processing message: #{e.message}")
            Rails.logger.error("[MailReceiver] Error processing message #{msg_id}: #{e.message}")
          end
        end

        imap.logout
        imap.disconnect
        add_detailed_log("Manual import completed. Processed #{processed_count}/#{messages_to_process.length} messages")
        
        return { 
          success: true, 
          processed: processed_count, 
          total: messages_to_process.length 
        }
      rescue => e
        add_detailed_log("Manual import failed: #{e.message}")
        Rails.logger.error("[MailReceiver] Manual import error: #{e.message}")
        return { success: false, error: e.message }
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
          log_mail("Added comment to ##{issue.id} from #{from}")
        end
      else
        if user
          if Setting.plugin_mail_receiver['no_ticket_mode'] == 'comment'
            fallback_id = Setting.plugin_mail_receiver['fallback_issue_id'].to_i
            if fallback_id > 0 && (issue = Issue.find_by_id(fallback_id))
              add_journal(issue, user, "No ticket id found. Moved to Posteingang\n\n#{body}")
              log_mail("Moved mail from #{from} to fallback issue ##{issue.id}")
            end
          else
            create_issue(user, subject, body)
            log_mail("Created new issue from #{from}")
          end
        else
          log_mail("Ignored mail from unknown user #{from}")
        end
      end
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
      log = log.last(50) # nur die letzten 50 Einträge behalten
      Setting.plugin_mail_receiver = Setting.plugin_mail_receiver.merge('mail_log' => log)
    end
    
    def self.add_detailed_log(message)
      log = Setting.plugin_mail_receiver['detailed_log'] || []
      log << "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S.%L')}] #{message}"
      log = log.last(200) # nur die letzten 200 Einträge behalten
      Setting.plugin_mail_receiver = Setting.plugin_mail_receiver.merge('detailed_log' => log)
    end
    
    private
    
    def self.extract_mail_body(mail)
      # Versuche zuerst den Text-Teil zu finden
      content = nil
      
      if mail.multipart?
        # Suche nach text/plain Teil
        text_part = mail.text_part
        if text_part
          content = text_part.body.decoded
        else
          # Suche nach text/html Teil und konvertiere zu Text
          html_part = mail.html_part
          if html_part
            content = html_to_text(html_part.body.decoded)
          else
            # Fallback: durchlaufe alle Teile
            mail.parts.each do |part|
              if part.content_type && part.content_type.start_with?('text/plain')
                content = part.body.decoded
                break
              elsif part.content_type && part.content_type.start_with?('text/html')
                content = html_to_text(part.body.decoded)
                break
              end
            end
          end
        end
      else
        # Wenn keine multipart E-Mail, versuche den Body direkt zu dekodieren
        if mail.body
          content = mail.body.decoded
          # Prüfe ob es HTML ist
          if content.include?('<html') || content.include?('<body')
            content = html_to_text(content)
          end
        else
          # Fallback
          content = mail.text_part ? mail.text_part.body.decoded : mail.body.decoded
        end
      end
      
      # Extrahiere nur den aktuellen E-Mail-Inhalt (ohne Antworten/Forwards)
      return extract_original_content(content)
    end
    
    def self.html_to_text(html_content)
      # Einfache HTML zu Text Konvertierung
      text = html_content
        .gsub(/<br\s*\/?>/i, "\n")           # <br> zu Zeilenumbrüchen
        .gsub(/<\/p>/i, "\n\n")              # </p> zu doppelten Zeilenumbrüchen
        .gsub(/<p[^>]*>/i, "")               # <p> Tags entfernen
        .gsub(/<div[^>]*>/i, "")             # <div> Tags entfernen
        .gsub(/<\/div>/i, "\n")              # </div> zu Zeilenumbrüchen
        .gsub(/<[^>]*>/i, "")                # Alle anderen HTML Tags entfernen
        .gsub(/&nbsp;/i, " ")                # &nbsp; zu Leerzeichen
        .gsub(/&amp;/i, "&")                 # &amp; zu &
        .gsub(/&lt;/i, "<")                  # &lt; zu <
        .gsub(/&gt;/i, ">")                  # &gt; zu >
        .gsub(/&quot;/i, '"')                # &quot; zu "
        .gsub(/&#39;/i, "'")                 # &#39; zu '
        .gsub(/\n\s*\n\s*\n/, "\n\n")        # Mehrfache Leerzeilen reduzieren
        .strip                               # Whitespace am Anfang/Ende entfernen
      
      return text
    end
    
    def self.extract_original_content(content)
      return "" if content.nil? || content.empty?
      
      lines = content.split("\n")
      original_lines = []
      
      # Verschiedene Antwort-Marker
      reply_markers = [
        /^>+\s*/,                           # > (Reply-Marker)
        /^On .* wrote:$/i,                  # "On ... wrote:"
        /^Am .* schrieb .*:$/i,             # "Am ... schrieb ...:"
        /^Von: .*$/i,                       # "Von: ..."
        /^From: .*$/i,                      # "From: ..."
        /^Gesendet: .*$/i,                  # "Gesendet: ..."
        /^Sent: .*$/i,                      # "Sent: ..."
        /^An: .*$/i,                        # "An: ..."
        /^To: .*$/i,                        # "To: ..."
        /^Betreff: .*$/i,                   # "Betreff: ..."
        /^Subject: .*$/i,                   # "Subject: ..."
        /^-{3,}.*Original Message.*-{3,}$/i, # "--- Original Message ---"
        /^-{3,}.*Ursprüngliche Nachricht.*-{3,}$/i, # "--- Ursprüngliche Nachricht ---"
        /^From: .*Sent: .*To: .*Subject: .*$/i, # E-Mail-Header-Block
        /^Original Message/i,               # "Original Message"
        /^Ursprüngliche Nachricht/i,        # "Ursprüngliche Nachricht"
        /^Reply to:/i,                      # "Reply to:"
        /^Antwort an:/i,                    # "Antwort an:"
        /^Forwarded message/i,              # "Forwarded message"
        /^Weitergeleitete Nachricht/i,      # "Weitergeleitete Nachricht"
        /^Begin forwarded message/i,        # "Begin forwarded message"
        /^Anfang weitergeleitete Nachricht/i # "Anfang weitergeleitete Nachricht"
      ]
      
      lines.each do |line|
        # Prüfe ob diese Zeile ein Antwort-Marker ist
        is_reply_marker = reply_markers.any? { |marker| line.match(marker) }
        
        if is_reply_marker
          break  # Stoppe hier - alles danach ist Antwort/Forward
        end
        
        original_lines << line
      end
      
      # Entferne leere Zeilen am Ende
      while original_lines.last && original_lines.last.strip.empty?
        original_lines.pop
      end
      
      return original_lines.join("\n").strip
    end
  end
end