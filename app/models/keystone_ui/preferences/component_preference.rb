# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class ComponentPreference < ApplicationRecord
      self.table_name = "keystone_ui_preferences_component_preferences"

      belongs_to :owner, polymorphic: true

      after_commit { Rails.cache.delete(self.class.cache_key_for(owner_type, owner_id, component_key)) }

      def self.cache_key_for(owner_type, owner_id, component_key)
        [ "keystone_ui_preferences", owner_type, owner_id, component_key ].join("/")
      end

      def owned_by?(record)
        owner_type == record.class.base_class.name && owner_id == record.id
      end
    end
  end
end
