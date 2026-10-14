# frozen_string_literal: true

class PartlyKeptPalettesController < ApplicationController
  layout "palette"
  keystone_host_colors only: :show

  def index
  end

  def show
  end
end
