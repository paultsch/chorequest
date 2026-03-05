class SchoolMessagesController < ApplicationController
  before_action :authenticate_parent!

  def index
    @needs_attention = current_parent.school_messages.needs_attention
    @recent = current_parent.school_messages.recent.limit(20)
  end

  def update
    @message = current_parent.school_messages.find(params[:id])
    @message.update!(actioned: true, needs_attention: false)
    redirect_to school_messages_path, notice: "Marked as done."
  end
end
