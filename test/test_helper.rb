# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require_relative "dummy/config/environment"
require "rails/test_help"

ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name
  end
end

Rails.application.config.action_dispatch.show_exceptions = :none
