class CreateLocations < ActiveRecord::Migration[5.1]
  def change
    create_table :locations do |t|
      t.text :name
      t.st_point :point, geographic: true, index: :gist
      t.timestamps
    end
  end
end
