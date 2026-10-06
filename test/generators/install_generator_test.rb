# frozen_string_literal: true

require "test_helper"
require "rails/generators"
require "generators/keystone_ui/preferences/install/install_generator"

class KeystoneUi::Preferences::Generators::InstallGeneratorTest < ActiveSupport::TestCase
  def destination
    @destination ||= File.expand_path("../../tmp/generator_test", __dir__)
  end

  def setup
    FileUtils.mkdir_p(destination)
    Rails::Generators.invoke("keystone_ui:preferences:install", [], destination_root: destination, quiet: true)
  end

  def teardown
    FileUtils.rm_rf(destination)
  end

  test "copies a migration that creates the component preferences table" do
    assert_includes migration, "create_table :keystone_ui_preferences_component_preferences"
  end

  test "the migration gives each preference a polymorphic owner" do
    assert_includes migration, "t.references :owner, polymorphic: true, null: false"
  end

  private

  def migration
    File.read(Dir.glob("#{destination}/db/migrate/*_create_keystone_ui_preferences_component_preferences.rb").first)
  end
end
