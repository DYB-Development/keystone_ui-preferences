# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < ActiveSupport::TestCase
  test "an app that configures no colours gets keystone_ui-colors' default accent, surface, background and text" do
    configuration = KeystoneUi::Preferences::Configuration.new

    assert_equal [ "blue", "zinc", "#ffffff", "#18181b" ], [ configuration.default_accent, configuration.default_surface, configuration.default_background, configuration.default_text ]
  end
end
