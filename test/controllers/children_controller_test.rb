require "test_helper"

class ChildrenControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @parent = parents(:one)
    @parent_two = parents(:two)
    @child_one = children(:one)
    @child_two = children(:two)
    @chore_one = chores(:one)
    @assignment_one = chore_assignments(:one)
  end

  # B2 Bug Fix Tests: Play Gate Fix
  # The play action now checks where.not(approved: true) instead of where(completed: [false, nil])
  # This prevents children from playing if chores are marked complete but not yet approved by parent

  test "unauthenticated request to play redirects to sign in" do
    post play_child_path(@child_one)
    assert_redirected_to new_parent_session_path
  end

  test "authenticated parent can access their own child's play action" do
    sign_in @parent
    post play_child_path(@child_one)
    # Should render play view or redirect to it (render :play)
    assert_response :success
  end

  test "cannot access another parent's child's play action" do
    sign_in @parent_two
    post play_child_path(@child_one)  # parent_two trying to access parent_one's child
    assert_response :not_found
  end

  # Test case 1: Child with NO chores today → play is allowed
  test "play is allowed when child has no chores scheduled for today" do
    sign_in @parent

    # Create a child with no chores for today
    child_no_chores = Child.create!(
      name: "Child No Chores",
      parent: @parent,
      pin_code: "9999",
      birthday: "2015-06-15"
    )

    # Create a game so we can start a session
    game = Game.create!(name: "Test Game")

    post play_child_path(child_no_chores)

    # Should render play view with games available
    assert_response :success
    assert_match /Test Game/, response.body
  end

  # Test case 2: Child with today's chores ALL APPROVED → play is allowed
  test "play is allowed when all today's chores are approved" do
    sign_in @parent

    # Setup: Create assignment for today that is approved
    today = Date.current
    assignment = ChoreAssignment.create!(
      child: @child_one,
      chore: @chore_one,
      scheduled_on: today,
      require_photo: false,
      completed: true,
      approved: true  # KEY: approved = true
    )

    game = Game.create!(name: "Test Game 2")

    post play_child_path(@child_one)

    # Should render play view
    assert_response :success
    assert_match /Test Game 2/, response.body
  end

  # Test case 3: Child with today's chores COMPLETED but NOT APPROVED → play is BLOCKED
  test "play is blocked when today's chores are completed but not approved" do
    sign_in @parent

    # Setup: Create assignment for today that is completed but NOT approved
    today = Date.current
    assignment = ChoreAssignment.create!(
      child: @child_one,
      chore: @chore_one,
      scheduled_on: today,
      require_photo: false,
      completed: true,
      approved: false  # KEY: completed but not approved - this is the bug scenario
    )

    post play_child_path(@child_one)

    # Should redirect back to child view with alert (play is blocked)
    assert_redirected_to child_path(@child_one)
    assert_match /Complete all chores scheduled for today before playing/, flash[:alert]
  end

  # Test case 4: Child with today's chores PENDING (not completed, not approved) → play is BLOCKED
  test "play is blocked when today's chores are pending" do
    sign_in @parent

    # Setup: Create assignment for today that is pending (not completed, not approved)
    today = Date.current
    assignment = ChoreAssignment.create!(
      child: @child_one,
      chore: @chore_one,
      scheduled_on: today,
      require_photo: false,
      completed: false,  # Not completed
      approved: false    # Not approved
    )

    post play_child_path(@child_one)

    # Should redirect back to child view with alert (play is blocked)
    assert_redirected_to child_path(@child_one)
    assert_match /Complete all chores scheduled for today before playing/, flash[:alert]
  end

  # Test case 5: Mix of chores - some approved, some not → play is BLOCKED
  test "play is blocked when only some of today's chores are approved" do
    sign_in @parent

    today = Date.current

    # Create two chores for this parent
    chore_a = Chore.create!(
      name: "Chore A",
      parent: @parent,
      token_amount: 5
    )
    chore_b = Chore.create!(
      name: "Chore B",
      parent: @parent,
      token_amount: 3
    )

    # Create assignments: one approved, one not
    approved_assignment = ChoreAssignment.create!(
      child: @child_one,
      chore: chore_a,
      scheduled_on: today,
      completed: true,
      approved: true
    )

    unapproved_assignment = ChoreAssignment.create!(
      child: @child_one,
      chore: chore_b,
      scheduled_on: today,
      completed: true,
      approved: false  # This one is not approved
    )

    post play_child_path(@child_one)

    # Should redirect because at least one chore is not approved
    assert_redirected_to child_path(@child_one)
    assert_match /Complete all chores scheduled for today before playing/, flash[:alert]
  end

  # Test case 6: Chores from DIFFERENT days don't affect today's play eligibility
  test "play is allowed when unapproved chores are scheduled for different days" do
    sign_in @parent

    today = Date.current
    tomorrow = today + 1.day

    # Create two chores for this parent
    chore_a = Chore.create!(
      name: "Chore A Today",
      parent: @parent,
      token_amount: 5
    )
    chore_b = Chore.create!(
      name: "Chore B Tomorrow",
      parent: @parent,
      token_amount: 3
    )

    # Today's chore is approved
    today_assignment = ChoreAssignment.create!(
      child: @child_one,
      chore: chore_a,
      scheduled_on: today,
      completed: true,
      approved: true
    )

    # Tomorrow's chore is not approved (should not block today's play)
    tomorrow_assignment = ChoreAssignment.create!(
      child: @child_one,
      chore: chore_b,
      scheduled_on: tomorrow,
      completed: false,
      approved: false
    )

    game = Game.create!(name: "Test Game 3")

    post play_child_path(@child_one)

    # Should allow play because today's chores are all approved
    assert_response :success
    assert_match /Test Game 3/, response.body
  end

  # Test case 7: Verify the bug fix - completed (without approved) no longer allows play
  test "bug fix verification: where.not(approved: true) blocks completed-but-unapproved chores" do
    sign_in @parent

    today = Date.current
    chore = Chore.create!(
      name: "Verify Bug Fix Chore",
      parent: @parent,
      token_amount: 10
    )

    # Create assignment with completed: true but approved: false
    # Under the OLD buggy code (where(completed: [false, nil])), this would allow play
    # Under the NEW fixed code (where.not(approved: true)), this should block play
    assignment = ChoreAssignment.create!(
      child: @child_one,
      chore: chore,
      scheduled_on: today,
      completed: true,   # This tricks the old buggy query
      approved: false    # But the new code checks this
    )

    post play_child_path(@child_one)

    # With the fix in place, play should be BLOCKED
    assert_redirected_to child_path(@child_one)
    assert_match /Complete all chores scheduled for today before playing/, flash[:alert]
  end

  # Test case 8: Verify token balance check still works
  test "play is blocked when child has no token balance" do
    sign_in @parent

    today = Date.current
    chore = Chore.create!(
      name: "Token Test Chore",
      parent: @parent,
      token_amount: 5
    )

    # Approve today's chore so play would be allowed
    assignment = ChoreAssignment.create!(
      child: @child_one,
      chore: chore,
      scheduled_on: today,
      completed: true,
      approved: true
    )

    # Remove all tokens from child
    @child_one.token_transactions.delete_all

    post play_child_path(@child_one)

    # Should be blocked due to no tokens
    assert_redirected_to child_path(@child_one)
    assert_match /Cannot play: child has no tokens/, flash[:alert]
  end

  # Test cross-parent isolation for show action
  test "show action: cannot access another parent's child" do
    sign_in @parent_two
    get child_path(@child_one)  # parent_two trying to access parent_one's child
    assert_response :not_found
  end

  # Test cross-parent isolation for edit action
  test "edit action: cannot access another parent's child" do
    sign_in @parent_two
    get edit_child_path(@child_one)
    assert_response :not_found
  end

  # Authentication gate tests for all ChildrenController actions

  test "unauthenticated request to index redirects to sign-in" do
    get children_url
    assert_redirected_to new_parent_session_path
  end

  test "unauthenticated request to show redirects to sign-in" do
    get child_path(@child_one)
    assert_redirected_to new_parent_session_path
  end

  test "unauthenticated request to new redirects to sign-in" do
    get new_child_url
    assert_redirected_to new_parent_session_path
  end

  test "unauthenticated request to create redirects to sign-in" do
    post children_url, params: { child: { name: "Test Child", pin_code: "1234", birthday: "2015-01-01" } }
    assert_redirected_to new_parent_session_path
  end

  test "unauthenticated request to edit redirects to sign-in" do
    get edit_child_path(@child_one)
    assert_redirected_to new_parent_session_path
  end

  test "unauthenticated request to update redirects to sign-in" do
    patch child_path(@child_one), params: { child: { name: "Updated" } }
    assert_redirected_to new_parent_session_path
  end

  test "unauthenticated request to destroy redirects to sign-in" do
    delete child_path(@child_one)
    assert_redirected_to new_parent_session_path
  end

  test "unauthenticated request to play redirects to sign-in" do
    post play_child_path(@child_one)
    assert_redirected_to new_parent_session_path
  end

  test "unauthenticated request to regenerate_public_link redirects to sign-in" do
    post regenerate_public_link_child_path(@child_one)
    assert_redirected_to new_parent_session_path
  end

  # Happy path tests for authenticated parent

  test "authenticated parent can access their own child's index" do
    sign_in @parent
    get children_url
    assert_response :success
  end

  test "authenticated parent can access their own child's show page" do
    sign_in @parent
    get child_path(@child_one)
    assert_response :success
  end

  test "authenticated parent can access their own child's edit page" do
    sign_in @parent
    get edit_child_path(@child_one)
    assert_response :success
  end

  test "authenticated parent can create a new child" do
    sign_in @parent
    assert_difference("@parent.children.count") do
      post children_url, params: { child: { name: "New Child", pin_code: "9999", birthday: "2016-06-15" } }
    end
    assert_redirected_to child_url(Child.last)
  end

  test "authenticated parent can update their own child" do
    sign_in @parent
    patch child_path(@child_one), params: { child: { name: "Updated Name" } }
    assert_redirected_to child_path(@child_one)
    @child_one.reload
    assert_equal "Updated Name", @child_one.name
  end

  test "authenticated parent can delete their own child" do
    sign_in @parent
    assert_difference("Child.count", -1) do
      delete child_path(@child_one)
    end
    assert_redirected_to children_path
  end

  test "authenticated parent can regenerate public link for their own child" do
    sign_in @parent
    post regenerate_public_link_child_path(@child_one)
    assert_redirected_to child_path(@child_one)
    assert_match /Public link generated/, flash[:notice]
  end

  # Cross-parent isolation tests for additional actions

  test "cannot delete another parent's child" do
    sign_in @parent_two
    assert_no_difference("Child.count") do
      delete child_path(@child_one)
    end
    assert_response :not_found
  end

  test "cannot update another parent's child" do
    sign_in @parent_two
    patch child_path(@child_one), params: { child: { name: "Hacked Name" } }
    assert_response :not_found
    @child_one.reload
    assert_equal "Child One", @child_one.name  # Should remain unchanged
  end

  test "cannot regenerate public link for another parent's child" do
    sign_in @parent_two
    post regenerate_public_link_child_path(@child_one)
    assert_response :not_found
  end
end
