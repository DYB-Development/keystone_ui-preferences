# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class ComponentPreference < ApplicationRecord
      self.table_name = "keystone_ui_preferences_component_preferences"

      belongs_to :owner, polymorphic: true

      def owned_by?(record)
        owner_type == record.class.base_class.name && owner_id == record.id
      end
    end
  end
end
