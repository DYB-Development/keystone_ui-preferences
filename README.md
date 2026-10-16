# keystone_ui-preferences

Per-user saved choices for Keystone UI components, such as a data table's hidden columns and the colours every page is drawn in.

A page gives a `ui_data_table` a `key:`. This gem saves each signed-in person's layout for that key and hands it back to keystone_ui, so the table renders from it and shows a Columns menu that saves to it. A person with nothing saved sees the hidden columns the table's own call names.

## Installation

Add the gem and run its install generator, which copies a migration for its table and the appearance editor script the Appearance sections use:

```ruby
gem "keystone_ui-preferences"
```

```bash
bundle install
bin/rails generate keystone_ui:preferences:install
bin/rails db:migrate
```

The script lands at `app/javascript/controllers/keystone_ui/preferences/appearance_editor_controller.js`. Register it in `app/javascript/controllers/index.js`:

```js
import AppearanceEditorController from "./keystone_ui/preferences/appearance_editor_controller"
application.register("keystone-ui--preferences--appearance-editor", AppearanceEditorController)
```

After updating the gem, run its update generator to copy any migrations added since it was installed, and the appearance editor script when the app does not have it yet:

```bash
bin/rails generate keystone_ui:preferences:update
bin/rails db:migrate
```

An app that installed an earlier version has a template picker script at `app/javascript/controllers/keystone_ui/preferences/theme_settings_controller.js` and a theme editor script at `app/javascript/controllers/keystone_ui/preferences/theme_editor_controller.js`. The appearance editor script replaces both. Register the appearance editor script as shown above. Then remove both old scripts and the two lines in `app/javascript/controllers/index.js` that register them as `keystone-ui--preferences--theme-settings` and `keystone-ui--preferences--theme-editor`. The update generator copies the new script and leaves both old scripts in place, so removing them is the app's own step.

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
  config.default_mode = "light"                      # the mode for a person with no mode saved and for a visitor
  config.user_looks = true                           # whether a person may choose their own look
  config.app_look_label = "Classic"                  # the label for the app's own look in the appearance section
  config.account_colors = true                       # whether an account may choose its colours, and its members their own
  config.account_looks = true                        # whether an account may choose its look
  config.theme_fonts = []                            # fonts the app serves itself that a pasted theme may name
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

It writes the same CSS variables keystone_ui-colors writes: `--color-accent-50` to `--color-accent-950`, `--color-surface-50` to `--color-surface-950`, `--color-custom-background` and `--color-custom-text`. A layout that already calls it for keystone_ui-colors keeps working unchanged, and an app that loads both gems stops at boot.

The colours come from the `colours` key, read the way a table's layout is read: the person's own row, or the account's row when the account does not let members choose. A saved value looks like `{ "accent": "#e11d48", "surface": "#f5e6c8", "text": "#3b2f1e" }`, `{ "template_name": "forest" }`, `{ "preset_name": "harbor" }` or a pasted theme, described under Appearance. A named accent or surface, such as `emerald` or `stone`, uses that palette's shades from keystone_ui-looks, and a hex value has its shades generated. A custom hex surface is also the custom background. A saved accent or surface that is neither a name of lowercase letters, digits and underscores nor a six-digit hex, and a saved text colour that is not a six-digit hex, is drawn as the configured default for that colour instead.

A saved `template_name` draws that template's accent, surface, background and text from keystone_ui-looks, whatever else the value holds. The template named `default` is built from the four defaults in the configuration. A person with nothing saved, and a visitor who is not signed in, see those four defaults.

