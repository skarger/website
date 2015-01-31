require 'rails_helper'

RSpec.describe "Login", :type => :request do
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
      user = User.create({email: 'test@test.com', password: 'secret'})
      get login_path
      assert_template 'sessions/new'
      post login_path, session: { email: 'test@test.com', password: 'secret' }
      follow_redirect!
      assert_template 'users/show'
    end
  end
end
