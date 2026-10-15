# frozen_string_literal: true

require "test_helper"
require "rails/generators"
require "generators/keystone_ui/preferences/update/update_generator"

class KeystoneUi::Preferences::Generators::UpdateGeneratorTest < ActiveSupport::TestCase
  def destination
    @destination ||= File.expand_path("../../tmp/update_generator_test", __dir__)
  end

  def setup
    FileUtils.mkdir_p(destination)
    Rails::Generators.invoke("keystone_ui:preferences:update", [], destination_root: destination, quiet: true)
  end

  def teardown
    FileUtils.rm_rf(destination)
  end

  test "copies a migration that drops the owner index the owner and component key index already covers" do
    assert_includes migration, %(remove_index :keystone_ui_preferences_component_preferences, %i[owner_type owner_id], name: "index_keystone_ui_preferences_component_preferences_on_owner", if_exists: true)
  end

  test "leaves an app's own edited copy of the template picker script as it is" do
    script = "#{destination}/app/javascript/controllers/keystone_ui/preferences/theme_settings_controller.js"
    File.write(script, "// edited by the app")

    Rails::Generators.invoke("keystone_ui:preferences:update", [], destination_root: destination, quiet: true)

    assert_equal "// edited by the app", File.read(script)
  end

  test "copies a migration that copies keystone_ui-colors' saved colours, mode and look" do
    assert_includes File.read(Dir.glob("#{destination}/db/migrate/*_copy_keystone_ui_colors_theme_preferences.rb").first.to_s), "class CopyKeystoneUiColorsThemePreferences"
  end

  test "leaves an app's own edited copy of the theme editor script as it is" do
    script = "#{destination}/app/javascript/controllers/keystone_ui/preferences/theme_editor_controller.js"
    File.write(script, "// edited by the app")

    Rails::Generators.invoke("keystone_ui:preferences:update", [], destination_root: destination, quiet: true)

    assert_equal "// edited by the app", File.read(script)
  end

  test "copies the appearance editor script into the app's Stimulus controllers" do
    assert_equal File.read(File.expand_path("../../app/javascript/keystone_ui/preferences/appearance_editor_controller.js", __dir__)), File.read("#{destination}/app/javascript/controllers/keystone_ui/preferences/appearance_editor_controller.js")
  end

  test "leaves an app's own edited copy of the appearance editor script as it is" do
    script = "#{destination}/app/javascript/controllers/keystone_ui/preferences/appearance_editor_controller.js"
    File.write(script, "// edited by the app")

    Rails::Generators.invoke("keystone_ui:preferences:update", [], destination_root: destination, quiet: true)

    assert_equal "// edited by the app", File.read(script)
  end

  test "copies one script for the Appearance sections and no other into an app that has none" do
    assert_equal [ "appearance_editor_controller.js" ], Dir.children("#{destination}/app/javascript/controllers/keystone_ui/preferences")
  end

  private

  def migration
    File.read(Dir.glob("#{destination}/db/migrate/*_remove_extra_owner_index_from_keystone_ui_preferences_component_preferences.rb").first.to_s)
  end
end
