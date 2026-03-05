class RueController < ApplicationController
  before_action :authenticate_parent!

  def chat
    message = params[:message].to_s.strip
    return render json: { reply: "Please send a message." }, status: :bad_request if message.blank?

    # Cap message length to prevent oversized prompts inflating API costs
    message = message.first(1000)

    # Load history from the database (avoids the 4KB cookie limit that caused truncation
    # and corrupted multi-turn conversations like chore/child creation flows).
    history = load_rue_history
    history = sanitize_history(history)
    history << { role: "user", content: message }

    reply = run_agentic_loop(history)

    # Keep the last 30 entries (~15 turns) — no cookie size concern now.
    save_rue_history(history.last(30))

    render json: { reply: reply }
  end

  def clear
    current_parent.update_column(:rue_history, nil)
    head :ok
  end

  private

  def run_agentic_loop(history)
    client = Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))

    # Safety cap: prevent runaway loops if the API behaves unexpectedly
    10.times do
      response = begin
        client.messages.create(
          model: "claude-sonnet-4-6",
          max_tokens: 1024,
          system: rue_system_prompt,
          messages: history,
          tools: rue_tools
        )
      rescue Anthropic::Errors::APIError => e
        # APIError is the base for all HTTP status errors. Note: must be APIError (all-caps).
        status = e.respond_to?(:status) ? e.status : nil
        if status == 529 || e.message.include?("529") || e.message.include?("overloaded")
          return "I'm having a little trouble reaching my brain right now — Anthropic is busy. Give it a few seconds and try again!"
        elsif status == 400 || e.message.include?("invalid_request")
          # 400 most often means the message history got corrupted (e.g. a tool_use block
          # with no matching tool_result). Clear the stale history so the next request starts clean.
          history.clear
          return "I got a little turned around there! I've reset our conversation — anything I already created is still saved. What would you like to do next?"
        end
        return "I ran into an unexpected error (#{status}). Please try again."
      end

      if response.stop_reason == :end_turn
        text = response.content.find { |b| b.type == :text }&.text || "Done!"
        history << { role: "assistant", content: serialize_content(response.content) }
        return text

      elsif response.stop_reason == :tool_use
        # Append Claude's assistant turn (which includes the tool_use blocks)
        history << { role: "assistant", content: serialize_content(response.content) }

        # Execute each tool Claude requested and collect results
        tool_results = response.content
          .select { |b| b.type == :tool_use }
          .map { |tool_call| execute_tool(tool_call) }

        # Return results to Claude as a user message (required by the API)
        history << {
          role: "user",
          content: tool_results.map { |r|
            { type: "tool_result", tool_use_id: r[:tool_use_id], content: r[:result] }
          }
        }
        # Loop: Claude will now read the tool results and respond
      else
        return "Something unexpected happened. Please try again."
      end
    end

    "I got a bit confused there — could you try rephrasing that?"
  end

  # Convert Anthropic response objects → plain hashes for session storage.
  # Truncate long string values in tool_use inputs to keep the cookie small —
  # Claude already acted on the full value in the current turn, so trimming
  # the stored copy is safe for history replay.
  def serialize_content(blocks)
    blocks.map do |b|
      case b.type
      when :text then { type: "text", text: b.text }
      when :tool_use
        truncated_input = b.input.transform_values { |v| v.is_a?(String) ? v.first(300) : v }
        { type: "tool_use", id: b.id, name: b.name, input: truncated_input }
      end
    end.compact
  end

  def load_rue_history
    raw = current_parent.rue_history
    return [] if raw.blank?
    parsed = JSON.parse(raw, symbolize_names: false)
    # Normalize keys to symbols so the rest of the controller works uniformly
    parsed.map { |entry| entry.transform_keys(&:to_sym) }
  rescue JSON::ParserError
    []
  end

  def save_rue_history(history)
    current_parent.update_column(:rue_history, history.to_json)
  end

  # Drop any trailing assistant turn that ends with a tool_use block but has no following
  # user turn with tool_result blocks. This broken pattern causes Anthropic to return a
  # 400 invalid_request_error.
  def sanitize_history(history)
    return history if history.empty?

    last = history.last
    if last[:role] == "assistant"
      content = last[:content]
      if content.is_a?(Array) && content.any? { |b| b.is_a?(Hash) && b[:type] == "tool_use" || b["type"] == "tool_use" }
        # Truncate back to the last clean user/assistant exchange
        return history[0...-1]
      end
    end
    history
  end

  def parse_date(date_str)
    return Date.today     if date_str.strip.casecmp("today").zero?
    return Date.tomorrow  if date_str.strip.casecmp("tomorrow").zero?
    Date.parse(date_str)
  rescue ArgumentError, TypeError
    nil
  end

  def execute_tool(tool_call)
    # Normalize to indifferent access once — the gem returns symbol keys but all
    # branches below use string keys (e.g. input["name"]). This covers all branches.
    tool_input = tool_call.input.with_indifferent_access

    result = case tool_call.name
    when "create_child"
      input = tool_input
      pin = input["pin_code"].to_s.strip

      # Validate PIN server-side — Claude's schema hint is not enforcement
      unless pin.match?(/\A\d{4}\z/)
        return { tool_use_id: tool_call.id, result: "Error: PIN must be exactly 4 digits (numbers only)." }
      end

      birthday = nil
      if input["birthday"].present?
        birthday = Date.parse(input["birthday"]) rescue nil
      end

      child = current_parent.children.create!(
        name:     input["name"].to_s.strip,
        pin_code: pin,
        birthday: birthday
      )

      "Successfully created a child account for #{child.name}. They can log in with PIN #{child.pin_code}."

    when "edit_child"
      input = tool_input
      child = current_parent.children.find_by(name: input["child_name"])
      unless child
        known = current_parent.children.pluck(:name).join(", ")
        return { tool_use_id: tool_call.id, result: "No child named '#{input['child_name']}' found. Known children: #{known.presence || 'none'}." }
      end

      updates = {}

      if input["new_name"].present?
        updates[:name] = input["new_name"].to_s.strip
      end

      if input["new_pin_code"].present?
        pin = input["new_pin_code"].to_s.strip
        unless pin.match?(/\A\d{4}\z/)
          return { tool_use_id: tool_call.id, result: "Error: New PIN must be exactly 4 digits (numbers only)." }
        end
        updates[:pin_code] = pin
      end

      if input["new_birthday"].present?
        updates[:birthday] = Date.parse(input["new_birthday"]) rescue nil
      end

      if updates.empty?
        "No changes were made — nothing new was provided."
      else
        child.update!(updates)
        changed = updates.keys.map { |k| k.to_s.delete_prefix("new_").humanize.downcase }.join(" and ")
        "Updated #{child.name}'s #{changed} successfully."
      end

    when "delete_child"
      input = tool_input
      child = current_parent.children.find_by(name: input["child_name"])
      unless child
        known = current_parent.children.pluck(:name).join(", ")
        return { tool_use_id: tool_call.id, result: "No child named '#{input['child_name']}' found. Known children: #{known.presence || 'none'}." }
      end
      child_name = child.name
      child.destroy!
      "#{child_name}'s account has been permanently deleted, including all their chore history and token balance."

    when "create_chore"
      input = tool_input
      chore = current_parent.chores.create!(
        name:               input["name"].to_s.strip,
        definition_of_done: input["definition_of_done"].to_s.strip,
        token_amount:       input["token_amount"].to_i,
        description:        input["description"].to_s.strip.presence
      )
      "Created chore '#{chore.name}' worth #{chore.token_amount} tokens."

    when "edit_chore"
      input = tool_input
      chore = current_parent.chores.find_by(name: input["chore_name"])
      unless chore
        known = current_parent.chores.pluck(:name).join(", ")
        return { tool_use_id: tool_call.id, result: "No chore named '#{input['chore_name']}' found. Known chores: #{known.presence || 'none'}." }
      end

      updates = {}
      updates[:name]               = input["new_name"].to_s.strip        if input["new_name"].present?
      updates[:definition_of_done] = input["new_definition_of_done"].to_s.strip if input["new_definition_of_done"].present?
      updates[:token_amount]       = input["new_token_amount"].to_i      if input["new_token_amount"].present?
      updates[:description]        = input["new_description"].to_s.strip if input["new_description"].present?

      if updates.empty?
        "No changes were made — nothing new was provided."
      else
        chore.update!(updates)
        changed = updates.keys.map { |k| k.to_s.delete_prefix("new_").humanize.downcase }.join(", ")
        "Updated '#{chore.name}': #{changed}."
      end

    when "delete_chore"
      input = tool_input
      chore = current_parent.chores.find_by(name: input["chore_name"])
      unless chore
        known = current_parent.chores.pluck(:name).join(", ")
        return { tool_use_id: tool_call.id, result: "No chore named '#{input['chore_name']}' found. Known chores: #{known.presence || 'none'}." }
      end
      chore_name = chore.name
      chore.destroy!
      "The chore '#{chore_name}' has been permanently deleted."

    when "assign_chore"
      input         = tool_input
      child_name    = input["child_name"].to_s.strip
      chore_name    = input["chore_name"].to_s.strip
      date_str      = input["date"].to_s.strip
      require_photo = input["require_photo"] || false

      child = current_parent.children.find_by(name: child_name)
      return { tool_use_id: tool_call.id, result: "No child named '#{child_name}' found." } unless child

      chore = current_parent.chores.find_by(name: chore_name)
      return { tool_use_id: tool_call.id, result: "No chore named '#{chore_name}' found." } unless chore

      scheduled_on = parse_date(date_str)
      return { tool_use_id: tool_call.id, result: "I couldn't understand the date '#{date_str}'. Please use 'today', 'tomorrow', or a date in YYYY-MM-DD format." } unless scheduled_on

      if ChoreAssignment.exists?(child: child, chore: chore, scheduled_on: scheduled_on)
        return { tool_use_id: tool_call.id, result: "'#{chore_name}' is already assigned to #{child_name} on #{scheduled_on.strftime('%B %-d')}." }
      end

      ChoreAssignment.create!(child: child, chore: chore, scheduled_on: scheduled_on, require_photo: require_photo)
      photo_note = require_photo ? " (photo required)" : ""
      "Assigned '#{chore_name}' to #{child_name} on #{scheduled_on.strftime('%B %-d, %Y')}#{photo_note}."

    when "unassign_chore"
      input      = tool_input
      child_name = input["child_name"].to_s.strip
      chore_name = input["chore_name"].to_s.strip
      date_str   = input["date"].to_s.strip

      child = current_parent.children.find_by(name: child_name)
      return { tool_use_id: tool_call.id, result: "No child named '#{child_name}' found." } unless child

      chore = current_parent.chores.find_by(name: chore_name)
      return { tool_use_id: tool_call.id, result: "No chore named '#{chore_name}' found." } unless chore

      scheduled_on = parse_date(date_str)
      return { tool_use_id: tool_call.id, result: "I couldn't understand the date '#{date_str}'." } unless scheduled_on

      assignment = ChoreAssignment.find_by(child: child, chore: chore, scheduled_on: scheduled_on)
      return { tool_use_id: tool_call.id, result: "No assignment found for '#{chore_name}' assigned to #{child_name} on #{scheduled_on.strftime('%B %-d')}." } unless assignment

      assignment.destroy!
      "Removed '#{chore_name}' from #{child_name}'s schedule on #{scheduled_on.strftime('%B %-d, %Y')}."

    else
      "Unknown tool: #{tool_call.name}"
    end

    { tool_use_id: tool_call.id, result: result }
  rescue => e
    { tool_use_id: tool_call.id, result: "Error: #{e.message}" }
  end

  def rue_system_prompt
    children_names = current_parent.children.map(&:name)
    children_text  = children_names.any? ? children_names.join(", ") : "none yet"

    chores_names = current_parent.chores.map(&:name)
    chores_text  = chores_names.any? ? chores_names.join(", ") : "none yet"

    todays_lines = current_parent.children.flat_map do |child|
      child.chore_assignments.where(scheduled_on: Date.today).includes(:chore).map do |a|
        status = a.approved? ? "approved" : (a.completed? ? "pending review" : "not done")
        "  - #{child.name}: #{a.chore.name} (#{status})"
      end
    end
    assignments_text = todays_lines.any? ? todays_lines.join("\n") : "  (none)"

    <<~PROMPT
      You are Rue, a warm and friendly assistant inside ChoreQuest — an app that helps parents assign chores to their kids, who earn tokens they can spend on screen time and games.

      You help parents manage their household. Right now you can:
      - Create, edit, and delete child accounts
      - Create, edit, and delete chores
      - Assign chores to children for specific dates
      - Remove chore assignments

      Current parent: #{current_parent.email}
      Their children: #{children_text}
      Their chores: #{chores_text}
      Today's date: #{Date.today}

      Today's chore assignments:
      #{assignments_text}

      ## Creating children
      Collect: name (required), 4-digit PIN (required), birthday (optional — ask but accept "skip").

      ## Creating chores
      1. Ask for the chore name.
      2. Based on the name, SUGGEST a concrete, kid-friendly "definition of done" — describe exactly what the finished chore looks like in 1-2 sentences (e.g. for "Clean your room": "All clothes are put away, the floor is clear of toys and trash, the bed is made, and the desk is tidy."). Present it and ask if it looks good or if they'd like to change it.
      3. Ask how many tokens it should be worth (typical range: 5–25).
      4. Ask for an optional short description (accept "skip").
      5. Then call create_chore with the confirmed values.

      ## Assigning chores
      - If the parent doesn't specify a date, ask "Which date should I schedule this for?" before calling assign_chore.
      - If they say "today" or "tomorrow", use those words directly.
      - If they name a weekday (e.g. "Monday"), calculate the next occurrence of that day, confirm it ("I'll schedule it for Monday, March 9th — does that work?"), then proceed.
      - If photo proof isn't mentioned, default to not required unless they ask for it.
      - You can assign multiple chores in one message — call assign_chore once per chore.

      ## Removing chore assignments
      ALWAYS confirm first: "Just to confirm: remove '[chore]' from [child]'s schedule on [date]?" Only call unassign_chore after an explicit yes.

      ## Editing
      Ask which field(s) to change and the new values before calling any edit tool.

      ## Deleting
      ALWAYS confirm first before deleting anything — say "Just to confirm: permanently delete [name]?" and only call the delete tool after the parent says yes.

      After using a tool, confirm what you did concisely. Keep responses warm and brief. Never expose raw database IDs.
    PROMPT
  end

  def rue_tools
    [
      {
        name: "create_child",
        description: "Creates a new child account for the current parent. Only call this after collecting the child's name and pin_code through conversation.",
        input_schema: {
          type: "object",
          properties: {
            name: {
              type: "string",
              description: "The child's first name"
            },
            pin_code: {
              type: "string",
              description: "A 4-digit PIN the child will use to log in (exactly 4 digits, e.g. '1234')",
              pattern: "^\\d{4}$"
            },
            birthday: {
              type: "string",
              description: "Child's birthday in YYYY-MM-DD format (optional — omit if not provided)"
            }
          },
          required: ["name", "pin_code"]
        }
      },
      {
        name: "edit_child",
        description: "Updates a child's name, PIN, or birthday. Only call after collecting which fields to change and their new values.",
        input_schema: {
          type: "object",
          properties: {
            child_name: {
              type: "string",
              description: "The current name of the child to edit"
            },
            new_name: {
              type: "string",
              description: "New name for the child (omit if not changing)"
            },
            new_pin_code: {
              type: "string",
              description: "New 4-digit PIN (omit if not changing)",
              pattern: "^\\d{4}$"
            },
            new_birthday: {
              type: "string",
              description: "New birthday in YYYY-MM-DD format (omit if not changing)"
            }
          },
          required: ["child_name"]
        }
      },
      {
        name: "delete_child",
        description: "Permanently deletes a child account and ALL their data (chore history, token balance, game sessions). Only call after the parent has explicitly confirmed the deletion.",
        input_schema: {
          type: "object",
          properties: {
            child_name: {
              type: "string",
              description: "The name of the child to delete"
            }
          },
          required: ["child_name"]
        }
      },
      {
        name: "create_chore",
        description: "Creates a new chore for the current parent. Only call after collecting the name, definition_of_done (confirmed by parent), and token_amount through conversation.",
        input_schema: {
          type: "object",
          properties: {
            name: {
              type: "string",
              description: "The chore name (e.g. 'Clean your room')"
            },
            definition_of_done: {
              type: "string",
              description: "A clear, kid-friendly description of what 'done' looks like"
            },
            token_amount: {
              type: "integer",
              description: "Number of tokens earned for completing this chore (typically 5–25)"
            },
            description: {
              type: "string",
              description: "Optional short description or notes about the chore"
            }
          },
          required: ["name", "definition_of_done", "token_amount"]
        }
      },
      {
        name: "edit_chore",
        description: "Updates a chore's name, definition of done, token amount, or description. Only call after collecting which fields to change.",
        input_schema: {
          type: "object",
          properties: {
            chore_name: {
              type: "string",
              description: "The current name of the chore to edit"
            },
            new_name: {
              type: "string",
              description: "New name (omit if not changing)"
            },
            new_definition_of_done: {
              type: "string",
              description: "New definition of done (omit if not changing)"
            },
            new_token_amount: {
              type: "integer",
              description: "New token amount (omit if not changing)"
            },
            new_description: {
              type: "string",
              description: "New description (omit if not changing)"
            }
          },
          required: ["chore_name"]
        }
      },
      {
        name: "delete_chore",
        description: "Permanently deletes a chore. Only call after the parent has explicitly confirmed the deletion.",
        input_schema: {
          type: "object",
          properties: {
            chore_name: {
              type: "string",
              description: "The name of the chore to delete"
            }
          },
          required: ["chore_name"]
        }
      },
      {
        name: "assign_chore",
        description: "Schedule a chore for a specific child on a specific date. Use this when a parent wants to assign a chore to a child for today, tomorrow, or any specific date.",
        input_schema: {
          type: "object",
          properties: {
            child_name: {
              type: "string",
              description: "The child's name exactly as it appears in the system."
            },
            chore_name: {
              type: "string",
              description: "The chore name exactly as it appears in the system."
            },
            date: {
              type: "string",
              description: "The date to schedule the chore. Use 'today', 'tomorrow', or YYYY-MM-DD format."
            },
            require_photo: {
              type: "boolean",
              description: "Whether the child must submit a photo to prove completion. Defaults to false."
            }
          },
          required: ["child_name", "chore_name", "date"]
        }
      },
      {
        name: "unassign_chore",
        description: "Remove a scheduled chore assignment from a child's schedule for a specific date. Only call after the parent has explicitly confirmed.",
        input_schema: {
          type: "object",
          properties: {
            child_name: {
              type: "string",
              description: "The child's name."
            },
            chore_name: {
              type: "string",
              description: "The chore name to remove."
            },
            date: {
              type: "string",
              description: "The date of the assignment to remove. Use 'today', 'tomorrow', or YYYY-MM-DD format."
            }
          },
          required: ["child_name", "chore_name", "date"]
        }
      }
    ]
  end
end
