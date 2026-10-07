# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class ComponentPreferencesController < ApplicationController
      def update
        return head 422 unless params[:component_key].match?(/\A\w{1,64}\z/)
        return head :forbidden unless keystone_layout_choice(params[:component_key]).members_choose?

        return head 422 if request.raw_post.bytesize > KeystoneUi::Preferences.configuration.max_value_bytes

        value = JSON.parse(request.raw_post)
        return head 422 unless value.is_a?(Hash)

        preference = ComponentPreference.find_or_initialize_by(owner: current_owner, component_key: params[:component_key])
        preference.update!(value: value)
        head :no_content
      rescue ActionDispatch::Http::Parameters::ParseError
        head 422
      end
    end
  end
end
