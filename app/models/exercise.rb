class Exercise < ActiveRecord::Base
  belongs_to :workout

  enum category: [:uncategorized, :strength, :cardio, :physical_therapy]
end
