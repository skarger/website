require 'rails_helper'

RSpec.describe "Login", :type => :request do
  def document_root_element
    html_document.root
  end

  let(:email) {'test@test.com' }
  let(:password) {'secret'}
  let!(:user) {User.create({email: email, password: password})}

  describe "GET /login" do
    it "should present the new session form" do
      get login_path
      assert_template 'sessions/new'
    end

    it "should remain on the new session form with invalid login" do
      get login_path
      post login_path, session: { email: "", password: "" }
      assert_template 'sessions/new'
    end

    it "should flash message for invalid login" do
      get login_path
      post login_path, session: { email: "", password: "" }
      expect(flash).not_to be_empty
    end

    it "should clear flash error message when navigating to other page" do
      get login_path
      post login_path, session: { email: "", password: "" }
      get root_path
      expect(flash).to be_empty
    end

    it "should show user after valid login" do
      get login_path
      assert_template 'sessions/new'
      post login_path, session: { email: email, password: password }
      follow_redirect!
      assert_template 'users/show'
    end

    it "should show a log in link before the user logs in" do
      get root_path
      assert_select "a[href=?]", login_path, count: 1
      assert_select "a[href=?]", logout_path, count: 0
    end

    it "should show a log out link after the user logs in" do
      get login_path
      post login_path, session: { email: email, password: password }
      follow_redirect!
      assert_select "a[href=?]", login_path, count: 0
      assert_select "a[href=?]", logout_path, count: 1
    end

    it "should remember the user if checkbox checked" do
      get login_path
      post login_path, session: {
          email: email,
          password: password,
          remember_me: 1
        }
      # using string instead of symbol because
      # cookies with symbol keys always returns nil in tests
      expect(cookies['remember_token']).to_not be_nil
    end

    it "should forget the user if checkbox unchecked" do
      get login_path
      post login_path, session: {
          email: email,
          password: password,
          remember_me: 0
        }
      expect(cookies['remember_token']).to be_nil
    end
  end

  describe "DELETE /logout" do
    it "should redirect to the site root after the user logs out" do
      get login_path
      post login_path, session: { email: email, password: password }
      follow_redirect!
      delete logout_path
      follow_redirect!
      assert_template 'welcome/index'
    end

    it "should only execute full log out logic once" do
      get login_path
      post login_path, session: { email: email, password: password }
      follow_redirect!
      delete logout_path
      # Simulate a user clicking logout in a second window.
      delete logout_path
      follow_redirect!
      assert_select "a[href=?]", login_path, count: 1
      assert_select "a[href=?]", logout_path, count: 0
    end

  end
end
