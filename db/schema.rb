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

ActiveRecord::Schema.define(version: 20161113161749) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "distance_runs", force: :cascade do |t|
    t.decimal  "distance_in_miles"
    t.string   "time"
    t.integer  "distance_workout_id"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.index ["distance_workout_id"], name: "index_distance_runs_on_distance_workout_id", using: :btree
  end

  create_table "run_intervals", force: :cascade do |t|
    t.integer  "order"
    t.integer  "distance_in_meters"
    t.string   "time"
    t.string   "rest"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "track_workout_id"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email"
    t.string   "password_digest"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "remember_digest"
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
  end

  create_table "workouts", force: :cascade do |t|
    t.datetime "when"
    t.string   "where"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "notes"
    t.string   "type"
    t.integer  "user_id"
    t.index ["user_id"], name: "index_workouts_on_user_id", using: :btree
  end

  add_foreign_key "distance_runs", "workouts", column: "distance_workout_id", on_delete: :cascade
end
