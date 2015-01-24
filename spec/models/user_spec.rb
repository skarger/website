require 'rails_helper'

RSpec.describe User, :type => :model do
  it 'should not allow a User with a blank email address' do
    u = User.new()
    expect(u.valid?).to be_falsey
  end

  it 'should accept a User that has an email address' do
    u = User.new(email: 'test@test.com', password: 'secret')
    expect(u.valid?).to be_truthy
  end

  it 'should ensure that email address is unique' do
    u = User.new(email: 'test@test.com', password: 'secret')
    u.save
    v = u.dup
    expect(v.valid?).to be_falsey
  end

  it 'should store the email as lowercase' do
      u = User.create(email: 'TEST@ALLCAPS.COM', password: 'secret')
      expect(u.email).to eq('test@allcaps.com')
  end
end
