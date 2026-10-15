# frozen_string_literal: true

require "test_helper"

class ThemeRolesTest < ActiveSupport::TestCase
  test "the colour roles are shadcn's colour role names" do
    expected = %w[
      background foreground card card-foreground popover popover-foreground
      primary primary-foreground secondary secondary-foreground muted muted-foreground
      accent accent-foreground destructive destructive-foreground border input ring
      chart-1 chart-2 chart-3 chart-4 chart-5
      sidebar sidebar-foreground sidebar-primary sidebar-primary-foreground
      sidebar-accent sidebar-accent-foreground sidebar-border sidebar-ring
    ]

    assert_equal expected, KeystoneUi::Preferences::ThemeRoles::ROLES.select { |_name, role| role[:kind] == :colour }.keys
  end

  test "every variable a colour role sets is defined by keystone_ui-styles, light and dark" do
    css = File.read(File.join(Gem.loaded_specs.fetch("keystone_ui-styles").full_gem_path, "app/assets/tailwind/keystone_ui_styles/engine.css"))
    variables = KeystoneUi::Preferences::ThemeRoles::ROLES.values.select { |role| role[:kind] == :colour }.flat_map { |role| role[:variables] }.flat_map { |variable| [ variable, "#{variable}-dark" ] }

    assert_empty variables.reject { |variable| css.include?("#{variable}:") }
  end

  test "every variable a shape or type setting sets is defined by keystone_ui-styles, apart from Tailwind's default mono font" do
    css = File.read(File.join(Gem.loaded_specs.fetch("keystone_ui-styles").full_gem_path, "app/assets/tailwind/keystone_ui_styles/engine.css"))
    variables = KeystoneUi::Preferences::ThemeRoles::ROLES.values.reject { |role| role[:kind] == :colour }.flat_map { |role| role[:variables] } + KeystoneUi::Preferences::ThemeCss::SHADOWS

    assert_equal [ "--default-mono-font-family" ], variables.reject { |variable| css.include?("#{variable}:") }
  end

  test "every hover variable a colour role sets is defined by keystone_ui-styles, light and dark" do
    css = File.read(File.join(Gem.loaded_specs.fetch("keystone_ui-styles").full_gem_path, "app/assets/tailwind/keystone_ui_styles/engine.css"))
    variables = KeystoneUi::Preferences::ThemeCss::HOVERS.values.flat_map { |variable| [ variable, "#{variable}-dark" ] }

    assert_empty variables.reject { |variable| css.include?("#{variable}:") }
  end

  test "every theme setting sits in exactly one of the editor's groups" do
    grouped = KeystoneUi::Preferences::ThemeRoles::GROUPS.values.flat_map(&:values).flatten

    assert_equal KeystoneUi::Preferences::ThemeRoles.names.sort, grouped.sort
  end
end
