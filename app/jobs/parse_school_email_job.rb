class ParseSchoolEmailJob < ApplicationJob
  queue_as :default

  CATEGORIES = %w[event homework permission_slip absence_alert newsletter announcement unknown].freeze

  def perform(school_message_id)
    message = SchoolMessage.find_by(id: school_message_id)
    return unless message

    client = Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))

    response = client.messages.create(
      model:      "claude-haiku-4-5-20251001",
      max_tokens: 512,
      system:     system_prompt,
      messages:   [{ role: "user", content: format_email(message) }]
    )

    text = response.content.find { |b| b.type == :text }&.text
    raise "No text response from Claude" if text.nil?

    text = text.strip.gsub(/\A```(?:json)?\n?/, "").gsub(/\n?```\z/, "").strip
    parsed = JSON.parse(text)

    message.update!(
      category:        CATEGORIES.include?(parsed["category"]) ? parsed["category"] : "unknown",
      child_name:      parsed["child_name"].presence,
      summary:         parsed["summary"].presence,
      action_item:     parsed["action_item"].presence,
      deadline:        (Date.parse(parsed["deadline"]) rescue nil),
      needs_attention: parsed["needs_attention"] == true,
      parse_status:    "parsed"
    )
  rescue => e
    message&.update!(parse_status: "failed")
    Rails.logger.error("ParseSchoolEmailJob failed for #{school_message_id}: #{e.message}")
  end

  private

  def system_prompt
    <<~PROMPT
      You parse school-to-parent emails and extract structured information. Respond with ONLY valid JSON, no markdown fences.

      Return this exact JSON structure:
      {
        "category": "one of: event, homework, permission_slip, absence_alert, newsletter, announcement, unknown",
        "child_name": "string or null — name of the child this email is about",
        "summary": "1-2 sentence plain-English summary of the email",
        "action_item": "string or null — what the parent needs to do, if anything",
        "deadline": "YYYY-MM-DD or null — due date for any action or event",
        "needs_attention": true or false
      }
    PROMPT
  end

  def format_email(message)
    body = Rails::Html::FullSanitizer.new.sanitize(message.raw_body.to_s).truncate(3000)
    "Subject: #{message.subject}\n\n#{body}"
  end
end
