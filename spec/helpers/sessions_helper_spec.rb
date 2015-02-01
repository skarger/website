require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the SessionsHelper. For example:
#
# describe SessionsHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe SessionsHelper, :type => :helper do
  let!(:user) {User.create(email: 'test@test.com', password: 'secret')}
  describe '#remember' do
    it 'should cause the user to have a remember_digest' do
      expect{ helper.remember(user) }.to change{user.remember_digest}
    end

    it 'should set cookies.permanent.signed[:user_id]' do
      cookies.permanent.signed[:user_id] = nil
      helper.remember(user)
      expect(cookies.permanent.signed[:user_id]).to eq(user.id)
    end

    it 'should set cookies.permanent[:remember_token]' do
      cookies.permanent[:remember_token] = nil
      helper.remember(user)
      expect(cookies.permanent[:remember_token]).to eq(user.remember_token)
    end
  end

  describe '#forget' do
    it 'should clear out the signed user_id cookie' do
      helper.remember(user)
      helper.forget(user)
      expect(cookies.signed[:user_id]).to be_nil
    end

    it 'should clear out the remember_token cookie' do
      helper.remember(user)
      helper.forget(user)
      expect(cookies[:remember_token]).to be_nil
    end
  end
end