A saved theme is written into the same style tag as a second rule, after the palette, setting the `--ks-*` variables of keystone_ui-styles that each theme role maps to. A role's light value sets each of its variables and its dark value sets each variable's `-dark` partner, so Dark mode, and System mode on a device that prefers dark, draw the theme's dark values. A role with no dark value keeps today's dark colour, and a role that maps to no variable, such as `sidebar-ring`, sets nothing. The accent, neutral and danger hover colours are derived from `primary`, `secondary` and `destructive` by mixing in 15% white. The rule's selector is `:root, html:root[data-look]`, so a theme's colours win over the colours a look sets. React components from keystone_ui-react use the same `ks-` classes, so they draw the same theme colours. The theme is checked again before it is written. A saved theme holding a value that fails the check, such as one saved before a rule was tightened, or one that is not a set of roles each holding light and dark values, is not written, and the page draws the account's colours and theme instead, or the app's defaults when the account has none or its own theme is the one that fails. Each such page writes one warning to the app's log naming the owner's type and id and the first setting that fails, for example `keystone_ui-preferences: User 5 saved a theme whose --radius setting fails the theme check`, or says the theme is not a set of roles, for example `keystone_ui-preferences: User 5 saved a theme that is not a set of roles, so it fails the theme check`. The written rule is kept in `Rails.cache` under the colours row's versioned cache key and the writer's version, so a saved change, or a new release of the writer, shows on the next page. No theme is written while `account_colors` is off.

A saved theme's shape and type are written into the same rule. `radius` sets `--ks-radius-control` and `--ks-radius-surface`, `spacing` sets `--ks-spacing`, `border-width` sets `--ks-border-width`, `letter-spacing` sets `--ks-letter-spacing`, `font-sans` sets `--ks-font-body`, `font-heading` sets `--ks-font-heading`, and `font-weight-normal`, `font-weight-medium`, `font-weight-strong` and `font-weight-heading` set the matching `--ks-font-weight-*` variable. `font-mono` sets both `--ks-font-mono` and Tailwind's `--default-mono-font-family`, since keystone_ui-styles draws code with the second, and a theme with no mono font sets neither. `font-serif` is saved but sets nothing. A theme that sets all six shadow settings writes one shadow, `<offset-x> <offset-y> <blur> <spread>` in the shadow colour mixed to the shadow opacity, to `--ks-shadow-surface`, `--ks-shadow-overlay` and `--ks-shadow-menu`, and a theme missing any of the six writes no shadow. Shape and type have no dark values. For a person who saved a look of their own, the shape and type go in a separate `:root` rule, so their look's corners, spacing, shadows, borders and fonts win over the theme's while the theme's colours still win over the look's. A look that comes only from the account or the app's default does not outrank the theme's shape and type. Whether the person saved a look is part of the cache key, so saving or removing one shows on the next page.

A saved `preset_name` writes that preset theme from keystone_ui-looks into the same rule a saved theme is written into, looked up on each page rather than copied into the row, so a preset changed in a later keystone_ui-looks release reaches everyone who picked it. The preset's values are checked as a saved theme's are before they are written. The written rule is kept in `Rails.cache` under the preset's name, the keystone_ui-looks version, the writer's version and whether the person saved a look of their own.

A saved name keystone_ui-looks no longer has still draws a page. A missing template draws the account's colours, or the four defaults when the account has none or its own template is the missing one. A missing accent or surface name draws the default accent or surface. A missing preset falls back the same way as a missing template, to the account's colours and theme, or to the four defaults when the account has none or its own preset is the missing one. Each of these writes one warning to the app's log naming the owner's type and id and the missing name, for example `keystone_ui-preferences: User 5 saved the template "retired", which keystone_ui-looks does not have`. A saved value that is not a name or a six-digit hex falls back with no warning. The saved row is left as it is until the owner saves again, and the appearance section shows no template selected for it.

## Appearance

A person picks their colours in a settings_hub section the app registers:

```ruby
SettingsHub.section :appearance, area: :user, title: "Appearance",
  renders: "keystone_ui/preferences/settings/appearance",
  runs: "KeystoneUi::Preferences::PickAppearance"
```

The section looks and behaves as keystone_ui-colors' colour settings do. It offers Default, the five named templates from keystone_ui-looks, the six preset themes from keystone_ui-looks and Custom, with an accent, a surface and a text colour picker under them. The person's own saved choice is selected, or Default when they have none, and the pickers show the colours drawn for them now. Picking a template sets the pickers to that template's colours at once, and changing a picker selects Custom, through the appearance editor script the install generator copies. Without the script the section still saves, and the form saves with a full page load, so it works in a Hotwire Native web view.

