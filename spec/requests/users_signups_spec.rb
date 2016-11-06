require 'rails_helper'

include SessionsHelper

RSpec.describe "UsersSignups", :type => :request do
  describe "POST /users" do
    context "given a blank password" do
      it "should not create a new user" do
        expect{
          post users_path, params: {
            user: { email: "test@test.com",
              password: "",
              password_confirmation: ""
            }
          }
        }.to_not change{User.count}
      end

      it "should redirect to the sign up page" do
        post users_path, params: {
          user: { email: "test@test.com",
            password: "",
            password_confirmation: ""
          }
        }
        expect(response).to redirect_to('/users/new')
        expect(flash).not_to be_empty
      end
    end

    it "should create a new user if valid input given" do
      expect{
        post users_path, params: {
          user: { email: "test@test.com",
                  password: "password",
                  password_confirmation: "password"
          }
        }
      }.to change{User.count}.by(1)
      expect(response).to redirect_to(user_url(User.last.id))
      expect(flash).not_to be_empty
    end

    it "should log in the new user after successful signup" do
      post users_path, params: {
        user: { email: "test@test.com",
        password: "password",
        password_confirmation: "password" }
      }
      expect(logged_in?).to be_truthy
    end
  end
end
