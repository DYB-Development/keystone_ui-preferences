# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require_relative "dummy/config/environment"
require "rails/test_help"

ActiveRecord::Schema.define do
  create_table :keystone_ui_preferences_component_preferences, force: true do |t|
    t.references :owner, polymorphic: true, null: false
    t.string :component_key, null: false
    t.json :value, null: false, default: {}
    t.boolean :members_choose, default: true, null: false
    t.timestamps
  end

  create_table :users, force: true do |t|
    t.string :name
  end

  create_table :accounts, force: true do |t|
    t.string :name
  end
end

Rails.application.config.action_dispatch.show_exceptions = :none
