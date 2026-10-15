# frozen_string_literal: true

require "test_helper"

class GemspecTest < ActiveSupport::TestCase
  def requirement_for(name)
    Gem::Specification.load(File.expand_path("../keystone_ui-preferences.gemspec", __dir__)).dependencies.find { |dependency| dependency.name == name }.requirement
  end

  test "the gem requires a keystone_ui-styles whose dark styles leave the preview's light side light on a dark page" do
    assert_equal Gem::Requirement.new(">= 0.23.0"), requirement_for("keystone_ui-styles")
  end
end
