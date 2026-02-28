# Stores the result of Claude AI photo analysis on each chore attempt.
# ai_verdict: APPROVED / REJECTED / NEEDS_REVIEW (nil while pending analysis)
# ai_message: short encouraging sentence from Claude shown to the child
# ai_analyzed_at: timestamp of when the AI analysis completed
class AddAiVerdictToChoreAttempts < ActiveRecord::Migration[7.1]
  def change
    add_column :chore_attempts, :ai_verdict,     :string
    add_column :chore_attempts, :ai_message,     :text
    add_column :chore_attempts, :ai_analyzed_at, :datetime
  end
end
