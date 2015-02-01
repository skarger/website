module CryptoHelper
  def digest(string)
    cost = Rails.env.test? ? BCrypt::Engine::MIN_COST :
                             BCrypt::Engine::cost
    BCrypt::Password.create(string, cost: cost)
  end

  def token_matches?(string, token)
    BCrypt::Password.new(token) == string
  end
end