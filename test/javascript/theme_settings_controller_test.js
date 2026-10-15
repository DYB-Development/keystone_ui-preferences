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

function editorFormOn(root, values, { chosenPreset = null, savedTheme = {} } = {}) {
  const roles = { primary: { kind: "colour", variables: ["--ks-color-accent"] }, radius: { kind: "length", variables: ["--ks-radius-control"] } }
  const exported = { value: "" }
  const copyButton = { dataset: {} }
  const editorElement = { ownerDocument: { documentElement: root }, dataset: { themeRoles: JSON.stringify(roles) } }
  const editor = new ThemeEditorController({ scope: { element: editorElement } })
  const fields = Object.entries(values).map(([name, value]) => field(name, value, (event) => editor.apply(event)))
  editorElement.querySelector = (selector) => ({ "[data-theme-export]": exported, "[data-controller~='clipboard']": copyButton })[selector] ?? fields.find(({ name }) => selector === `[name="${name}"]`) ?? null
  const element = {
    querySelector(selector) {
      if (selector === "input[name='template_name'][data-theme]:checked") return chosenPreset && { dataset: { theme: JSON.stringify(chosenPreset) } }
      if (selector === "[data-saved-theme]") return { dataset: { savedTheme: JSON.stringify(savedTheme) } }
      return fields.find(({ name }) => selector === `[name="${name}"]`) ?? null
    },
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

test("reset fills every theme field from the chosen preset", () => {
  const preset = { primary: { light: "#1f5fbf", dark: "#8ab4f8" }, radius: { light: "0.5rem" } }
  const { fields, settings } = editorFormOn(pageRoot(), { "theme[primary][light]": "#ff0000", "theme[primary][dark]": "#ff0000", "theme[radius][light]": "2rem" }, { chosenPreset: preset })

  settings.reset()

  assert.deepEqual(fields.map(({ value }) => value), ["#1f5fbf", "#8ab4f8", "0.5rem"])
})

test("reset with no preset chosen draws the saved theme on the page, removing what the editor set for a setting the saved theme leaves empty", () => {
  const root = pageRoot()
  const { settings } = editorFormOn(root, { "theme[primary][light]": "#ff0000", "theme[primary][dark]": "#ff0000", "theme[radius][light]": "2rem" }, { savedTheme: { primary: { light: "#1f5fbf", dark: "#8ab4f8" } } })
  settings.selectPreset(presetCard({ primary: { light: "#ff0000", dark: "#ff0000" }, radius: { light: "2rem" } }))

  settings.reset()

  assert.deepEqual(root.variables, { "--ks-color-accent": "#1f5fbf", "--ks-color-accent-dark": "#8ab4f8" })
})

function colourPicker() {
  const parts = {
    "input[type='hidden']": { value: "" },
    "[data-color-picker-target='swatch']": { style: {} },
    "[data-color-picker-target='hexLabel']": { textContent: "" },
    "[data-color-picker-target='text']": { value: "" }
  }
  return {
    parts,
    querySelector: (selector) => parts[selector] ?? null,
    shown: () => [parts["input[type='hidden']"].value, parts["[data-color-picker-target='swatch']"].style.backgroundColor, parts["[data-color-picker-target='hexLabel']"].textContent, parts["[data-color-picker-target='text']"].value]
  }
}

function templateCard(accentHex, surfaceHex, textHex) {
  return { currentTarget: { dataset: { accentHex, surfaceHex, textHex }, closest: () => ({ dataset: { template: "forest" } }) } }
}

test("picking a template card fills the accent, surface and text pickers with that template's colours", () => {
  const settings = new ThemeSettingsController({ scope: { element: {} } })
  const pickers = [colourPicker(), colourPicker(), colourPicker()]
  Object.assign(settings, { accentPickerTarget: pickers[0], surfacePickerTarget: pickers[1], textPickerTarget: pickers[2], templateLabelTargets: [] })

  settings.selectTemplate(templateCard("#10b981", "#78716c", "#064e3b"))

  assert.deepEqual(pickers.map((picker) => picker.shown()), [["#10b981", "#10b981", "#10b981", "#10b981"], ["#78716c", "#78716c", "#78716c", "#78716c"], ["#064e3b", "#064e3b", "#064e3b", "#064e3b"]])
})

function cardLabel(template, border) {
  const classes = new Set([border])
  const span = { classList: { add: (name) => classes.add(name), remove: (name) => classes.delete(name) } }
  return { dataset: { template }, querySelector: (selector) => (selector === "span" ? span : null), classes }
}

function bordersOf(labels) {
  return labels.map(({ classes }) => [...classes].sort())
}

test("picking a template card outlines that card and clears the outline from every other card", () => {
  const settings = new ThemeSettingsController({ scope: { element: {} } })
  const labels = [cardLabel("default", "border-accent-500"), cardLabel("forest", "border-transparent"), cardLabel("custom", "border-transparent")]
  Object.assign(settings, { accentPickerTarget: colourPicker(), surfacePickerTarget: colourPicker(), textPickerTarget: colourPicker(), templateLabelTargets: labels })

  settings.selectTemplate(templateCard("#10b981", "#78716c", "#064e3b"))

  assert.deepEqual(bordersOf(labels), [["border-transparent"], ["border-accent-500"], ["border-transparent"]])
})
