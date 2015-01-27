require 'rails_helper'

RSpec.describe SessionsController, :type => :controller do
  let(:valid_email) { 'cat@pets.com' }
  let(:valid_password) { 'catnip' }
  let(:invalid_email) { 'dog@pets.com' }
  let(:invalid_password) { 'milk bone' }
  let!(:user) { User.create(email: valid_email, password: valid_password) }

  context 'invalid credentials' do
    it 'should present the login page when given an invalid username' do
      post :create, session: { email: invalid_email, password: valid_password }
      expect(response).to render_template(:new)
      expect(flash[:danger]).to eq('Invalid email/password combination')
    end

    it 'should present the login page when given an invalid password' do
      post :create, session: { email: valid_email, password: invalid_password }
      expect(response).to render_template(:new)
      expect(flash[:danger]).to eq('Invalid email/password combination')
    end

    it 'should present the login page for a completely non-existent user' do
      post :create, session: { email: 'fake@email.com', password: '12345' }
      expect(response).to render_template(:new)
      expect(flash[:danger]).to eq('Invalid email/password combination')
    end
  end

  context 'valid credentials' do
    before(:each) do
      post :create, session: { email: valid_email, password: valid_password }
    end

    it 'should set the session' do
      expect(session[:user_id]).to eq(user.id)
    end

    it 'should present the user page' do
      expect(response).to redirect_to(user)
    end
  end
end
