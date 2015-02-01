require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the CryptoHelper. For example:
#
# describe SessionsHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe SessionsHelper, :type => :helper do
  describe '#digest' do
    let(:input_string) { 'a string' }
    let(:test_cost) { BCrypt::Engine::MIN_COST }
    let(:production_cost) { BCrypt::Engine.cost }

    it 'should use the min cost in test mode' do
      expect(helper.digest(input_string).cost).to eq(test_cost)
    end

    it 'should use the regular cost when not in test mode' do
      allow(Rails.env).
        to receive(:test?).and_return(false)
      expect(helper.digest(input_string).cost).to eq(production_cost)
    end

    describe '#token_matches?'
    it 'should return true when given the correct token' do
      encrypted_token = helper.digest(input_string)
      expect(helper.token_matches?(encrypted_token, input_string)).
        to be_truthy
    end

    it 'should return false when given an invalid token' do
      encrypted_token = helper.digest(input_string)
      expect(helper.token_matches?(encrypted_token, 'wrong value')).
        to be_falsey
    end
  end
end