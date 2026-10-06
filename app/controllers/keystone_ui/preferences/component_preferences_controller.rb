# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class ComponentPreferencesController < ApplicationController
      def update
        preference = ComponentPreference.find_or_initialize_by(owner: current_owner, component_key: params[:component_key])
        preference.update!(value: JSON.parse(request.raw_post))
        head :no_content
      end
    end
  end
end
