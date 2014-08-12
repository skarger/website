class WorkoutAugust9 < ActiveRecord::Migration
  def change
    reversible do |m|
      m.up do
        w = Workout.new({ :when => DateTime.new(2014, 8, 9, 16, 0, 0, '-4'),
                          :where => 'MIT Track'})
        w.save
        w.exercises.create(name: 'Track Workout', category: :cardio)
      end

      m.down do
        Workout.where(when: DateTime.new(2014, 8, 9, 16, 0, 0, '-4')).destroy_all
      end
    end
  end
end
