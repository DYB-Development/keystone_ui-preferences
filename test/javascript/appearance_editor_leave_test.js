import { test } from "node:test"
import assert from "node:assert/strict"
import AppearanceEditorController from "../../app/javascript/keystone_ui/preferences/appearance_editor_controller.js"

function sectionLoadedWith(values) {
  const fields = Object.entries(values).map(([name, value]) => ({ name, value }))
  const element = {
    ownerDocument: { documentElement: { style: {} } },
    querySelector: () => null,
    querySelectorAll: (selector) => (selector === "[name^='theme[']" ? fields : [])
  }
  const editor = new AppearanceEditorController({ scope: { element } })
  editor.connect()
  editor.change = (name, value) => { fields.find((field) => field.name === name).value = value }
  return editor
}

function visit(url = "/settings/layouts") {
  return { detail: { url }, held: false, preventDefault() { this.held = true } }
}

test("following a link after changing a theme field holds the visit", () => {
  const editor = sectionLoadedWith({ "theme[primary][light]": "#000000" })
  editor.change("theme[primary][light]", "#1f5fbf")
  const leaving = visit()

  editor.confirmLeave(leaving)

  assert.equal(leaving.held, true)
})
