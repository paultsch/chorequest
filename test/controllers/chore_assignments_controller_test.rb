require "test_helper"

class ChoreAssignmentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @parent = parents(:one)
    @parent_two = parents(:two)
    @child_one = children(:one)
    @child_two = children(:two)
    @chore_one = chores(:one)
    @chore_two = chores(:two)
    @chore_assignment = chore_assignments(:one)
  end

  # Authentication gate tests

  test "unauthenticated request to index redirects to sign-in" do
    get chore_assignments_url
    assert_redirected_to new_parent_session_path
  end

  test "unauthenticated request to new redirects to sign-in" do
    get new_chore_assignment_url
    assert_redirected_to new_parent_session_path
  end

  test "unauthenticated request to create redirects to sign-in" do
    post chore_assignments_url, params: { chore_assignment: { child_id: @child_one.id, chore_id: @chore_one.id, scheduled_on: Date.current } }
    assert_redirected_to new_parent_session_path
  end

  test "unauthenticated request to show redirects to sign-in" do
    get chore_assignment_url(@chore_assignment)
    assert_redirected_to new_parent_session_path
  end

  test "unauthenticated request to edit redirects to sign-in" do
    get edit_chore_assignment_url(@chore_assignment)
    assert_redirected_to new_parent_session_path
  end

  # Happy path tests - authenticated parent can perform actions

  test "authenticated parent can view index" do
    sign_in @parent
    get chore_assignments_url
    assert_response :success
  end

  test "authenticated parent can view their own chore assignment" do
    sign_in @parent
    get chore_assignment_url(@chore_assignment)
    assert_response :success
  end

  test "authenticated parent can get new chore_assignment form" do
    sign_in @parent
    get new_chore_assignment_url
    assert_response :success
  end

  test "authenticated parent can edit their own chore assignment" do
    sign_in @parent
    get edit_chore_assignment_url(@chore_assignment)
    assert_response :success
  end

  test "authenticated parent can create chore assignment for their own child" do
    sign_in @parent
    assert_difference("ChoreAssignment.count") do
      post chore_assignments_url, params: { chore_assignment: { child_id: @child_one.id, chore_id: @chore_one.id, scheduled_on: Date.tomorrow, require_photo: false } }
    end
    assert_redirected_to child_path(@child_one)
  end

  # Cross-parent isolation tests

  test "parent cannot view another parent's chore assignment" do
    sign_in @parent_two
    # @chore_assignment belongs to @child_one which belongs to @parent
    get chore_assignment_url(@chore_assignment)
    assert_response :not_found
  end

  test "parent cannot edit another parent's chore assignment" do
    sign_in @parent_two
    get edit_chore_assignment_url(@chore_assignment)
    assert_response :not_found
  end

  test "parent cannot update another parent's chore assignment" do
    sign_in @parent_two
    patch chore_assignment_url(@chore_assignment), params: { chore_assignment: { require_photo: true } }
    assert_response :not_found
  end

  test "parent cannot destroy another parent's chore assignment" do
    sign_in @parent_two
    assert_no_difference("ChoreAssignment.count") do
      delete chore_assignment_url(@chore_assignment)
    end
    assert_response :not_found
  end

  # Child_id ownership validation in create

  test "create rejects invalid child_id" do
    sign_in @parent
    assert_no_difference("ChoreAssignment.count") do
      post chore_assignments_url, params: { chore_assignment: { child_id: 99999, chore_id: @chore_one.id, scheduled_on: Date.current } }
    end
    assert_redirected_back
    assert_match /Invalid child/, flash[:alert]
  end

  test "create rejects foreign child_id (another parent's child)" do
    sign_in @parent
    assert_no_difference("ChoreAssignment.count") do
      post chore_assignments_url, params: { chore_assignment: { child_id: @child_two.id, chore_id: @chore_one.id, scheduled_on: Date.current } }
    end
    assert_redirected_back
    assert_match /Invalid child/, flash[:alert]
  end

  # Chore ownership validation in create

  test "create rejects invalid chore_id" do
    sign_in @parent
    assert_no_difference("ChoreAssignment.count") do
      post chore_assignments_url, params: { chore_assignment: { child_id: @child_one.id, chore_id: 99999, scheduled_on: Date.current } }
    end
    assert_redirected_back
    assert_match /Invalid chore/, flash[:alert]
  end

  test "create rejects foreign chore_id (another parent's chore)" do
    sign_in @parent
    other_parent_chore = parents(:two).chores.create!(name: "Other Chore", token_amount: 5)
    assert_no_difference("ChoreAssignment.count") do
      post chore_assignments_url, params: { chore_assignment: { child_id: @child_one.id, chore_id: other_parent_chore.id, scheduled_on: Date.current } }
    end
    assert_redirected_back
    assert_match /Invalid chore/, flash[:alert]
  end

  # Bulk update ownership tests

  test "bulk_update only affects current parent's assignments" do
    sign_in @parent
    # Create an assignment for parent_one's child
    assignment1 = ChoreAssignment.create!(child: @child_one, chore: @chore_one, scheduled_on: Date.current, require_photo: false)
    # Create an assignment for parent_two's child
    assignment2 = ChoreAssignment.create!(child: @child_two, chore: parents(:two).chores.first, scheduled_on: Date.current, require_photo: false)

    # Try to bulk approve both
    post bulk_update_chore_assignments_url, params: { assignment_ids: [assignment1.id, assignment2.id], bulk_action: 'approve' }

    # Only assignment1 should be approved (it belongs to parent_one)
    assignment1.reload
    assignment2.reload
    assert_equal true, assignment1.approved
    assert_equal false, assignment2.approved
  end

  test "bulk_update cannot modify another parent's assignments" do
    sign_in @parent_two
    # Create an assignment for parent_one's child
    assignment1 = ChoreAssignment.create!(child: @child_one, chore: @chore_one, scheduled_on: Date.current, require_photo: false)

    # Try to delete it
    post bulk_update_chore_assignments_url, params: { assignment_ids: [assignment1.id], bulk_action: 'delete' }

    # Assignment should still exist
    assert ChoreAssignment.exists?(assignment1.id)
  end

  # Index only shows current parent's children and chores

  test "index only shows current parent's children" do
    sign_in @parent
    get chore_assignments_url
    assert_response :success
    # Verify that child_two (parent_two's child) is not in the children list
    assert_no_match /#{@child_two.name}/, response.body
  end

  test "index only shows current parent's chores" do
    sign_in @parent
    other_parent_chore = parents(:two).chores.create!(name: "Bob's Secret Chore", token_amount: 5)
    get chore_assignments_url
    assert_response :success
    # Verify that the other parent's chore is not in the chores list
    assert_no_match /Bob's Secret Chore/, response.body
  end
end
