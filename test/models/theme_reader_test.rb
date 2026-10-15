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

  test "declarations whose names are not shadcn colour roles are ignored" do
    reader = read(":root {\n  --radius: 0.625rem;\n  --font-sans: Inter;\n  color: red;\n  --ring: #a1a1a1;\n}\n")

    assert_equal({ "ring" => { "light" => "#a1a1a1" } }, reader.values)
  end

  test "colour roles set by any selector or rule other than a :root block and a .dark block are ignored" do
    reader = read(<<~CSS)
      :root { --border: #e5e5e5; }
      .sidebar .dark { --primary: #000000; }
      @theme inline { --color-primary: var(--primary); }
      @media (prefers-color-scheme: dark) { :root { --ring: #ffffff; } }
      html { --muted: #f5f5f5; }
    CSS

    assert_equal({ "border" => { "light" => "#e5e5e5" } }, reader.values)
  end

  test "a :root block and a .dark block inside an @layer rule are read" do
    reader = read("@layer base {\n  :root {\n    --ring: #a1a1a1;\n  }\n  .dark {\n    --ring: #737373;\n  }\n}\n")

    assert_equal({ "ring" => { "light" => "#a1a1a1", "dark" => "#737373" } }, reader.values)
  end

  test "a paste containing url( anywhere is refused with a reason" do
    reader = read(":root { --primary: #171717; }\n.logo { background: url(https://example.com/x.png); }\n")

    assert_equal "The pasted theme contains url( or @import, so it was not saved.", reader.refusal&.message
  end

  test "a paste containing @import anywhere is refused with a reason" do
    reader = read("@import \"https://example.com/theme.css\";\n:root { --primary: #171717; }\n")

    assert_equal "The pasted theme contains url( or @import, so it was not saved.", reader.refusal&.message
  end

  test "a paste containing URL( or @IMPORT in capitals is refused with a reason" do
    refusals = [ "a { background: URL(x.png); }", "@IMPORT 'x.css';" ].map { |text| read(text).refusal&.message }

    assert_equal [ "The pasted theme contains url( or @import, so it was not saved." ] * 2, refusals
  end

  test "a paste over 20,000 characters is refused for its size before any of it is read" do
    reader = read("@import 'x.css';\n:root { --primary: #171717; }\n#{"/* padding */" * 2000}")

    assert_equal "The pasted theme is longer than 20,000 characters, so it was not saved.", reader.refusal&.message
  end
end
