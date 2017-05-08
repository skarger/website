class Location < ApplicationRecord
  validates :uuid, uniqueness: true
end
