class WorkoutAugust9V2 < ActiveRecord::Migration
  def change
    reversible do |m|
      m.up do
        w = Workout.where(when: DateTime.new(2014, 8, 9, 16, 0, 0, '-4')).first
        w.type = 'SpeedWorkout'
        w.save

        sw = SpeedWorkout.find(w.id)

        sw.run_intervals.create({ :order => 1, :distance_in_meters => 200,
          :time => '34 seconds', :rest => '2 minutes' })
        sw.run_intervals.create({ :order => 2, :distance_in_meters => 400,
          :time => '70 seconds', :rest => '3 minutes' })
        sw.run_intervals.create({ :order => 3, :distance_in_meters => 200,
          :time => '34 seconds', :rest => '2 minutes 30 seconds' })
        sw.run_intervals.create({ :order => 4, :distance_in_meters => 400,
          :time => '72 seconds'})
      end

      m.down do
        w = Workout.where(when: DateTime.new(2014, 8, 9, 16, 0, 0, '-4')).first
        w.run_intervals.destroy_all
        w.type = nil
        w.save
      end
    end
  end
end
