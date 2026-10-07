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

  private

  def migration
    File.read(Dir.glob("#{destination}/db/migrate/*_remove_extra_owner_index_from_keystone_ui_preferences_component_preferences.rb").first.to_s)
  end
end
