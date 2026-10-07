# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class ComponentPreferencesController < ApplicationController
      def update
        return head :forbidden unless keystone_layout_choice(params[:component_key]).members_choose?

        preference = ComponentPreference.find_or_initialize_by(owner: current_owner, component_key: params[:component_key])
        preference.update!(value: JSON.parse(request.raw_post))
        head :no_content
      end
    end
  end
end
