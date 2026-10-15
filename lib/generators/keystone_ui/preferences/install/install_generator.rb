# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module KeystoneUi
  module Preferences
    module Generators
      class InstallGenerator < Rails::Generators::Base
        include ActiveRecord::Generators::Migration

        source_root File.expand_path("templates", __dir__)

        desc "Installs KeystoneUi::Preferences: copies its migration, its template picker script and its theme editor script."

        def copy_migration
          migration_template(
            "create_keystone_ui_preferences_component_preferences.rb.erb",
            "db/migrate/create_keystone_ui_preferences_component_preferences.rb"
          )
        end

        def copy_template_picker_script
          script = File.expand_path("../../../../../app/javascript/keystone_ui/preferences/theme_settings_controller.js", __dir__)
          create_file "app/javascript/controllers/keystone_ui/preferences/theme_settings_controller.js", File.read(script)
        end

        def copy_theme_editor_script
          script = File.expand_path("../../../../../app/javascript/keystone_ui/preferences/theme_editor_controller.js", __dir__)
          create_file "app/javascript/controllers/keystone_ui/preferences/theme_editor_controller.js", File.read(script)
        end

        def copy_appearance_editor_script
          script = File.expand_path("../../../../../app/javascript/keystone_ui/preferences/appearance_editor_controller.js", __dir__)
          create_file "app/javascript/controllers/keystone_ui/preferences/appearance_editor_controller.js", File.read(script)
        end
      end
    end
  end
end
