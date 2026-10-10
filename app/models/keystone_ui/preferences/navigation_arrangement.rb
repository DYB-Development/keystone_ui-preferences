# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class NavigationArrangement
      def initialize(arranged)
        @arranged = arranged
      end

      def group_moved(index, step)
        moved(order, index, step)
      end

      def order
        @arranged.map { |group, tabs| { "group" => group.label, "tabs" => tabs.map { |tab| tab.key.to_s } } }
      end

      private

      def moved(items, index, step)
        items.insert(index + step, items.delete_at(index))
      end
    end
  end
end
