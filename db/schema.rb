# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170508141407) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"
  enable_extension "uuid-ossp"

  create_table "distance_runs", id: :serial, force: :cascade do |t|
    t.decimal "distance_in_miles"
    t.string "time"
    t.integer "distance_workout_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["distance_workout_id"], name: "index_distance_runs_on_distance_workout_id"
  end

  create_table "locations", force: :cascade do |t|
    t.text "name"
    t.geography "point", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "uuid", default: -> { "uuid_generate_v4()" }
    t.index ["point"], name: "index_locations_on_point"
    t.index ["uuid"], name: "index_locations_on_uuid", unique: true
  end

  create_table "track_intervals", id: :serial, force: :cascade do |t|
    t.integer "order"
    t.integer "distance_in_meters"
    t.interval "time"
    t.interval "rest"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "track_workout_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.string "remember_digest"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "workouts", id: :serial, force: :cascade do |t|
    t.datetime "when"
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "notes"
    t.string "type"
    t.integer "user_id"
    t.index ["user_id"], name: "index_workouts_on_user_id"
  end

  add_foreign_key "distance_runs", "workouts", column: "distance_workout_id", on_delete: :cascade
end
