# frozen_string_literal: true

require "test_helper"
require "keystone_ui/preferences/colors_check"

class ColorsCheckTest < ActiveSupport::TestCase
  test "an app with keystone_ui-colors loaded is told to remove it before running the update generator" do
    error = assert_raises(KeystoneUi::Preferences::ColorsCheck::Error) do
      KeystoneUi::Preferences::ColorsCheck.new(colors_loaded: true).call
    end

    assert_equal "keystone_ui-preferences and keystone_ui-colors both save colours, modes and looks, so the app cannot load both. " \
      "Remove keystone_ui-colors from the Gemfile and change every KeystoneUi::Colors name the app uses first, " \
      "then run bin/rails generate keystone_ui:preferences:update, so the migration copying keystone_ui-colors' saved choices is in db/migrate, " \
      "and then run bin/rails db:migrate.", error.message
  end

  test "an app without keystone_ui-colors passes the check" do
    assert_nil KeystoneUi::Preferences::ColorsCheck.new(colors_loaded: false).call
  end
end
