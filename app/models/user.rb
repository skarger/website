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
    update_attribute(:remember_digest, nil)
    self.remember_token = nil
  end

  def authenticated?(remember_token)
    token_matches?(remember_token, remember_digest)
  end
end
