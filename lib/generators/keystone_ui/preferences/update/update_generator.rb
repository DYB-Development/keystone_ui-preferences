# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module KeystoneUi
  module Preferences
    module Generators
      class UpdateGenerator < Rails::Generators::Base
        include ActiveRecord::Generators::Migration

        source_root File.expand_path("templates", __dir__)

        desc "Updates KeystoneUi::Preferences: copies migrations added since it was installed and the template picker and theme editor scripts when the app has none."

        def copy_remove_extra_owner_index_migration
          migration_template(
            "remove_extra_owner_index_from_keystone_ui_preferences_component_preferences.rb.erb",
            "db/migrate/remove_extra_owner_index_from_keystone_ui_preferences_component_preferences.rb"
          )
        end

        def copy_keystone_ui_colors_theme_preferences_migration
          migration_template(
            "copy_keystone_ui_colors_theme_preferences.rb.erb",
            "db/migrate/copy_keystone_ui_colors_theme_preferences.rb"
          )
        end

        def copy_template_picker_script
          copy = "app/javascript/controllers/keystone_ui/preferences/theme_settings_controller.js"
          return if File.exist?(File.join(destination_root, copy))

          create_file copy, File.read(File.expand_path("../../../../../app/javascript/keystone_ui/preferences/theme_settings_controller.js", __dir__))
        end

        def copy_theme_editor_script
          copy = "app/javascript/controllers/keystone_ui/preferences/theme_editor_controller.js"
          return if File.exist?(File.join(destination_root, copy))

          create_file copy, File.read(File.expand_path("../../../../../app/javascript/keystone_ui/preferences/theme_editor_controller.js", __dir__))
        end

        def copy_appearance_editor_script
          copy = "app/javascript/controllers/keystone_ui/preferences/appearance_editor_controller.js"
          return if File.exist?(File.join(destination_root, copy))

          create_file copy, File.read(File.expand_path("../../../../../app/javascript/keystone_ui/preferences/appearance_editor_controller.js", __dir__))
        end
      end
    end
  end
end
