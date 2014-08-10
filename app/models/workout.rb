class Workout < ActiveRecord::Base
#  attr_accessible :when, :where

  has_many :exercises
end
