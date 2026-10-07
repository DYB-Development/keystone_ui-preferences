# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class ComponentPreferencesController < ApplicationController
      def update
        return head :forbidden unless keystone_layout_choice(params[:component_key]).members_choose?

        return head 422 if request.raw_post.bytesize > 10_000

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
