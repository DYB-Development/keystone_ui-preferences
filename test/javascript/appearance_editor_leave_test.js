import { test } from "node:test"
import assert from "node:assert/strict"
import AppearanceEditorController from "../../app/javascript/keystone_ui/preferences/appearance_editor_controller.js"

globalThis.CSS ??= { supports: () => true }

function themeOf(values) {
  const theme = {}
  Object.entries(values).filter(([, value]) => value !== "").forEach(([name, value]) => {
    const [, role, side] = name.match(/^theme\[([^\]]+)\]\[(light|dark)\]$/)
    theme[role] = { ...theme[role], [side]: value }
  })
  return theme
}

function sectionLoadedWith(values, savedTheme = themeOf(values), choices = []) {
  const fields = Object.entries(values).map(([name, value]) => ({ name, value, closest: () => null, dispatchEvent() {} }))
  const visited = []
  const question = { classes: new Set(["hidden"]), classList: { add(name) { question.classes.add(name) }, remove(name) { question.classes.delete(name) } } }
  const roles = { primary: { kind: "colour", variables: ["--ks-color-accent"] } }
  const parts = { "[data-saved-theme]": { dataset: { savedTheme: JSON.stringify(savedTheme) } }, "[data-theme-roles]": { dataset: { themeRoles: JSON.stringify(roles) } }, "[data-leave-question] [data-modal-target='backdrop']": question }
  const element = {
    ownerDocument: { documentElement: { style: { setProperty() {}, removeProperty() {} } }, defaultView: { Turbo: { visit(url) { visited.push(url) } } } },
    querySelector: (selector) => parts[selector] ?? fields.find(({ name }) => selector === `[name="${name}"]`) ?? null,
    querySelectorAll: (selector) => (selector === "[name^='theme[']" ? fields : choices.filter(({ name }) => selector.includes(`[name='${name}']`)))
  }
  const editor = new AppearanceEditorController({ scope: { element } })
  editor.connect()
  editor.change = (name, value) => { fields.find((field) => field.name === name).value = value }
  editor.pick = (name, value) => choices.filter((choice) => choice.name === name).forEach((choice) => { choice.checked = choice.value === value })
  editor.questionShown = () => !question.classes.has("hidden")
  editor.visited = visited
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

test("a held visit opens the question asking whether to leave without saving", () => {
  const editor = sectionLoadedWith({ "theme[primary][light]": "#000000" })
  editor.change("theme[primary][light]", "#1f5fbf")

  editor.confirmLeave(visit())

  assert.equal(editor.questionShown(), true)
})

test("choosing to leave without saving visits the page the held visit was going to", () => {
  const editor = sectionLoadedWith({ "theme[primary][light]": "#000000" })
  editor.change("theme[primary][light]", "#1f5fbf")
  editor.confirmLeave(visit("/settings/layouts"))

  editor.leave()

  assert.deepEqual(editor.visited, ["/settings/layouts"])
})

test("the visit made after choosing to leave is not held again", () => {
  const editor = sectionLoadedWith({ "theme[primary][light]": "#000000" })
  editor.change("theme[primary][light]", "#1f5fbf")
  editor.confirmLeave(visit("/settings/layouts"))
  editor.leave()
  const leaving = visit("/settings/layouts")

  editor.confirmLeave(leaving)

  assert.equal(leaving.held, false)
})

test("following a link with no theme field changed is not held", () => {
  const editor = sectionLoadedWith({ "theme[primary][light]": "#000000" })
  const leaving = visit()

  editor.confirmLeave(leaving)

  assert.equal(leaving.held, false)
})

test("following a link after resetting the changed fields to the saved theme is not held", () => {
  const editor = sectionLoadedWith({ "theme[primary][light]": "#000000", "theme[radius][light]": "" }, { primary: { light: "#000000" } })
  editor.change("theme[primary][light]", "#1f5fbf")
  editor.change("theme[radius][light]", "0.5rem")
  editor.reset()
  const leaving = visit()

  editor.confirmLeave(leaving)

  assert.equal(leaving.held, false)
})

function unload() {
  return { warned: false, preventDefault() { this.warned = true } }
}

test("closing or reloading the page after changing a theme field asks the browser to warn first", () => {
  const editor = sectionLoadedWith({ "theme[primary][light]": "#000000" })
  editor.change("theme[primary][light]", "#1f5fbf")
  const closing = unload()

  editor.warnBeforeUnload(closing)

  assert.equal(closing.warned, true)
})

test("closing or reloading the page with no theme field changed is not warned about", () => {
  const editor = sectionLoadedWith({ "theme[primary][light]": "#000000" })
  const closing = unload()

  editor.warnBeforeUnload(closing)

  assert.equal(closing.warned, false)
})

test("saving changed theme fields unloads the page without a warning", () => {
  const editor = sectionLoadedWith({ "theme[primary][light]": "#000000" })
  editor.change("theme[primary][light]", "#1f5fbf")
  editor.save()
  const closing = unload()

  editor.warnBeforeUnload(closing)

  assert.equal(closing.warned, false)
})

test("following a link from a section refilled by a refused save, with nothing changed since, holds the visit", () => {
  const editor = sectionLoadedWith({ "theme[primary][light]": "#1f5fbf" }, { primary: { light: "#000000" } })
  const leaving = visit()

  editor.confirmLeave(leaving)

  assert.equal(leaving.held, true)
})

function card(name, value, checked = false) {
  return { name, value, type: "radio", checked }
}

test("following a link after picking another colour card holds the visit", () => {
  const editor = sectionLoadedWith({}, {}, [card("template_name", "default", true), card("template_name", "ocean")])
  editor.pick("template_name", "ocean")
  const leaving = visit()

  editor.confirmLeave(leaving)

  assert.equal(leaving.held, true)
})

function picker(name, value) {
  return { name, value, type: "hidden" }
}

test("following a link after changing the Custom accent, surface or text picker holds the visit", () => {
  const choices = [picker("accent", "#3b82f6")]
  const editor = sectionLoadedWith({}, {}, choices)
  choices[0].value = "#ef4444"
  const leaving = visit()

  editor.confirmLeave(leaving)

  assert.equal(leaving.held, true)
})

test("following a link after picking another Mode holds the visit", () => {
  const editor = sectionLoadedWith({}, {}, [card("mode", "light", true), card("mode", "dark")])
  editor.pick("mode", "dark")
  const leaving = visit()

  editor.confirmLeave(leaving)

  assert.equal(leaving.held, true)
})

test("following a link after picking another Look holds the visit", () => {
  const editor = sectionLoadedWith({}, {}, [card("look", "", true), card("look", "rounded")])
  editor.pick("look", "rounded")
  const leaving = visit()

  editor.confirmLeave(leaving)

  assert.equal(leaving.held, true)
})

test("following a link after picking another Mode and then the saved Mode again is not held", () => {
  const editor = sectionLoadedWith({}, {}, [card("mode", "light", true), card("mode", "dark")])
  editor.pick("mode", "dark")
  editor.pick("mode", "light")
  const leaving = visit()

  editor.confirmLeave(leaving)

  assert.equal(leaving.held, false)
})

test("closing or reloading the page after picking another colour card asks the browser to warn first", () => {
  const editor = sectionLoadedWith({}, {}, [card("template_name", "default", true), card("template_name", "ocean")])
  editor.pick("template_name", "ocean")
  const closing = unload()

  editor.warnBeforeUnload(closing)

  assert.equal(closing.warned, true)
})

test("following a link with text in the paste box holds the visit", () => {
  const paste = { name: "pasted_theme", value: "", type: "textarea" }
  const editor = sectionLoadedWith({}, {}, [paste])
  paste.value = ":root { --primary: #1f5fbf; }"
  const leaving = visit()

  editor.confirmLeave(leaving)

  assert.equal(leaving.held, true)
})

test("following a link with only spaces in the paste box is not held", () => {
  const editor = sectionLoadedWith({}, {}, [{ name: "pasted_theme", value: "  \n", type: "textarea" }])
  const leaving = visit()

  editor.confirmLeave(leaving)

  assert.equal(leaving.held, false)
})

function switchOf(name, checked) {
  return { name, value: "1", type: "checkbox", checked }
}

test("following a link after turning off a Members choose switch holds the visit", () => {
  const members = switchOf("members_choose", true)
  const editor = sectionLoadedWith({}, {}, [{ name: "members_choose", value: "0", type: "hidden" }, members])
  members.checked = false
  const leaving = visit()

  editor.confirmLeave(leaving)

  assert.equal(leaving.held, true)
})

test("following a link after turning on the Members choose their own look switch holds the visit", () => {
  const members = switchOf("members_choose_look", false)
  const editor = sectionLoadedWith({}, {}, [{ name: "members_choose_look", value: "0", type: "hidden" }, members])
  members.checked = true
  const leaving = visit()

  editor.confirmLeave(leaving)

  assert.equal(leaving.held, true)
})

test("following a link after turning a Members choose switch off and on again is not held", () => {
  const members = switchOf("members_choose", true)
  const editor = sectionLoadedWith({}, {}, [{ name: "members_choose", value: "0", type: "hidden" }, members])
  members.checked = false
  members.checked = true
  const leaving = visit()

  editor.confirmLeave(leaving)

  assert.equal(leaving.held, false)
})
