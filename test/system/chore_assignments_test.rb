require "application_system_test_case"

class ChoreAssignmentsTest < ApplicationSystemTestCase
  setup do
    @chore_assignment = chore_assignments(:one)
  end

  test "visiting the index" do
    visit chore_assignments_url
    assert_selector "h1", text: "Chore assignments"
  end

  test "should create chore assignment" do
    visit chore_assignments_url
    click_on "New chore assignment"

    check "Approved" if @chore_assignment.approved
    fill_in "Child", with: @chore_assignment.child_id
    fill_in "Chore", with: @chore_assignment.chore_id
    check "Completed" if @chore_assignment.completed
    fill_in "Completion photo", with: @chore_assignment.completion_photo
    fill_in "Day", with: @chore_assignment.day
    click_on "Create Chore assignment"

    assert_text "Chore assignment was successfully created"
    click_on "Back"
  end

  test "should update Chore assignment" do
    visit chore_assignment_url(@chore_assignment)
    click_on "Edit this chore assignment", match: :first

    check "Approved" if @chore_assignment.approved
    fill_in "Child", with: @chore_assignment.child_id
    fill_in "Chore", with: @chore_assignment.chore_id
    check "Completed" if @chore_assignment.completed
    fill_in "Completion photo", with: @chore_assignment.completion_photo
    fill_in "Day", with: @chore_assignment.day
    click_on "Update Chore assignment"

    assert_text "Chore assignment was successfully updated"
    click_on "Back"
  end

  test "should destroy Chore assignment" do
    visit chore_assignment_url(@chore_assignment)
    click_on "Destroy this chore assignment", match: :first

    assert_text "Chore assignment was successfully destroyed"
  end
end
