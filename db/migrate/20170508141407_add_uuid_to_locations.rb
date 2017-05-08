class AddUuidToLocations < ActiveRecord::Migration[5.1]
  def change
    enable_extension 'uuid-ossp'
    add_column :locations, :uuid, :uuid, default: 'uuid_generate_v4()'
    add_index(:locations, :uuid, unique: true)
  end
end
