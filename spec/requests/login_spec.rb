require 'rails_helper'

RSpec.describe "Login", :type => :request do
  describe "GET /login" do
    it "should flash message for invalid login" do
      get login_path
      assert_template 'sessions/new'
      post login_path, session: { email: "", password: "" }
      assert_template 'sessions/new'
      expect(flash).not_to be_empty
      get root_path
      expect(flash).to be_empty
    end
  end
end
