module CryptoHelper
  def digest(string)
    cost = Rails.env.test? ? BCrypt::Engine::MIN_COST :
                             BCrypt::Engine::cost
    BCrypt::Password.create(string, cost: cost)
  end

  def random_token
    SecureRandom.urlsafe_base64
  end

  def token_matches?(unencrypted, encrypted)
    return if encrypted.nil?
    BCrypt::Password.new(encrypted).is_password?(unencrypted)
  end
end