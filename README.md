# keystone_ui-preferences

Per-user saved choices for Keystone UI components, such as a data table's hidden columns and the colours every page is drawn in.

A page gives a `ui_data_table` a `key:`. This gem saves each signed-in person's layout for that key and hands it back to keystone_ui, so the table renders from it and shows a Columns menu that saves to it. A person with nothing saved sees the hidden columns the table's own call names.

## Installation

Add the gem and run its install generator, which copies a migration for its table and the template picker script the appearance section uses:

```ruby
gem "keystone_ui-preferences"
```

```bash
bundle install
bin/rails generate keystone_ui:preferences:install
bin/rails db:migrate
```

The script lands at `app/javascript/controllers/keystone_ui/preferences/theme_settings_controller.js`. Register it in `app/javascript/controllers/index.js`:

```js
import ThemeSettingsController from "./keystone_ui/preferences/theme_settings_controller"
application.register("keystone-ui--preferences--theme-settings", ThemeSettingsController)
```

After updating the gem, run its update generator to copy any migrations added since it was installed, and the template picker script when the app does not have it yet:

```bash
bin/rails generate keystone_ui:preferences:update
bin/rails db:migrate
```

Mount the engine in `config/routes.rb`. A table's Columns menu saves to it:

```ruby
mount KeystoneUi::Preferences::Engine => "/keystone_ui_preferences"
```

Include the concern in `ApplicationController`. It gives views the lookup keystone_ui calls for a table's key:

```ruby
class ApplicationController < ActionController::Base
  include KeystoneUi::Preferences::ComponentPreferences
end
```

## Configuration

The gem asks the host for the signed-in person and for its sign-in check. Both default to Devise's names:

```ruby
KeystoneUi::Preferences.configure do |config|
  config.current_owner_method = :current_user        # returns the person a value is saved for
  config.authentication_method = :authenticate_user! # runs before every save
  config.current_account_method = :current_account   # returns the account; nil (the default) skips the account level
  config.max_value_bytes = 10_000                    # the largest saved value accepted, in bytes
  config.default_accent = "blue"                     # the accent for a person with no colours saved
  config.default_surface = "zinc"                    # the surface for a person with no colours saved
  config.default_background = "#ffffff"              # the custom background for a person with no colours saved
  config.default_text = "#18181b"                    # the custom text colour for a person with no colours saved
end
```

The save address refuses, with a 422 and nothing saved, a body that is not a JSON object, a body larger than `max_value_bytes`, and a component key that is not 1 to 64 letters, digits and underscores.

## Using it

Give a table a key, and the hidden columns it shows a person with nothing saved:

```erb
<%= ui_data_table(
  items: @months,
  columns: [
    Keystone::Ui::Column.new(:month, "Month"),
    Keystone::Ui::Column.new(:pipeline, "Pipeline", hideable: true)
  ],
  key: :revenue_projection_months,
  hidden_columns: [ :pipeline ]
) %>
```

A signed-in person sees a Columns menu above the table. Their changes save `{ "hidden_columns": [...], "column_order": [...] }` for that person and key when the menu closes, replacing what they saved before, and reload the page. Another person viewing the same table sees only their own saved layout. With nobody signed in, the table renders from its own call and shows no menu.

## Account layouts

With `current_account_method` set, an account can keep its own layout for a key, and a members-choose switch saying whether its members may keep their own. A table shows, in this order:

1. The person's own layout, when the account lets members choose.
2. Otherwise the account's layout, when it has one.
3. Otherwise the table's default layout, from its own call.

A person whose account does not let members choose sees no Columns menu, and a save they send is refused. Reading the layout that applies makes one query, and each owner's row for a key, or the fact that there is none, is then kept in `Rails.cache` until that row is saved through the gem, so a later view makes no query. A row changed outside the gem keeps its old cache entry until it expires. With no cache configured, every view reads the rows.

An admin sets an account's layouts in a settings_hub section. Who may open it is the app's decision, so register it behind a capability of the app's choosing:

```ruby
SettingsHub.section :account_layouts, area: :account, title: "Table layouts",
  capability: :configure_site,
  renders: "keystone_ui/preferences/settings/account_layouts",
  runs: "KeystoneUi::Preferences::PickAccountLayouts"
```

The section lists each component key the admin or the account has a saved layout for, by the name the app gives it, or by the key in words when it has none:

```ruby
KeystoneUi::Preferences.configure do |config|
  config.name_component :revenue_projection_months, "Revenue projection – By month"
end
```

Each key has the members-choose switch and, when the admin has a saved layout of their own, a button that makes it the account's layout.

## Navigation placement

A person chooses where keystone_ui draws the desktop navigation, at the top or as a sidebar on the left or the right, in a settings_hub section the app registers:

```ruby
SettingsHub.section :navigation_placement, area: :user, title: "Navigation",
  renders: "keystone_ui/preferences/settings/navigation_placement",
  runs: "KeystoneUi::Preferences::PickNavigationPlacement"
```

