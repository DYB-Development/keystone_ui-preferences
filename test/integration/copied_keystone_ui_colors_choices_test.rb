# frozen_string_literal: true

require "test_helper"
require "rails/generators"
require "generators/keystone_ui/preferences/update/update_generator"

class CopiedKeystoneUiColorsChoicesTest < ActionDispatch::IntegrationTest
  def person
    @person ||= User.create!(name: "Rep")
  end

  def destination
    @destination ||= File.expand_path("../../tmp/copied_keystone_ui_colors_choices_test", __dir__)
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
    FileUtils.mkdir_p(destination)
  end

  def teardown
    ApplicationController.signed_in_user = nil
    ActiveRecord::Base.connection.drop_table(:keystone_ui_colors_theme_preferences, if_exists: true)
    KeystoneUi::Preferences::ComponentPreference.delete_all
    FileUtils.rm_rf(destination)
  end

  def run_copied_migration
    Rails::Generators.invoke("keystone_ui:preferences:update", [], destination_root: destination, quiet: true)
    load Dir.glob("#{destination}/db/migrate/*_copy_keystone_ui_colors_theme_preferences.rb").first
    ActiveRecord::Migration.suppress_messages { CopyKeystoneUiColorsThemePreferences.new.migrate(:up) }
  end

  test "a person sees the colours, mode and look they saved in keystone_ui-colors once the copied migration runs" do
    ActiveRecord::Base.connection.execute(<<~SQL)
      INSERT INTO keystone_ui_colors_theme_preferences (owner_type, owner_id, accent, surface, template_name, mode, look, created_at, updated_at)
      VALUES ('User', #{person.id}, 'emerald', 'stone', 'forest', 'dark', 'rounded', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    SQL
    run_copied_migration
    ApplicationController.signed_in_user = person

    get "/palette"

    assert_equal [ "--color-accent-500: #10b981;", "dark", "rounded" ], [ css_select("head style").text.lines.map(&:strip).grep(/accent-500:/).first, css_select("html").first["data-theme"], css_select("html").first["data-look"] ]
  end
end
