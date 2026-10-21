# frozen_string_literal: true

require "test_helper"
require "herb"
require "herb/engine"
require "herb/engine/validators/security_validator"

class HerbCompilationTest < ActiveSupport::TestCase
  def compile(template)
    source = KeystoneUi::Preferences::Engine.root.join("app/views", template).read
    Herb::Engine.new(source, validate_ruby: true, visitors: [ Herb::Engine::Validators::SecurityValidator.new ])
  end

  test "the theme settings template compiles under Herb" do
    assert_nothing_raised { compile("keystone_ui/preferences/settings/_theme_settings.html.erb") }
  end
end
