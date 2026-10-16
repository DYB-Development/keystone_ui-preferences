# frozen_string_literal: true

require "test_helper"

class PresetThemesTest < ActiveSupport::TestCase
  test "every preset theme in keystone_ui-looks passes the theme check with every setting kept as written" do
    problems = KeystoneUi::Looks::Themes.all.to_h do |name, preset|
      checked = KeystoneUi::Preferences::CheckedTheme.new(preset[:theme])
      changed = preset[:theme].reject { |role, sides| checked.value["theme"][role] == sides }.keys
      [ name, [ checked.refusal&.message, *changed ].compact ]
    end

    assert_empty problems.reject { |_name, found| found.empty? }
  end

  test "every preset theme in keystone_ui-looks and the variables the theme writer writes for it are the ones the editor script's drawing test reads" do
    written = KeystoneUi::Looks::Themes.all.to_h do |name, preset|
      css = KeystoneUi::Preferences::ThemeCss.new(preset[:theme]).to_s
      [ name.to_s, { "theme" => preset[:theme], "variables" => css.scan(/^  (--[\w-]+): (.*);$/).to_h } ]
    end

    assert_equal written, JSON.parse(File.read(File.expand_path("../fixtures/drawn/presets.json", __dir__)))["presets"]
  end
end