The section offers Top, Left and Right, with the placement that applies to the person selected, or Top when nothing is saved. Saving keeps `"placement": "left"` for that person under the `navigation` key, leaving any saved tab order as it was, and keystone_ui's navigation reads it on the next page they open. A placement other than `top`, `left` or `right` is refused with a message, and nothing is saved.

The `navigation` key follows the account layouts above, so an account that turns off members-choose for it draws its own placement and tab order for every member.

While it is off, the placement and tab order sections say the account sets the navigation for everyone and offer no save. A placement, tab order or reset sent anyway is refused with a message, and nothing is saved.

## Tab order

A person sets the order of the navigation's groups, and of the tabs in each group, in a settings_hub section the app registers:

```ruby
SettingsHub.section :navigation_order, area: :user, title: "Tab order",
  renders: "keystone_ui/preferences/settings/navigation_order",
  runs: "KeystoneUi::Preferences::PickNavigationOrder"
```

The section lists the groups declared with keystone_ui's `navigation_group`, each with the tabs the person may see, in the order that applies to them. A group with no tab they may see is left out. Each group and tab has an Up and a Down button, and pressing one saves the order with it moved one place, so the page works in a Hotwire Native web view with no script and nothing to drag. At phone width each row's buttons sit under its name.

A tab declared outside any group with keystone_ui's `navigation_tab` is one row in the list of groups, named by its label, with the same Up and Down buttons as a group. It has no tab rows under it, and no button moves it into a group.

Saving keeps `"order": [{ "group": "Admin" }, { "group": "Sales", "tabs": ["orders", "quotes"] }, { "group": "Console" }]` for that person under the `navigation` key, naming groups by label and tabs by key, and a tab declared outside any group by its label alone. It leaves their saved placement as it was. keystone_ui draws the navigation in that order on the next page they open, with anything the order does not name after it in its declared order. Reset removes the saved order, so the navigation goes back to the declared order. An order that is not a list of groups is refused with a message, and nothing is saved.

## Colours

Add the palette style tag to your layout's `<head>`:

```erb
<%= keystone_palette_style_tag %>
```

It writes the same CSS variables keystone_ui-colors writes: `--color-accent-50` to `--color-accent-950`, `--color-surface-50` to `--color-surface-950`, `--color-custom-background` and `--color-custom-text`. A layout that already calls it for keystone_ui-colors keeps working unchanged, and an app must not load both gems.

The colours come from the `colours` key, read the way a table's layout is read: the person's own row, or the account's row when the account does not let members choose. A saved value looks like `{ "accent": "#e11d48", "surface": "#f5e6c8", "text": "#3b2f1e" }` or `{ "template_name": "forest" }`. A named accent or surface, such as `emerald` or `stone`, uses that palette's shades from keystone_ui-looks, and a hex value has its shades generated. A custom hex surface is also the custom background. A saved accent or surface that is neither a name of lowercase letters, digits and underscores nor a six-digit hex, and a saved text colour that is not a six-digit hex, is drawn as the configured default for that colour instead.

A saved `template_name` draws that template's accent, surface, background and text from keystone_ui-looks, whatever else the value holds. The template named `default` is built from the four defaults in the configuration. A person with nothing saved, and a visitor who is not signed in, see those four defaults.

## Appearance

A person picks their colours in a settings_hub section the app registers:

```ruby
SettingsHub.section :appearance, area: :user, title: "Appearance",
  renders: "keystone_ui/preferences/settings/appearance",
  runs: "KeystoneUi::Preferences::PickAppearance"
```

The section looks and behaves as keystone_ui-colors' colour settings do. It offers Default, the five named templates from keystone_ui-looks and Custom, with an accent, a surface and a text colour picker under them. The person's own saved choice is selected, or Default when they have none, and the pickers show the colours drawn for them now. Picking a template sets the pickers to that template's colours at once, and changing a picker selects Custom, through the template picker script the install generator copies. Without the script the section still saves, and the form saves with a full page load, so it works in a Hotwire Native web view.

Saving a template keeps `{ "template_name": "forest" }` for that person under the `colours` key. Saving Custom keeps `{ "accent": "#e11d48", "surface": "#f5e6c8", "text": "#3b2f1e" }`. Saving Default removes the person's `colours` row, so the account's colours, or the app's defaults, apply again. The next page the person opens is drawn in the saved colours.

A template that is not Default or one of the five is refused with a message, and so is a Custom accent or surface that is neither a six-digit hex nor a palette name from keystone_ui-looks, and a text colour that is not a six-digit hex. Nothing is saved.

The `colours` key follows the account layouts above. While an account turns off members-choose for it, the section says the account sets the colours for everyone and offers no save, and a save sent anyway is refused with a message and saves nothing.

## What is stored

One row per owner and component key, in `keystone_ui_preferences_component_preferences`:

| Column | Holds |
|--------|-------|
| `owner` | the person or account the value belongs to (polymorphic) |
| `component_key` | the key the page gave the component |
| `value` | the JSON object last saved |
| `members_choose` | whether an account's members may keep their own value, on by default |
