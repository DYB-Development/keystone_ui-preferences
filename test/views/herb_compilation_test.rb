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

  test "every template in the gem compiles under Herb" do
    views = KeystoneUi::Preferences::Engine.root.join("app/views")
    failures = Dir[views.join("**/*.html.erb")].filter_map do |path|
      template = Pathname(path).relative_path_from(views).to_s
      begin
        compile(template)
        nil
      rescue Herb::Engine::CompilationError, Herb::Engine::SecurityError => error
        "#{template}: #{error.message.lines.first}"
      end
    end

    assert_empty failures
  end
end
