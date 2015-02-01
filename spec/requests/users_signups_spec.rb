require 'rails_helper'

include SessionsHelper

RSpec.describe "UsersSignups", :type => :request do
  describe "POST /users" do
    it "should not create a new user if given a blank password" do
      expect{
        post users_path, user: { email: "test@test.com",
                                 password: "",
                                 password_confirmation: "" }
      }.to_not change{User.count}
      assert_template 'users/new'
    end

    it "should create a new user if valid input given" do
      expect{
        post_via_redirect users_path, user: { email: "test@test.com",
                                 password: "password",
                                 password_confirmation: "password" }
      }.to change{User.count}.by(1)
      assert_template 'users/show'
      expect(flash).not_to be_empty
    end

    it "should log in the new user after successful signup" do
       post users_path, user: { email: "test@test.com",
                                 password: "password",
                                 password_confirmation: "password" }
        expect(logged_in?).to be_truthy
     end
  end
end
