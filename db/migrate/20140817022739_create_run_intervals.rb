class CreateRunIntervals < ActiveRecord::Migration
  def change
    create_table :run_intervals do |t|
      t.belongs_to :exercise
      t.integer :order
      t.integer :distance_in_meters
      t.column :time, :interval
      t.column :rest, :interval

      t.timestamps
    end
  end
end