Saving a template keeps `{ "template_name": "forest" }` for that person under the `colours` key. Saving a preset theme keeps only its name, as `{ "preset_name": "harbor" }`. Saving Custom keeps `{ "accent": "#e11d48", "surface": "#f5e6c8", "text": "#3b2f1e" }`. Saving Default removes the person's `colours` row, so the account's colours, or the app's defaults, apply again. The next page the person opens is drawn in the saved colours.

A template or preset name that is not Default, one of the five templates or one of the six preset themes is refused with a message, and so is a Custom accent or surface that is neither a six-digit hex nor a palette name from keystone_ui-looks, and a text colour that is not a six-digit hex. Nothing is saved.

The Theme section also has a paste box for a theme in shadcn/ui's variable names, as tweakcn and shadcn's theme pages export it. Only declarations in a `:root` block and a `.dark` block are read, either at the top level or inside an `@layer` rule, and only the theme's settings are kept. Those are the 32 shadcn colour roles: `background`, `foreground`, `card`, `card-foreground`, `popover`, `popover-foreground`, `primary`, `primary-foreground`, `secondary`, `secondary-foreground`, `muted`, `muted-foreground`, `accent`, `accent-foreground`, `destructive`, `destructive-foreground`, `border`, `input`, `ring`, `chart-1` to `chart-5` and the eight `sidebar` roles. They are also shadcn's shape and type settings, `radius`, `spacing`, `letter-spacing`, `font-sans`, `font-serif`, `font-mono`, `shadow-color`, `shadow-opacity`, `shadow-blur`, `shadow-spread`, `shadow-offset-x` and `shadow-offset-y`. Last are the settings shadcn has no name for, `border-width`, `font-heading`, `font-weight-normal`, `font-weight-medium`, `font-weight-strong` and `font-weight-heading`. Every other declaration, selector and rule is ignored, including ready-made shadows such as `--shadow-sm`.

Each colour must be a hex colour or an `rgb()`, `hsl()` or `oklch()` colour written with plain numbers, such as `oklch(0.205 0 0)` or `oklch(1 0 0 / 10%)`. Saving keeps only the checked colours, as `{ "theme": { "primary": { "light": "oklch(0.205 0 0)", "dark": "oklch(0.922 0 0)" } } }` under the `colours` key, and the pasted text itself is never stored. A role with no value in the `.dark` block is kept with a light value alone.

Shape and type settings are kept from the `:root` block only, as `{ "radius": { "light": "0.5rem" } }`, and each is checked by its kind. A radius, spacing, border width or shadow blur must be a number followed by `px`, `rem` or `em`, or zero. A shadow's spread and offsets, and a letter spacing, may also be negative, and a letter spacing may be `normal`. A shadow colour is checked as a colour, a shadow opacity must be a number from 0 to 1, and a font weight must be a whole hundred from 100 to 900. A font list must be comma-separated names made of letters, digits, spaces and hyphens, each optionally in single or double quotes. A font in the list is kept only when the app names it in `theme_fonts` or it is one of the system fonts the gem lists: `system-ui`, `ui-sans-serif`, `ui-serif`, `ui-monospace`, `ui-rounded`, `sans-serif`, `serif`, `monospace`, `cursive`, `-apple-system`, `BlinkMacSystemFont`, `Segoe UI`, `Roboto`, `Helvetica`, `Helvetica Neue`, `Arial`, `Georgia`, `Times New Roman`, `Menlo`, `Monaco`, `Consolas`, `Courier New` and `SFMono-Regular`. Any other font is dropped, so the browser uses the next font in the list and nothing is requested from another site. A kept name of more than one word is written in double quotes and a one-word name is written bare. The gem loads no font file, so an app that names a font in `theme_fonts` serves that font itself. The Theme section then says the current choice is the person's own theme and selects no template. The palette style tag then writes the theme onto every page, as described under Colours.

