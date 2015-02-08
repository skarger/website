# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20150207041239) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "run_intervals", force: true do |t|
    t.integer  "order"
    t.integer  "distance_in_meters"
    t.string   "time",               limit: nil
    t.string   "rest",               limit: nil
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "speed_workout_id"
  end

  create_table "users", force: true do |t|
    t.string   "email"
    t.string   "password_digest"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "remember_digest"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree

  create_table "workouts", force: true do |t|
    t.datetime "when"
    t.string   "where"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "notes"
    t.string   "type"
    t.integer  "user_id"
  end

  add_index "workouts", ["user_id"], name: "index_workouts_on_user_id", using: :btree

end
