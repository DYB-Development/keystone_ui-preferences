# frozen_string_literal: true

require "test_helper"
require "open3"
require "rbconfig"

class BootWithKeystoneUiColorsTest < ActiveSupport::TestCase
  test "an app that loads keystone_ui-colors stops at boot" do
    environment = File.expand_path("../dummy/config/environment", __dir__)
    boot = "module KeystoneUi; module Colors; end; end; require #{environment.dump}"

    _output, errors, _status = Open3.capture3({ "RAILS_ENV" => "test" }, RbConfig.ruby, "-e", boot)

    assert_includes errors, "KeystoneUi::Preferences::ColorsCheck::Error"
  end
end