Each refusal below saves nothing and says why. A paste over 20,000 characters is refused before any of it is read. A paste containing `url(` or `@import` anywhere is refused. A paste with no shadcn colour role in a `:root` or `.dark` block is refused. A colour that fails the check is refused with a message naming the role and whether it is the light or dark value. A shape or type value that fails its check is refused with a message naming the setting, and so is a font list left with no font the app offers. A paste is refused with the same message as other colours while the account sets the colours for everyone.

After Look and Mode, the section lists every theme setting as its own field, named by its shadcn variable, with no closed disclosure around them. The fields are grouped as tweakcn's editor groups them. Colors holds the colour roles in sets, each with its foreground beside it: Page (`background` and `foreground`), Primary, Secondary, Accent, Muted, Card, Popover, Destructive, Border, input and ring, Chart (`chart-1` to `chart-5`) and the eight Sidebar roles. Typography holds the sans, serif, mono and heading fonts, the four font weights and the letter spacing. Other holds the radius, the spacing, the border width and the six shadow settings. Each colour role has a light and a dark keystone_ui colour picker side by side, and the shadow colour has one, so a colour can be typed as hex, `rgb()`, `hsl()` or `oklch()`. Every other setting is a text field. Each font field suggests the fonts in `theme_fonts` and then the system fonts the gem offers, and still takes a typed list of several fonts. The fields show the person's saved theme, so after a paste they hold the values that were read. Changing a field and pressing Save saves the fields as the person's theme, so a theme edited by hand stays the person's own. A field left blank leaves that setting out of the theme. Each value is checked and refused exactly as a pasted one is, with spaces around it removed first. The fields are saved only when they differ from the saved theme, so picking a template or changing the Accent, Surface or Text picker saves as before, and a paste sent in the same save wins over the fields. The grouped fields and the font suggestions need no script, but the colour pickers need keystone_ui's colour picker script to take a typed colour.

Each change to a theme field is drawn on the whole page before saving, through the appearance editor script the install generator copies. The script sets the setting's `--ks-*` variables on the page's root element, taking the list of which setting sets which variables from the same theme roles list the palette style tag writes from, so the page looks as it will after Save. A colour also sets the hover colour the style tag derives from `primary`, `secondary` and `destructive`, and a dark value sets only the `-dark` variables, so it shows only where the page is drawn dark. Colours, corner radius, spacing, border width, letter spacing, fonts, font weights and the shadow are drawn this way, and the shadow is drawn only once all six shadow settings hold a value, as the style tag writes it. A value the browser cannot draw leaves the page as it was, and it is still sent and checked on Save. Leaving the section without saving removes every variable the script set, so the next page, a Turbo visit included, is drawn in the saved theme. The script saves nothing and sends no request, so Save works as before, and without the script the fields still save.

Beside the fields the section shows a preview of keystone_ui's own components: a card, a primary, a secondary and a danger button, a form with a text field and a select, a table, a line chart and a sidebar navigation list. The preview is drawn twice, once on a side marked light and once on a side marked dark, from sample data the gem holds. Each unsaved change the appearance editor script draws on the page also shows in the preview, so a dark value changes only the dark side, including while the page itself is drawn dark. A chart colour redraws the preview's line chart and a sidebar colour changes its navigation list. The preview names no font of its own and loads nothing from another site, so it draws in the fonts the theme sets. On a screen 64rem wide or wider the fields and the preview sit side by side. On a narrower screen, such as a phone, the section shows an Edit tab and a Preview tab from keystone_ui's tab switcher, and picking a tab shows its panel through the appearance editor script. The preview needs keystone_ui-styles 0.23.0 or later, whose dark styles leave a side marked light drawn light inside a dark page, and keystone_ui 0.47.0 or later, whose line chart takes light or dark from the side it is drawn on and redraws when the theme's variables change, and it needs keystone_ui's tab switcher and line chart scripts registered. The preview is shown only alongside the theme fields, so it is not shown while the account sets the colours for everyone.

