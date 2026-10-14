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

  def account
    @account ||= Account.create!(name: "Acme")
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

  test "a person's custom colours are copied as their accent, surface and text" do
    theme_preference(person, accent: "#1d4ed8", surface: "slate", text: "#111111")

    copy

    assert_equal({ "accent" => "#1d4ed8", "surface" => "slate", "text" => "#111111" }, saved(person, "colours")&.value)
  end

  test "a person's saved mode is copied as their mode" do
    theme_preference(person, mode: "dark")

    copy

    assert_equal({ "mode" => "dark" }, saved(person, "mode")&.value)
  end

  test "an owner with no saved mode gets no mode" do
    theme_preference(person)

    copy

    assert_nil saved(person, "mode")
  end

  test "a person's saved look is copied as their look" do
    theme_preference(person, look: "rounded")

    copy

    assert_equal({ "look" => "rounded" }, saved(person, "look")&.value)
  end

  test "an account that sets the colours for everyone keeps setting them" do
    theme_preference(account, members_choose: false)

    copy

    assert_equal false, saved(account, "colours")&.members_choose
  end

  test "an account that sets the look for everyone keeps setting it" do
    theme_preference(account, look: "rounded", members_choose_look: false)

    copy

    assert_equal false, saved(account, "look")&.members_choose
  end

  test "an account on the app's own look that sets the look for everyone keeps setting it" do
    theme_preference(account, members_choose_look: false)

    copy

    assert_equal [ {}, false ], [ saved(account, "look")&.value, saved(account, "look")&.members_choose ]
  end

  test "a saved template named Default is copied as the app's default colours" do
    theme_preference(account, template_name: "default")

    copy

    assert_equal({ "template_name" => "default" }, saved(account, "colours")&.value)
  end

  test "an owner that already chose colours in keystone_ui-preferences keeps them" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "template_name" => "ocean" })
    theme_preference(person, template_name: "forest")

    copy

    assert_equal [ { "template_name" => "ocean" } ], KeystoneUi::Preferences::ComponentPreference.where(owner: person, component_key: "colours").map(&:value)
  end

  test "running the copy a second time changes nothing" do
    theme_preference(person, template_name: "forest", mode: "dark", look: "rounded")
    copy
    first = KeystoneUi::Preferences::ComponentPreference.order(:id).map(&:attributes)

    copy

    assert_equal first, KeystoneUi::Preferences::ComponentPreference.order(:id).map(&:attributes)
  end
end
