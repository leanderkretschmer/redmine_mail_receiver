require 'net/imap'
require 'mail'

module MailReceiver
  class Receiver
    def self.process
      cfg = Setting.plugin_mail_receiver

      return if cfg['imap_host'].blank?

      imap = Net::IMAP.new(
        cfg['imap_host'],
        cfg['imap_port'].to_i,
        cfg['imap_ssl'] == 'true'
      )
      imap.login(cfg['imap_user'], cfg['imap_password'])
      imap.select('INBOX')

      imap.search(['UNSEEN']).each do |msg_id|
        msg = imap.fetch(msg_id, 'RFC822')[0].attr['RFC822']
        mail = Mail.read_from_string(msg)

        process_mail(mail)

        imap.store(msg_id, "+FLAGS", [:Seen])
      end

      imap.logout
      imap.disconnect
    end

    def self.process_mail(mail)
      subject = mail.subject.to_s
      body = mail.body.decoded
      from = mail.from.first.downcase

      user = User.find_by_mail(from)
      ticket_id = subject[/\[#(\d+)\]/, 1]

      if ticket_id
        issue = Issue.find_by_id(ticket_id)
        return unless issue

        if user
          add_journal(issue, user, body)
        else
          user = create_silent_user(from, mail)
          add_journal(issue, user, body)
        end
      else
        if user
          create_issue(user, subject, body)
        else
          # Unbekannter Absender ohne Ticket-ID → verwerfen
        end
      end
    end

    def self.add_journal(issue, user, body)
      issue.init_journal(user, body)
      issue.save
    end

    def self.create_issue(user, subject, body)
      project = Project.find_by_identifier(
        Setting.plugin_mail_receiver['default_project']
      )
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
  end
end