The preset themes are option cards after the templates, each showing its light primary and secondary colours as swatches, and the person's saved preset is selected. Picking a preset card fills the theme fields with that preset's values, through the appearance editor script, which draws them on the whole page and the preview before saving, as it draws a field changed by hand. Once a preset is saved the fields show its values. Theme fields sent unchanged, holding the picked or the saved preset's values, save the picked card as before. Changing a field after picking a preset saves the fields as the person's own theme in place of the preset. Without the script, picking a card and pressing Save still saves the preset. A Reset button beside Save fills every theme field, the page and the preview from the picked preset card, or from the saved theme when no preset card is picked, and saves nothing. A setting the saved theme leaves out is emptied, and the page draws it from the saved theme again.

Once a theme field differs from the saved theme, or the picked colour card, the Custom accent, surface or text picker, the picked Mode, the picked Look or, in the account's section, either Members choose switch differs from what the page opened with, or the paste box holds text, the appearance editor script asks before the change is lost. The page opens with the saved colour card, colours, Mode, Look and switches selected, after a refused save as well, so picking another and then the saved one again asks nothing. A paste box that is empty or holds only spaces sends nothing to save, so it asks nothing. Following a link out of the section holds the Turbo visit and opens a question on the page, from keystone_ui's modal, offering Leave without saving and Stay. Leave without saving carries on to the page the link was going to, and Stay closes the question. Because the question is part of the page, it shows in a Hotwire Native web view, where Turbo asks the page before it hands a link to the app. Closing or reloading the page asks the browser to show its own leave-page warning, which a Hotwire Native web view does not show. The native back button and tab bar of a Hotwire Native app leave the page without asking it, so they leave with no question, and so does the browser's back button. Saving, resetting to the saved theme, or changing nothing leaves with no question. The question is part of every Appearance section, the person's and the account's, including one that offers no colours. The question needs keystone_ui's modal script registered as `modal`.

After the theme fields an Export text area shows the fields' current values, saved or not, as a `:root` block with every light value and a `.dark` block with every dark value, in shadcn/ui's variable names, which is the shape the paste box reads. The appearance editor script writes it when the section opens and again on each change, in the browser, so it carries unsaved edits. The text area is read-only and has no name, so Save does not send it. A Copy button beside it copies the export through keystone_ui's clipboard script with no request to the server. Where the browser refuses to copy, as a Hotwire Native web view may, the button says to select the text, and the text area can be selected and copied by hand. A value holding a semicolon or a curly brace is left out, so it cannot end its block or add a setting. An exported theme pasted back into the paste box and saved keeps every value it held. Copying needs keystone_ui's clipboard script registered. The export is not offered in keystone's own `--ks-*` variable names.

The `colours` key follows the account layouts above. While an account turns off members-choose for it, the section says the account sets the colours for everyone and offers no colours, and a save that sends colours anyway is refused with a message and saves nothing.

## Mode

The appearance section also offers Light, Dark and System, as keystone_ui-colors' mode control does, with the person's saved mode selected, or `default_mode` when they have none. It offers Custom too when the person may choose their own colours, or when the colours that apply to them draw a background other than white. The mode is offered while the account sets the colours, and saving it there keeps the mode alone.

Saving keeps `{ "mode": "dark" }` for that person under the `mode` key. A mode is only ever read from the person's own row, never from the account's, so it applies whether or not the account lets members choose colours. A mode other than `light`, `dark`, `system` or `custom` is refused with a message, and nothing is saved.

The gem gives keystone_ui the mode through keystone_ui's theme mode supplier, so a layout whose `<html>` tag calls keystone_ui's `keystone_theme_attributes` is marked with the person's mode on every page:

```erb
<html <%= keystone_theme_attributes %>>
```

A visitor who is not signed in gets `default_mode`. A choice made with keystone_ui's theme toggle is kept in a cookie and wins over the saved mode in that browser. Saving in the appearance section clears that cookie, so the saved mode shows on the next page. The clearing runs in settings_hub's `after_settings_change` hook, which the `ComponentPreferences` concern defines, so an app that defines its own `after_settings_change` calls `super` from it.

