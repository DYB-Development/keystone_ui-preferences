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
end
