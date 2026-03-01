require "test_helper"

class ChoreAttemptsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @parent = parents(:one)
    @parent_two = parents(:two)
    @child_one = children(:one)
    @child_two = children(:two)
    @chore_one = chores(:one)
    @assignment_one = chore_assignments(:one)
    @attempt_one = chore_attempts(:one)  # status: pending
    @attempt_two = chore_attempts(:two)  # status: approved
  end

  # Authentication gate test
  test "unauthenticated request to bulk_approve redirects to sign in" do
    post bulk_approve_chore_attempts_path, params: { attempt_ids: [@attempt_one.id] }
    assert_redirected_to new_parent_session_path
  end

  # bulk_approve happy path: approves multiple pending attempts
  test "authenticated parent can bulk approve pending attempts" do
    sign_in @parent

    # Create a second pending attempt for the same parent's child
    assignment_two = ChoreAssignment.create!(
      child: @child_one,
      chore: @chore_one,
      scheduled_on: Date.current + 1.day,
      require_photo: false
    )
    attempt_pending_two = ChoreAttempt.create!(
      chore_assignment: assignment_two,
      status: 'pending'
    )

    # Bulk approve both attempts
    assert_difference("TokenTransaction.count", 2) do
      post bulk_approve_chore_attempts_path, params: {
        attempt_ids: [@attempt_one.id, attempt_pending_two.id]
      }
    end

    assert_redirected_to admin_root_path
    assert_match "2 chore(s) approved", flash[:notice]
  end

  test "bulk_approve approves only pending attempts, skips already-approved" do
    sign_in @parent

    # Create a mix of pending and approved attempts
    assignment_pending = ChoreAssignment.create!(
      child: @child_one,
      chore: @chore_one,
      scheduled_on: Date.current + 1.day,
      require_photo: false
    )
    attempt_pending = ChoreAttempt.create!(
      chore_assignment: assignment_pending,
      status: 'pending'
    )

    # @attempt_two is already approved
    assert_equal 'approved', @attempt_two.status

    # Bulk approve both
    assert_difference("TokenTransaction.count", 1) do  # Only 1 new transaction
      post bulk_approve_chore_attempts_path, params: {
        attempt_ids: [@attempt_two.id, attempt_pending.id]
      }
    end

    assert_redirected_to admin_root_path
    assert_match "1 chore(s) approved", flash[:notice]
  end

  test "bulk_approve creates TokenTransaction for each approved attempt" do
    sign_in @parent

    assignment_two = ChoreAssignment.create!(
      child: @child_one,
      chore: @chore_one,
      scheduled_on: Date.current + 1.day,
      require_photo: false
    )
    attempt_two = ChoreAttempt.create!(
      chore_assignment: assignment_two,
      status: 'pending'
    )

    initial_transaction_count = TokenTransaction.count

    post bulk_approve_chore_attempts_path, params: {
      attempt_ids: [@attempt_one.id, attempt_two.id]
    }

    assert_equal initial_transaction_count + 2, TokenTransaction.count
  end

  test "bulk_approve updates attempt status to approved" do
    sign_in @parent

    assert_equal 'pending', @attempt_one.status

    post bulk_approve_chore_attempts_path, params: {
      attempt_ids: [@attempt_one.id]
    }

    @attempt_one.reload
    assert_equal 'approved', @attempt_one.status
  end

  test "bulk_approve updates chore_assignment approved flag" do
    sign_in @parent

    assert_not @assignment_one.approved

    post bulk_approve_chore_attempts_path, params: {
      attempt_ids: [@attempt_one.id]
    }

    @assignment_one.reload
    assert @assignment_one.approved
  end

  test "bulk_approve updates chore_assignment completed_at timestamp" do
    sign_in @parent

    post bulk_approve_chore_attempts_path, params: {
      attempt_ids: [@attempt_one.id]
    }

    @assignment_one.reload
    assert_not_nil @assignment_one.completed_at
  end

  test "bulk_approve only approves attempts belonging to current parent's children" do
    sign_in @parent

    # Create an attempt for parent_two's child using a chore that belongs to parent_two
    chore_other = Chore.create!(name: "Parent Two Chore", parent: @parent_two, token_amount: 3)
    assignment_other = ChoreAssignment.create!(
      child: @child_two,
      chore: chore_other,
      scheduled_on: Date.current + 1.day,
      require_photo: false
    )
    attempt_other = ChoreAttempt.create!(
      chore_assignment: assignment_other,
      status: 'pending'
    )

    # Try to approve parent_two's attempt as parent_one
    assert_no_difference("TokenTransaction.count") do
      post bulk_approve_chore_attempts_path, params: {
        attempt_ids: [attempt_other.id]
      }
    end

    attempt_other.reload
    assert_equal 'pending', attempt_other.status
  end

  test "bulk_approve skips attempts not found for current parent" do
    sign_in @parent

    # Attempt to approve a non-existent ID and a valid one
    assert_difference("TokenTransaction.count", 1) do
      post bulk_approve_chore_attempts_path, params: {
        attempt_ids: [99999, @attempt_one.id]
      }
    end

    assert_redirected_to admin_root_path
    assert_match "1 chore(s) approved", flash[:notice]
  end

  test "bulk_approve empty attempt_ids redirects with 0 approved" do
    sign_in @parent

    post bulk_approve_chore_attempts_path, params: {
      attempt_ids: []
    }

    assert_redirected_to admin_root_path
    assert_match "0 chore(s) approved", flash[:notice]
  end

  test "bulk_approve with no attempt_ids param redirects with 0 approved" do
    sign_in @parent

    post bulk_approve_chore_attempts_path, params: {}

    assert_redirected_to admin_root_path
    assert_match "0 chore(s) approved", flash[:notice]
  end

  test "bulk_approve grants correct token amount from chore" do
    sign_in @parent

    token_amount = @chore_one.token_amount
    child = @child_one

    post bulk_approve_chore_attempts_path, params: {
      attempt_ids: [@attempt_one.id]
    }

    # Find the token transaction created
    transaction = TokenTransaction.where(
      child: child,
      description: "Chore approved: #{@chore_one.name}"
    ).last

    assert_not_nil transaction
    assert_equal token_amount, transaction.amount
  end

  test "bulk_approve uses 0 tokens if chore has no token_amount" do
    sign_in @parent

    # Create a chore with no token_amount
    chore_no_tokens = Chore.create!(
      name: "Zero Token Chore",
      parent: @parent,
      token_amount: nil
    )

    assignment = ChoreAssignment.create!(
      child: @child_one,
      chore: chore_no_tokens,
      scheduled_on: Date.current,
      require_photo: false
    )
    attempt = ChoreAttempt.create!(
      chore_assignment: assignment,
      status: 'pending'
    )

    post bulk_approve_chore_attempts_path, params: {
      attempt_ids: [attempt.id]
    }

    transaction = TokenTransaction.where(child: @child_one).last
    assert_equal 0, transaction.amount
  end

  test "bulk_approve cross-parent isolation: parent_two cannot approve parent_one's attempts" do
    sign_in @parent_two

    assert_equal 'pending', @attempt_one.status

    assert_no_difference("TokenTransaction.count") do
      post bulk_approve_chore_attempts_path, params: {
        attempt_ids: [@attempt_one.id]
      }
    end

    @attempt_one.reload
    assert_equal 'pending', @attempt_one.status
  end
end
