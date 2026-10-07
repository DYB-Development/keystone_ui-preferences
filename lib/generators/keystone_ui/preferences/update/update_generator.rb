# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module KeystoneUi
  module Preferences
    module Generators
      class UpdateGenerator < Rails::Generators::Base
        include ActiveRecord::Generators::Migration

        source_root File.expand_path("templates", __dir__)

        desc "Updates KeystoneUi::Preferences: copies migrations added since it was installed."

        def copy_remove_extra_owner_index_migration
          migration_template(
            "remove_extra_owner_index_from_keystone_ui_preferences_component_preferences.rb.erb",
            "db/migrate/remove_extra_owner_index_from_keystone_ui_preferences_component_preferences.rb"
          )
        end
      end
    end
  end
end
