# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module KeystoneUi
  module Preferences
    module Generators
      class InstallGenerator < Rails::Generators::Base
        include ActiveRecord::Generators::Migration

        source_root File.expand_path("templates", __dir__)

        desc "Installs KeystoneUi::Preferences: copies its migration."

        def copy_migration
          migration_template(
            "create_keystone_ui_preferences_component_preferences.rb.erb",
            "db/migrate/create_keystone_ui_preferences_component_preferences.rb"
          )
        end
      end
    end
  end
end