## Look

When the app registers looks with keystone_ui, the appearance section also offers a look, as keystone_ui-colors' look control does. It lists the app's own look first, labelled with `app_look_label`, and then every registered look by name. The person's saved look is selected, or the app's own look when they have none.

Saving a look keeps `{ "look": "rounded" }` for that person under the `look` key. Saving the app's own look removes the person's `look` row, so the account's look, or the app's default look, applies again. A look name keystone_ui does not register is refused with a message, and nothing is saved.

A person's look comes from their own row while the account lets members choose their own look, then from the account's row, and a saved look the app no longer registers is passed over for the next one. With neither, keystone_ui uses its `default_look`. A visitor who is not signed in gets `default_look` too.

The gem gives keystone_ui the look through keystone_ui's look supplier, so the same `keystone_theme_attributes` call marks the `<html>` tag with `data-look` on every page.

An app that keeps people off their own looks sets `user_looks` to false. The appearance section then shows no look choice, a save ignores any look sent with it and keeps the rest, and a person's saved look is passed over for the account's look or the app's default look. With no looks registered the section shows no look choice.

## Account appearance

An admin sets the account's colours and look in a settings_hub section. Who may open it is the app's decision, so register it behind a capability of the app's choosing. settings_hub refuses a capability the app does not define, so use the one the app already uses for its other account sections in place of `:manage_account`:

```ruby
SettingsHub.section :account_appearance, area: :account, title: "Appearance",
  capability: :manage_account,
  renders: "keystone_ui/preferences/settings/account_appearance",
  runs: "KeystoneUi::Preferences::PickAccountAppearance"
```

The section looks and behaves as keystone_ui-colors' account picker does. It offers Default, the five named templates, the six preset themes and Custom with the three colour pickers and the paste box the person's section has, then the app's own look and every registered look, with the account's saved choices selected, or Default and the app's own look when it has none. Under them are two switches, one for whether members choose their own colours and one for whether members choose their own look. Both are on until an admin turns them off. The theme fields come last, grouped into Colors, Typography and Other as in the person's section. The section is the same theme editor as the person's. Each change to a field and each picked preset card is drawn on the whole page before saving. The preview sits beside the fields on a wide screen and under Edit and Preview tabs on a phone. A Reset button beside Save fills the fields from the picked preset card, or from the account's saved theme, and saves nothing. The Export text area and its Copy button carry the fields' current values. Leaving the section without saving draws the next page in the admin's own saved theme. While the app turns off account colours the section shows no preview, no tabs and no Reset button.

Saving keeps the account's colours under the `colours` key, as `{ "template_name": "forest" }`, `{ "preset_name": "harbor" }`, `{ "accent": "#e11d48", "surface": "#f5e6c8", "text": "#3b2f1e" }` or a pasted or hand-edited theme, and its look under the `look` key, with each switch in that row's `members_choose` column. Saving Default keeps `{ "template_name": "default" }`, and saving the app's own look keeps an empty look, so neither removes the row its switch is on. The colours, a pasted theme, the theme fields and the look pass the same checks as a person's, the theme fields are saved only when they differ from the account's saved theme or the picked or saved preset, and a template, preset, colour, theme value or look that fails one is refused with a message, and nothing is saved. A save with no account is refused too.

A member with no colours of their own sees the account's colours and theme. While the colours switch is off, every member sees the account's colours and theme, and their appearance section says the account sets the colours and offers no colour choice. While the look switch is off, every member sees the account's look, and their appearance section offers no look choice. A look a member sends then is ignored, and the rest of the save is kept. While the look switch is on, a member who chose a look keeps it, and a member with none sees the account's.

An app that keeps accounts off colours sets `account_colors` to false. Neither section then offers a colour choice or the colours switch, every page is drawn in the four configured defaults, and colours sent to either section are refused with a message. An app that keeps accounts off looks sets `account_looks` to false. The account's section then offers no look choice and no look switch, a look sent to it is ignored, and a saved account look is not applied.

