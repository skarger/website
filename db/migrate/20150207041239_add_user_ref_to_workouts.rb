class AddUserRefToWorkouts < ActiveRecord::Migration
  def change
    add_reference :workouts, :user, index: true

    sole_user = User.first
    Workout.all.each do |w|
      w.update_attributes(user_id: sole_user.id)
    end

  end
end
