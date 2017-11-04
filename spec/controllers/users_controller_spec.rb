require 'rails_helper'

RSpec.describe UsersController, :type => :controller do
  context "production" do
    before :each do
      allow(Rails.env).to receive(:production?).and_return(true)
    end

    it 'should block the user new endpoint' do
      get :new
      expect(response.status).to eq(404)
    end

    it 'should block the user create endpoint' do
      expect{post :create}.to_not change{User.count}
      expect(response.status).to eq(404)
    end

    it 'should show a user' do
      u = User.new(name: "Test User")
      allow(User).to receive(:find).and_return(u)
      get :show, params: { id: 1 }
      expect(response.status).to eq(200)
    end
  end
end
