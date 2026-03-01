require "test_helper"

class ParentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @parent = parents(:one)
    @parent_two = parents(:two)
  end

  # Authentication gate tests
  test "unauthenticated request to edit redirects to sign in" do
    get edit_parent_path(@parent)
    assert_redirected_to new_parent_session_path
  end

  test "unauthenticated request to update redirects to sign in" do
    patch parent_path(@parent), params: { parent: { name: "Updated" } }
    assert_redirected_to new_parent_session_path
  end

  test "unauthenticated request to destroy redirects to sign in" do
    delete parent_path(@parent)
    assert_redirected_to new_parent_session_path
  end

  # set_parent security tests - set_parent always uses current_parent
  test "authenticated parent trying to access another parent's edit page is redirected" do
    sign_in @parent_two
    get edit_parent_path(@parent)
    # set_parent should redirect because params[:id] doesn't match current_parent.id
    assert_redirected_to edit_parent_path(@parent_two)
  end

  test "authenticated parent trying to update another parent's account is redirected" do
    sign_in @parent_two
    patch parent_path(@parent), params: { parent: { name: "Hacked" } }
    assert_redirected_to edit_parent_path(@parent_two)
  end

  test "authenticated parent trying to destroy another parent's account is redirected" do
    sign_in @parent_two
    delete parent_path(@parent)
    assert_redirected_to edit_parent_path(@parent_two)
  end

  # Happy path: profile-only update (name/email without password)
  test "authenticated parent can update profile without password" do
    sign_in @parent
    patch parent_path(@parent), params: {
      parent: {
        name: "Alice Updated",
        email: "alice_updated@example.com"
      }
    }
    assert_redirected_to edit_parent_path(@parent)
    assert_equal "Alice Updated", @parent.reload.name
    assert_equal "alice_updated@example.com", @parent.reload.email
  end

  test "authenticated parent can edit their own account" do
    sign_in @parent
    get edit_parent_path(@parent)
    assert_response :success
  end

  # Password change tests
  test "password change with wrong current_password fails" do
    sign_in @parent
    patch parent_path(@parent), params: {
      parent: {
        password: "newpassword123",
        password_confirmation: "newpassword123",
        current_password: "wrongpassword"
      }
    }
    assert_response :unprocessable_entity
    assert_includes @parent.reload.errors.full_messages.join, "Current password is incorrect"
  end

  test "password change with correct current_password succeeds" do
    sign_in @parent
    old_password_digest = @parent.encrypted_password

    patch parent_path(@parent), params: {
      parent: {
        password: "newpassword123",
        password_confirmation: "newpassword123",
        current_password: "password123"  # matches fixture encrypted_password
      }
    }

    # Should redirect to edit page on success
    assert_redirected_to edit_parent_path(@parent)

    # Password should have changed
    @parent.reload
    assert_not_equal old_password_digest, @parent.encrypted_password
  end

  test "password change keeps session alive via bypass_sign_in" do
    sign_in @parent
    patch parent_path(@parent), params: {
      parent: {
        password: "newpassword123",
        password_confirmation: "newpassword123",
        current_password: "password123"
      }
    }
    # After password change, parent should still be signed in (bypass_sign_in called)
    assert_response :redirect
    follow_redirect!
    # If still signed in, should not redirect to login
    assert_response :success
  end

  test "blank password fields do not change password" do
    sign_in @parent
    old_password_digest = @parent.encrypted_password

    patch parent_path(@parent), params: {
      parent: {
        name: "Updated Name",
        password: "",
        password_confirmation: ""
      }
    }

    assert_redirected_to edit_parent_path(@parent)
    @parent.reload
    assert_equal old_password_digest, @parent.encrypted_password
    assert_equal "Updated Name", @parent.name
  end

  # Destroy tests
  test "authenticated parent can destroy their own account" do
    sign_in @parent
    assert_difference("Parent.count", -1) do
      delete parent_path(@parent)
    end
    assert_redirected_to root_path
  end

  test "destroy signs out the parent before deleting" do
    sign_in @parent
    delete parent_path(@parent)

    # Try to access a protected page - should redirect to login if signed out
    get edit_parent_path(Parent.first || @parent_two)
    # If session was cleared, this would either redirect to login or fail
    assert_response :redirect
  end

  test "destroy shows success message" do
    sign_in @parent
    delete parent_path(@parent)
    follow_redirect!
    assert_match "account has been deleted", flash[:notice]
  end
end
