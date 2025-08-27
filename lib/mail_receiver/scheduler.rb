module MailReceiver
    class Scheduler
      def self.send_reminders
        # ruft die eingebaute Redmine Reminder Logik auf
        Mailer.reminders(
          days: 7,
          users: User.active
        ).deliver
      end
    end
  end