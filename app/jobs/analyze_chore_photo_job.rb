# Background job: sends the chore attempt photo to Claude AI for analysis.
# Resizes the image, calls the Claude API, and updates the attempt with the verdict:
#   APPROVED    → auto-approves the attempt and grants tokens to the child
#   REJECTED    → auto-rejects the attempt with AI feedback message
#   NEEDS_REVIEW → leaves the attempt pending for parent review on the dashboard
# On API failure, falls back to NEEDS_REVIEW so no attempt is silently lost.
class AnalyzeChorePhotoJob < ApplicationJob
  queue_as :default

  TIMEOUT_SECONDS = 30

  def perform(chore_attempt_id)
    attempt = ChoreAttempt.find_by(id: chore_attempt_id)
    return unless attempt && attempt.photo.attached?

    assignment = attempt.chore_assignment
    chore      = assignment.chore

    verdict, message = analyze_photo(attempt, chore)
    apply_verdict(attempt, assignment, chore, verdict, message)
  rescue => e
    Sentry.capture_exception(e, extra: { chore_attempt_id: chore_attempt_id })
    Rails.logger.error "AnalyzeChorePhotoJob failed for attempt #{chore_attempt_id}: #{e.message}"
    attempt&.update_columns(ai_verdict: 'NEEDS_REVIEW', ai_analyzed_at: Time.current)
  end

  private

  def analyze_photo(attempt, chore)
    tempfile = Tempfile.new(['chore_photo', '.jpg'])
    tempfile.binmode
    tempfile.write(attempt.photo.download)
    tempfile.rewind

    resized = ImageProcessing::MiniMagick
      .source(tempfile.path)
      .resize_to_limit(1568, 1568)
      .convert("jpeg")
      .call
    base64_image = Base64.strict_encode64(File.binread(resized.path))
    resized.close!

    # Determine per-task vs whole-chore mode
    chore_task = attempt.chore_task_id.present? ? ChoreTask.find_by(id: attempt.chore_task_id) : nil

    if chore_task
      # Per-step mode: evaluate only this specific task
      prompt_text = <<~PROMPT
        You are evaluating whether a child has completed a specific step of a household chore.

        Chore: #{chore.name}
        Step to evaluate: #{chore_task.title}

        Look at the photo and determine if this specific step appears to be genuinely complete.

        Respond with EXACTLY two lines:
        Line 1: One word only — APPROVED, REJECTED, or NEEDS_REVIEW
        Line 2: One short encouraging sentence written directly to the child (e.g. "Great job making your bed so neatly!" or "It looks like the sink still has dishes — give it another try!")

        Use NEEDS_REVIEW when the photo is unclear, blurry, or you genuinely cannot determine completion status.
      PROMPT

      model_photo_source = chore_task.model_photo.attached? ? chore_task.model_photo : nil
    else
      # Whole-chore mode: evaluate the entire chore
      tasks = chore.chore_tasks.to_a
      task_section = if tasks.any?
        task_lines = tasks.each_with_index.map { |t, i| "#{i + 1}. #{t.title}" }.join("\n")
        "\n\nThis chore requires completing the following tasks in order:\n#{task_lines}\nCheck that each task appears to be completed in the submitted photo(s)."
      else
        ""
      end

      prompt_text = <<~PROMPT
        You are evaluating whether a child has completed a household chore.

        Chore: #{chore.name}
        Description: #{chore.definition_of_done.presence || chore.description}#{task_section}

        Look at the photo and determine if the chore appears to be genuinely complete.

        Respond with EXACTLY two lines:
        Line 1: One word only — APPROVED, REJECTED, or NEEDS_REVIEW
        Line 2: One short encouraging sentence written directly to the child (e.g. "Great job making your bed so neatly!" or "It looks like the sink still has dishes — give it another try!")

        Use NEEDS_REVIEW when the photo is unclear, blurry, or you genuinely cannot determine completion status.
      PROMPT

      model_photo_source = chore.model_photo.attached? ? chore.model_photo : nil
    end

    # Build content array — prepend model photo if available
    content = []
    if model_photo_source
      model_base64 = Base64.strict_encode64(model_photo_source.download)
      content << {
        type:   'image',
        source: { type: 'base64', media_type: model_photo_source.content_type, data: model_base64 }
      }
      content << { type: 'text', text: "Above is the reference photo showing what 'done' looks like." }
    end
    content << {
      type:   'image',
      source: { type: 'base64', media_type: 'image/jpeg', data: base64_image }
    }
    content << { type: 'text', text: prompt_text }

    client = Anthropic::Client.new(api_key: ENV.fetch('ANTHROPIC_API_KEY'))

    response = Timeout.timeout(TIMEOUT_SECONDS) do
      client.messages.create(
        model:      'claude-haiku-4-5-20251001',
        max_tokens: 256,
        messages: [{ role: 'user', content: content }]
      )
    end

    lines   = response.content.first.text.strip.lines.map(&:strip).reject(&:empty?)
    verdict = lines[0].to_s.upcase.strip
    verdict = 'NEEDS_REVIEW' unless %w[APPROVED REJECTED NEEDS_REVIEW].include?(verdict)
    message = lines[1].to_s.strip

    [verdict, message]
  ensure
    tempfile&.close!
  end

  def apply_verdict(attempt, assignment, chore, verdict, message)
    case verdict
    when 'APPROVED'
      attempt.update!(
        status:         'approved',
        parent_note:    message,
        ai_verdict:     'APPROVED',
        ai_message:     message,
        ai_analyzed_at: Time.current
      )
      # Only mark the whole assignment approved when all required tasks are done
      if all_required_tasks_approved?(assignment)
        assignment.update!(approved: true, completed: true, completed_at: Time.current)
        TokenTransaction.create!(
          child:       attempt.child,
          amount:      chore.token_amount.to_i,
          description: "Chore approved: #{chore.name}"
        )
      end
    when 'REJECTED'
      attempt.update!(
        status:         'rejected',
        parent_note:    message,
        ai_verdict:     'REJECTED',
        ai_message:     message,
        ai_analyzed_at: Time.current
      )
      assignment.update!(completed: false, approved: nil)
    else # NEEDS_REVIEW
      attempt.update!(
        ai_verdict:     'NEEDS_REVIEW',
        ai_message:     message,
        ai_analyzed_at: Time.current
      )
      # status stays 'pending' — surfaces in parent dashboard for manual review
    end
  end

  # Returns true when there are no photo_required tasks (simple chore)
  # or when every photo_required task now has an approved ChoreAttempt.
  def all_required_tasks_approved?(assignment)
    required_tasks = assignment.chore.chore_tasks.where(photo_required: true)
    return true if required_tasks.empty?

    required_tasks.all? do |task|
      assignment.chore_attempts.where(chore_task_id: task.id, status: 'approved').exists?
    end
  end
end
