# frozen_string_literal: true

require "test_helper"

class PinnedStyleTagTest < ActionDispatch::IntegrationTest
  def person
    @person ||= User.create!(name: "Rep")
  end

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
end
