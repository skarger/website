require 'rails_helper'

include SessionsHelper

RSpec.describe SessionsController, :type => :controller do
  let(:valid_email) { 'cat@pets.com' }
  let(:valid_password) { 'catnip' }
  let(:invalid_email) { 'dog@pets.com' }
  let(:invalid_password) { 'milk bone' }
  let!(:user) { User.create(email: valid_email, password: valid_password) }

  describe '#create' do
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

      it 'should log in the user' do
        expect(logged_in?).to be_truthy
      end

      it 'should set the current user' do
        expect(current_user).to eq(user)
      end

      it 'should present the user page' do
        expect(response).to redirect_to(user)
      end
    end
  end

  describe '#destroy' do
    it 'should log out the user' do
      post :create, session: { email: valid_email, password: valid_password }
      delete :destroy
      expect(logged_in?).to be_falsey
    end

    it 'should clear the current_user' do
      post :create, session: { email: valid_email, password: valid_password }
      delete :destroy
      expect(current_user).to be_nil
    end
  end
end
