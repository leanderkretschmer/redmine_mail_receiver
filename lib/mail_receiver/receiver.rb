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
    end

    def self.handle_mail(mail)
      subject = mail.subject.to_s
      body = mail.body.decoded
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
  end
end