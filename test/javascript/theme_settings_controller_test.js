import { test } from "node:test"
import assert from "node:assert/strict"
import ThemeSettingsController from "../../app/javascript/keystone_ui/preferences/theme_settings_controller.js"
import ThemeEditorController from "../../app/javascript/keystone_ui/preferences/theme_editor_controller.js"

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

globalThis.CSS = { supports: () => true }

function pageRoot() {
  const variables = {}
  return {
    variables,
    style: {
      setProperty(name, value) { variables[name] = value },
      removeProperty(name) { delete variables[name] }
    }
  }
}

function field(name, value, onEvent) {
  return {
    name,
    value,
    closest: () => null,
    dispatchEvent(event) { if (event.bubbles) onEvent({ type: event.type, target: this }) }
  }
}

function editorFormOn(root, values) {
  const roles = { primary: { kind: "colour", variables: ["--ks-color-accent"] }, radius: { kind: "length", variables: ["--ks-radius-control"] } }
  const editor = new ThemeEditorController({ scope: { element: { ownerDocument: { documentElement: root }, dataset: { themeRoles: JSON.stringify(roles) } } } })
  const fields = Object.entries(values).map(([name, value]) => field(name, value, (event) => editor.apply(event)))
  const element = {
    querySelector: (selector) => fields.find(({ name }) => selector === `[name="${name}"]`) ?? null,
    querySelectorAll: (selector) => (selector === "[name^='theme[']" ? fields : [])
  }
  const settings = new ThemeSettingsController({ scope: { element } })
  settings.templateLabelTargets = []
  return { fields, settings }
}

function presetCard(theme) {
  return { currentTarget: { dataset: { theme: JSON.stringify(theme) }, closest: () => ({ dataset: { template: "harbor" } }) } }
}

test("picking a preset card draws the preset on the page's root element before saving", () => {
  const root = pageRoot()
  const { settings } = editorFormOn(root, { "theme[primary][light]": "#000000", "theme[primary][dark]": "#000000", "theme[radius][light]": "0rem" })

  settings.selectPreset(presetCard({ primary: { light: "#1f5fbf", dark: "#8ab4f8" }, radius: { light: "0.5rem" } }))

  assert.deepEqual(root.variables, { "--ks-color-accent": "#1f5fbf", "--ks-color-accent-dark": "#8ab4f8", "--ks-radius-control": "0.5rem" })
})
