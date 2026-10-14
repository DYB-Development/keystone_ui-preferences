# frozen_string_literal: true

require "test_helper"
require "erb"
require "tmpdir"

class CopyKeystoneUiColorsThemePreferencesTest < ActiveSupport::TestCase
  class ThemePreference < ActiveRecord::Base
    self.table_name = "keystone_ui_colors_theme_preferences"
  end

  TEMPLATE = File.expand_path("../../lib/generators/keystone_ui/preferences/update/templates/copy_keystone_ui_colors_theme_preferences.rb.erb", __dir__)

  def person
    @person ||= User.create!(name: "Rep")
  end

  def setup
    ActiveRecord::Base.connection.create_table(:keystone_ui_colors_theme_preferences, force: true) do |t|
      t.string :accent, null: false
      t.string :surface, null: false
      t.string :template_name
      t.string :mode
      t.string :text
      t.string :look
      t.boolean :members_choose, default: true, null: false
      t.boolean :members_choose_look, default: true, null: false
      t.references :owner, polymorphic: true, null: false
      t.timestamps
    end
    ThemePreference.reset_column_information
  end

  def teardown
    ActiveRecord::Base.connection.drop_table(:keystone_ui_colors_theme_preferences, if_exists: true)
    KeystoneUi::Preferences::ComponentPreference.delete_all
  end

  def theme_preference(owner, **columns)
    ThemePreference.create!(owner_type: owner.class.name, owner_id: owner.id, accent: "blue", surface: "zinc", **columns)
  end

  def copy
    Dir.mktmpdir do |directory|
      file = File.join(directory, "copy_keystone_ui_colors_theme_preferences.rb")
      File.write(file, ERB.new(File.read(TEMPLATE)).result)
      load file
    end
    ActiveRecord::Migration.suppress_messages { CopyKeystoneUiColorsThemePreferences.new.migrate(:up) }
  end

  def saved(owner, component_key)
    KeystoneUi::Preferences::ComponentPreference.find_by(owner: owner, component_key: component_key)
  end

  test "a person's saved template is copied as their colours" do
    theme_preference(person, accent: "emerald", surface: "stone", template_name: "forest")

    copy

    assert_equal({ "template_name" => "forest" }, saved(person, "colours")&.value)
  end
end
