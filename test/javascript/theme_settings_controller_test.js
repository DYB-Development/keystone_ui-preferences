import { test } from "node:test"
import assert from "node:assert/strict"
import ThemeSettingsController from "../../app/javascript/keystone_ui/preferences/theme_settings_controller.js"

function panel() {
  const attributes = new Set()
  return {
    attributes,
    toggleAttribute(name, force) { force ? attributes.add(name) : attributes.delete(name) }
  }
}

function settingsHolding(panels) {
  const element = { querySelectorAll: (selector) => (selector === "[data-editor-panel]" ? panels : []) }
  return new ThemeSettingsController({ scope: { element } })
}

test("picking a tab shows the panel in that tab's place and hides the others", () => {
  const panels = [panel(), panel()]
  panels[0].attributes.add("data-shown")

  settingsHolding(panels).showPanel({ detail: { index: 1 } })

  assert.deepEqual(panels.map(({ attributes }) => attributes.has("data-shown")), [false, true])
})
