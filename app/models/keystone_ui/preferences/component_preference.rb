# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class ComponentPreference < ApplicationRecord
      self.table_name = "keystone_ui_preferences_component_preferences"

      belongs_to :owner, polymorphic: true
    end
  end
end
