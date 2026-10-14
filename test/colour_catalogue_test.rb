# frozen_string_literal: true

require "test_helper"

class ColourCatalogueTest < ActiveSupport::TestCase
  test "loading keystone_ui-preferences loads the colour templates from keystone_ui-looks" do
    assert defined?(KeystoneUi::Looks::Templates)
  end
end
