# keystone_ui-preferences

Per-user saved choices for Keystone UI components, such as a data table's hidden columns.

A page gives a `ui_data_table` a `key:`. This gem saves each signed-in person's layout for that key and hands it back to keystone_ui, so the table renders from it and shows a Columns menu that saves to it. A person with nothing saved sees the hidden columns the table's own call names.

## Installation

Add the gem and run its install generator, which copies a migration for its table:

```ruby
gem "keystone_ui-preferences"
```

```bash
bundle install
bin/rails generate keystone_ui:preferences:install
bin/rails db:migrate
```

After updating the gem, run its update generator to copy any migrations added since it was installed:

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

## What is stored

One row per owner and component key, in `keystone_ui_preferences_component_preferences`:

| Column | Holds |
|--------|-------|
| `owner` | the person or account the value belongs to (polymorphic) |
| `component_key` | the key the page gave the component |
| `value` | the JSON object last saved |
| `members_choose` | whether an account's members may keep their own value, on by default |
