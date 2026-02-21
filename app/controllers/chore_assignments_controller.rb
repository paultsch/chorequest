class ChoreAssignmentsController < ApplicationController
  before_action :set_chore_assignment, only: %i[ show edit update destroy ]

  # GET /chore_assignments or /chore_assignments.json
  def index
    @chore_assignments = ChoreAssignment.all
  end

  # GET /chore_assignments/1 or /chore_assignments/1.json
  def show
  end

  # GET /chore_assignments/new
  def new
    @chore_assignment = ChoreAssignment.new
  end

  # GET /chore_assignments/1/edit
  def edit
  end

  # POST /chore_assignments or /chore_assignments.json
  def create
    @chore_assignment = ChoreAssignment.new(chore_assignment_params)

    respond_to do |format|
      if @chore_assignment.save
        format.html { redirect_to @chore_assignment, notice: "Chore assignment was successfully created." }
        format.json { render :show, status: :created, location: @chore_assignment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @chore_assignment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /chore_assignments/1 or /chore_assignments/1.json
  def update
    respond_to do |format|
      if @chore_assignment.update(chore_assignment_params)
        format.html { redirect_to @chore_assignment, notice: "Chore assignment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @chore_assignment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @chore_assignment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /chore_assignments/1 or /chore_assignments/1.json
  def destroy
    @chore_assignment.destroy!

    respond_to do |format|
      format.html { redirect_to chore_assignments_path, notice: "Chore assignment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_chore_assignment
      @chore_assignment = ChoreAssignment.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def chore_assignment_params
      params.require(:chore_assignment).permit(:child_id, :chore_id, :day, :completed, :approved, :completion_photo)
    end
end