## Keeping a page on the app's colours

A controller that declares `keystone_host_colors` draws its pages in the app's four default colours, `default_mode` and keystone_ui's `default_look`, whatever the signed-in person or their account saved. The declaration has the same name keystone_ui-colors gives it, so a controller that already declares it keeps working unchanged. It takes the same `only:` and `except:` options as `before_action`.

```ruby
class HomeController < ApplicationController
  keystone_host_colors
end
```

A choice made with keystone_ui's theme toggle in that browser still sets light or dark on these pages.

## Moving off keystone_ui-colors

An app that saved colours, modes and looks with keystone_ui-colors keeps them by following these steps in this order. An app that has never installed keystone_ui-preferences runs its install generator at step 5 instead of the update generator.

1. Set keystone_ui-preferences to `~> 0.7` and remove keystone_ui-colors from the Gemfile, then run `bundle install`.
2. Change every `KeystoneUi::Colors` name the app uses to its replacement, and move any settings from a keystone_ui-colors initializer into a keystone_ui-preferences initializer. keystone_ui-colors' README lists each name and what replaces it under [Moving to keystone_ui-preferences](https://github.com/DYB-Development/keystone_ui-colors#moving-to-keystone_ui-preferences).
3. Register the person's appearance section and the account's appearance section, as [Appearance](#appearance) and [Account appearance](#account-appearance) show. Register the account's behind the capability the app already uses for its other account sections.
4. Call `super` from any `after_settings_change` the app defines.
5. Run its update generator, which copies the migration below into `db/migrate`.
6. Run `bin/rails db:migrate`.

```bash
# set keystone_ui-preferences to ~> 0.7 and remove keystone_ui-colors from the Gemfile
bundle install
# change each KeystoneUi::Colors name, move the initializer settings, register both appearance sections, call super from after_settings_change
bin/rails generate keystone_ui:preferences:update
bin/rails db:migrate
```

Boot stops with `KeystoneUi::Preferences::ColorsCheck::Error` while keystone_ui-colors is loaded, and the message names keystone_ui-colors as the gem to remove. The update generator and `bin/rails db:migrate` both boot the app, so keystone_ui-colors comes out of the Gemfile before either runs. An initializer, route, controller or helper that still names `KeystoneUi::Colors`, such as a `KeystoneUi::Colors.configure` block, a route mounting `KeystoneUi::Colors::Engine`, `include KeystoneUi::Colors::CurrentPalette` or `helper KeystoneUi::Colors::PaletteHelper`, also stops the app from booting, so every name is changed before the generator runs.

The generator copies a migration that reads every row of `keystone_ui_colors_theme_preferences` and writes up to three rows for the same owner:

| keystone_ui-colors | keystone_ui-preferences |
|--------------------|-------------------------|
| `template_name`, including `default` | `colours` row holding `{"template_name": ...}` |
| `accent`, `surface` and `text` with no template | `colours` row holding `{"accent": ..., "surface": ..., "text": ...}` |
| `members_choose` | `members_choose` of the `colours` row |
| `mode` | `mode` row holding `{"mode": ...}`, written only when a mode was saved |
| `look` | `look` row holding `{"look": ...}`, written only when a look was saved |
| `members_choose_look` | `members_choose` of the `look` row, which holds `{}` for an account on the app's own look that sets the look for everyone |

An owner and key that already has a row keeps it, so a choice made in keystone_ui-preferences is never replaced by an older one, and running the migration again changes nothing. In an app without keystone_ui-colors' table the migration does nothing. Rolling it back changes neither table. Drop keystone_ui-colors' table once the copy has run.

## What is stored

One row per owner and component key, in `keystone_ui_preferences_component_preferences`:

| Column | Holds |
|--------|-------|
| `owner` | the person or account the value belongs to (polymorphic) |
| `component_key` | the key the page gave the component |
| `value` | the JSON object last saved |
| `members_choose` | whether an account's members may keep their own value, on by default |
