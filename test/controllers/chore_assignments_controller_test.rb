require "test_helper"

class ChoreAssignmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @chore_assignment = chore_assignments(:one)
  end

  test "should get index" do
    get chore_assignments_url
    assert_response :success
  end

  test "should get new" do
    get new_chore_assignment_url
    assert_response :success
  end

  test "should create chore_assignment" do
    assert_difference("ChoreAssignment.count") do
      post chore_assignments_url, params: { chore_assignment: { approved: @chore_assignment.approved, child_id: @chore_assignment.child_id, chore_id: @chore_assignment.chore_id, completed: @chore_assignment.completed, completion_photo: @chore_assignment.completion_photo, day: @chore_assignment.day } }
    end

    assert_redirected_to chore_assignment_url(ChoreAssignment.last)
  end

  test "should show chore_assignment" do
    get chore_assignment_url(@chore_assignment)
    assert_response :success
  end

  test "should get edit" do
    get edit_chore_assignment_url(@chore_assignment)
    assert_response :success
  end

  test "should update chore_assignment" do
    patch chore_assignment_url(@chore_assignment), params: { chore_assignment: { approved: @chore_assignment.approved, child_id: @chore_assignment.child_id, chore_id: @chore_assignment.chore_id, completed: @chore_assignment.completed, completion_photo: @chore_assignment.completion_photo, day: @chore_assignment.day } }
    assert_redirected_to chore_assignment_url(@chore_assignment)
  end

  test "should destroy chore_assignment" do
    assert_difference("ChoreAssignment.count", -1) do
      delete chore_assignment_url(@chore_assignment)
    end

    assert_redirected_to chore_assignments_url
  end
end
