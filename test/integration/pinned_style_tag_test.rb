# frozen_string_literal: true

require "test_helper"

class PinnedStyleTagTest < ActionDispatch::IntegrationTest
  def person
    @person ||= User.create!(name: "Rep")
  end

  THEME = {
    "background" => { "light" => "#ffffff" },
    "foreground" => { "light" => "oklch(0.145 0 0)", "dark" => "oklch(0.985 0 0)" },
    "primary" => { "light" => "#1d4ed8", "dark" => "#60a5fa" },
    "secondary" => { "light" => "hsl(210 40% 96%)", "dark" => "hsl(217 33% 17%)" },
    "destructive" => { "light" => "rgb(220, 38, 38)", "dark" => "rgb(127, 29, 29)" },
    "sidebar-ring" => { "light" => "#111111" },
    "radius" => { "light" => "0.5rem" },
    "spacing" => { "light" => "0.25rem" },
    "letter-spacing" => { "light" => "-0.01em" },
    "font-sans" => { "light" => "Inter, system-ui, sans-serif" },
    "font-mono" => { "light" => "ui-monospace, Menlo" },
    "font-weight-heading" => { "light" => "700" },
    "shadow-color" => { "light" => "#000000" },
    "shadow-opacity" => { "light" => "0.1" },
    "shadow-blur" => { "light" => "3px" },
    "shadow-spread" => { "light" => "0px" },
    "shadow-offset-x" => { "light" => "0px" },
    "shadow-offset-y" => { "light" => "1px" }
  }.freeze

  def setup
    ApplicationController.signed_in_user = person
  end

  def teardown
    ApplicationController.signed_in_user = nil
    KeystoneUi::Preferences::ComponentPreference.delete_all
  end

  def save_colours(value)
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: value)
  end

  def pinned(name)
    File.read(File.expand_path("../fixtures/pinned/#{name}.css", __dir__))
  end

  def style_tag
    get "/palette"
    css_select("head style").text
  end

  test "a saved template writes the same style tag as before the writers were joined" do
    save_colours({ "template_name" => "forest" })

    assert_equal pinned("template_forest"), style_tag
  end

  test "saved custom colours write the same style tag as before the writers were joined" do
    save_colours({ "accent" => "#e11d48", "surface" => "stone", "text" => "#1c1917" })

    assert_equal pinned("custom_colours"), style_tag
  end

  test "a saved preset writes the same style tag as before the writers were joined" do
    save_colours({ "preset_name" => "harbor" })

    assert_equal pinned("preset_harbor"), style_tag
  end

  test "a saved preset writes the same style tag as before the writers were joined for a person who saved a look of their own" do
    save_colours({ "preset_name" => "harbor" })
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "look", value: { "look" => "rounded" })

    assert_equal pinned("preset_harbor_own_look"), style_tag
  end

  test "a saved theme writes the same style tag as before the writers were joined" do
    save_colours({ "theme" => THEME })

    assert_equal pinned("theme"), style_tag
  end
end
