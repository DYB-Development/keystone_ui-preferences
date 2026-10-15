# frozen_string_literal: true

require "test_helper"

class ThemeRolesTest < ActiveSupport::TestCase
  test "the theme roles are shadcn's colour role names" do
    expected = %w[
      background foreground card card-foreground popover popover-foreground
      primary primary-foreground secondary secondary-foreground muted muted-foreground
      accent accent-foreground destructive destructive-foreground border input ring
      chart-1 chart-2 chart-3 chart-4 chart-5
      sidebar sidebar-foreground sidebar-primary sidebar-primary-foreground
      sidebar-accent sidebar-accent-foreground sidebar-border sidebar-ring
    ]

    assert_equal expected, KeystoneUi::Preferences::ThemeRoles.names
  end
end
