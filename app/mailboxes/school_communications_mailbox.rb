class SchoolCommunicationsMailbox < ActionMailbox::Base
  def process
    parent = Parent.find_by(email: mail.from.first)
    return unless parent  # silently drop unknown senders

    message = parent.school_messages.create!(
      subject:      mail.subject.to_s.truncate(255),
      raw_body:     extract_body,
      from_address: mail.from.first,
      parse_status: "pending"
    )

    ParseSchoolEmailJob.perform_later(message.id)
  end

  private

  def extract_body
    mail.text_part&.decoded || mail.html_part&.decoded || mail.decoded
  end
end
