require "test_helper"

module Admin
  class DashboardControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @parent = parents(:one)
      @parent_two = parents(:two)
      @child_one = children(:one)
      @child_two = children(:two)
      @chore_one = chores(:one)
      @assignment_one = chore_assignments(:one)
      @attempt_one = chore_attempts(:one)
    end

    # Authentication gate test
    test "unauthenticated request to dashboard redirects to sign in" do
      get admin_root_path
      assert_redirected_to new_parent_session_path
    end

    # Happy path: authenticated parent can access dashboard
    test "authenticated parent can access dashboard" do
      sign_in @parent
      get admin_root_path
      assert_response :success
    end

    # Dashboard loads all required instance variables
    test "dashboard loads @children with includes" do
      sign_in @parent
      get admin_root_path
      assert_response :success
      assert_not_nil assigns(:children)
      # Should only have current parent's children
      assigned_children = assigns(:children)
      assert_includes assigned_children, @child_one
      # @child_two belongs to @parent_two, should not be included
      assert_not_includes assigned_children, @child_two
    end

    test "dashboard loads @pending_attempts" do
      sign_in @parent
      get admin_root_path
      assert_response :success
      assert_not_nil assigns(:pending_attempts)
      assert_kind_of ActiveRecord::Relation, assigns(:pending_attempts)
    end

    test "dashboard loads @todays_by_child" do
      sign_in @parent
      get admin_root_path
      assert_response :success
      assert_not_nil assigns(:todays_by_child)
      assert_kind_of Hash, assigns(:todays_by_child)
    end

    test "dashboard loads @overdue_by_child" do
      sign_in @parent
      get admin_root_path
      assert_response :success
      assert_not_nil assigns(:overdue_by_child)
      assert_kind_of Hash, assigns(:overdue_by_child)
    end

    test "dashboard loads @approved_attempts" do
      sign_in @parent
      get admin_root_path
      assert_response :success
      assert_not_nil assigns(:approved_attempts)
      assert_kind_of ActiveRecord::Relation, assigns(:approved_attempts)
    end

    # Data isolation: dashboard only loads current parent's data
    test "dashboard only shows current parent's children" do
      sign_in @parent
      get admin_root_path
      assert_response :success
      children = assigns(:children)
      assert_includes children.map(&:id), @child_one.id
      assert_not_includes children.map(&:id), @child_two.id
    end

    test "dashboard only shows pending attempts for current parent's children" do
      sign_in @parent
      get admin_root_path
      assert_response :success
      pending = assigns(:pending_attempts)
      # All pending attempts should belong to current parent's children
      pending.each do |attempt|
        assert_includes @parent.children.map(&:id), attempt.child.id
      end
    end

    test "dashboard only shows overdue assignments for current parent's children" do
      sign_in @parent
      get admin_root_path
      assert_response :success
      overdue_by_child = assigns(:overdue_by_child)
      # All overdue assignments should belong to current parent's children
      overdue_by_child.each_key do |child_id|
        assert_includes @parent.children.map(&:id), child_id
      end
    end

    test "dashboard only shows approved attempts for current parent's children" do
      sign_in @parent
      get admin_root_path
      assert_response :success
      approved = assigns(:approved_attempts)
      # All approved attempts should belong to current parent's children
      approved.each do |attempt|
        assert_includes @parent.children.map(&:id), attempt.child.id
      end
    end

    # Cross-parent isolation test
    test "parent_two cannot see parent_one's children data on dashboard" do
      sign_in @parent_two
      get admin_root_path
      assert_response :success
      children = assigns(:children)
      assert_not_includes children.map(&:id), @child_one.id
      assert_includes children.map(&:id), @child_two.id
    end
  end
end
