class User < ActiveRecord::Base
  include CryptoHelper

  has_secure_password
  attr_accessor :remember_token

  before_save { self.email = email.downcase }
  validates :email, presence: true, uniqueness: true

  def remember
    self.remember_token = random_token
    update_attribute(:remember_digest, digest(remember_token))
  end

  def forget
    self.remember_token = nil
    update_attribute(:remember_digest, nil)
  end

  def authenticated?(token)
    token_matches?(token, remember_digest)
  end
end
