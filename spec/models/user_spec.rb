require 'rails_helper'

RSpec.describe User, :type => :model do
  let!(:user) {User.create(email: 'test@test.com', password: 'secret')}

  it 'should not allow a User with a blank email address' do
    u = User.new()
    expect(u.valid?).to be_falsey
  end

  it 'should accept a User that has an email address and password' do
    u = User.new(email: 'test@email.com', password: 'secret')
    expect(u.valid?).to be_truthy
  end

  it 'should ensure that email address is unique' do
    v = user.dup
    expect(v.valid?).to be_falsey
  end

  it 'should store the email as lowercase' do
      u = User.create(email: 'TEST@ALLCAPS.COM', password: 'secret')
      expect(u.email).to eq('test@allcaps.com')
  end

  describe '#remember' do
    it 'should create a remember_digest' do
      expect(user.remember_digest).to be_nil
      user.remember
      expect(user.remember_digest).to_not be_nil
    end

  end

  describe '#forget' do
    it 'should clear the remember_digest' do
      user.remember
      user.forget
      expect(user.remember_digest).to be_nil
    end

    it 'should clear the remember_token' do
      user.remember
      user.forget
      expect(user.remember_token).to be_nil
    end
  end

  describe '#authenticated?' do
    it 'should match the remember token to the saved digest' do
      user.remember
      expect(user.authenticated?(user.remember_token)).
        to be_truthy
    end

    it 'should not match the remember_token to the digest after forget' do
      user.remember
      user.forget
      expect(user.authenticated?(user.remember_token)).
        to be_falsey
    end

    it 'should not match an invalid remember token' do
      user.remember
      expect(user.authenticated?('invalid')).
        to be_falsey
    end
  end
end
