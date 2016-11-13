class RenameWhereToName < ActiveRecord::Migration[5.0]
  def change
    rename_column :workouts, :where, :name
  end
end
