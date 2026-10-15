# frozen_string_literal: true

require "test_helper"

class ThemeReaderTest < ActiveSupport::TestCase
  def read(text)
    KeystoneUi::Preferences::ThemeReader.new(text)
  end

  test "a :root block and a .dark block are read into a light and a dark value for each role" do
    reader = read(":root {\n  --primary: oklch(0.205 0 0);\n  --border: #e5e5e5;\n}\n.dark {\n  --primary: oklch(0.922 0 0);\n}\n")

    assert_equal({ "primary" => { "light" => "oklch(0.205 0 0)", "dark" => "oklch(0.922 0 0)" }, "border" => { "light" => "#e5e5e5" } }, reader.values)
  end
end
