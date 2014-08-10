class Exercise < ActiveRecord::Base
  #attr_accessible :name, :category

  belongs_to :workout

  enum category: [:uncategorized, :strength, :cardio, :physical_therapy]
end
