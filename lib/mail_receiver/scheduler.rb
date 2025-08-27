module MailReceiver
    class Scheduler
      def self.send_reminders
        Rails.logger.info("[MailReceiver] Sending reminders...")
        Mailer.reminders(days: 7, users: User.active).deliver_now
      end
    end
  end