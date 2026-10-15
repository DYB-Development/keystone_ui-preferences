# frozen_string_literal: true

require "test_helper"

class ColourChoicesPartialTest < ActionView::TestCase
  include KeystoneUiHelper

  test "the paste box holds the theme the person pasted, markup and all, when the section is given it" do
    pasted = ":root {\n  --primary: </textarea><b>bold</b>;\n}\n"

    render partial: "keystone_ui/preferences/settings/colour_choices", locals: { saved: { "template_name" => "default" }, drawn: KeystoneUi::Preferences::AppearanceChoice.new(person: nil, account: nil).colours, pastes: true, sent_paste: pasted }

    assert_equal pasted, css_select("textarea[name=pasted_theme]").first.text.delete_prefix("\n")
  end
end
