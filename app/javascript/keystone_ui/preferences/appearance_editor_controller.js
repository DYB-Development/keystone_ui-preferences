import { Controller } from "@hotwired/stimulus"

const THEME_FIELD = /^theme\[([^\]]+)\]\[(light|dark)\]$/
const ENDS_DECLARATION = /[;{}]/
const QUICK_CHOICES = "[name='template_name'], [name='accent'], [name='surface'], [name='text']"
const PROPERTY_FOR_KIND = { colour: "color", length: "width", letter_spacing: "letter-spacing", font_list: "font-family", weight: "font-weight" }

export default class extends Controller {
  static targets = ["accentPicker", "surfacePicker", "textPicker", "customRadio", "templateLabel"]

  #setVariables = new Set()
  #loadedChoices = []
  #heldUrl = null
  #leaveAllowed = false

  connect() {
    this.#loadedChoices = this.#quickChoices()
    this.colorPickerTargets().forEach(picker => picker.addEventListener("change", () => this.customColorChanged()))
    this.#writeExport()
    this.#drawUnsavedFields()
  }

  confirmLeave(event) {
    if (!this.#hasUnsavedChanges()) return

    event.preventDefault()
    this.#heldUrl = event.detail.url
    this.element.querySelector("[data-leave-question] [data-modal-target='backdrop']").classList.remove("hidden")
  }

  warnBeforeUnload(event) {
    if (this.#hasUnsavedChanges()) event.preventDefault()
  }

  save() {
    this.#leaveAllowed = true
  }

  leave() {
    this.#leaveAllowed = true
    this.element.ownerDocument.defaultView.Turbo.visit(this.#heldUrl)
  }

  disconnect() {
    this.#setVariables.forEach(variable => this.#rootStyle().removeProperty(variable))
    this.#setVariables.clear()
  }

  apply({ target: { name, value } }) {
    this.#writeExport()
    const field = name.match(THEME_FIELD)
    if (!field) return

    const [, role, side] = field
    const { kind, variables, hover } = this.#roles()[role]
    const suffix = side === "dark" ? "-dark" : ""
    if (value === "") {
      [...variables, hover].filter(Boolean).forEach(variable => this.#remove(`${variable}${suffix}`))
      return
    }
    if (!CSS.supports(PROPERTY_FOR_KIND[kind], value)) return

    variables.forEach(variable => this.#set(`${variable}${suffix}`, value))
    if (hover) this.#set(`${hover}${suffix}`, `color-mix(in oklab, ${value} 85%, white)`)
  }

  colorPickerTargets() {
    return [
      this.hasAccentPickerTarget && this.accentPickerTarget,
      this.hasSurfacePickerTarget && this.surfacePickerTarget,
      this.hasTextPickerTarget && this.textPickerTarget
    ].filter(Boolean)
  }

  selectTemplate(event) {
    const input = event.currentTarget
    const label = input.closest("[data-template]")
    const accentHex = input.dataset.accentHex
    const surfaceHex = input.dataset.surfaceHex
    const textHex = input.dataset.textHex

    this.setPickerValue(this.accentPickerTarget, accentHex)
    this.setPickerValue(this.surfacePickerTarget, surfaceHex)
    this.setPickerValue(this.textPickerTarget, textHex)

    this.highlightTemplate(label.dataset.template)
  }

  selectPreset(event) {
    const input = event.currentTarget
    const theme = JSON.parse(input.dataset.theme)

    Object.entries(theme).forEach(([role, sides]) => {
      Object.entries(sides).forEach(([side, value]) => this.setThemeField(`theme[${role}][${side}]`, value))
    })

    this.highlightTemplate(input.closest("[data-template]").dataset.template)
  }

  reset() {
    const preset = this.element.querySelector("input[name='template_name'][data-theme]:checked")
    const theme = JSON.parse(preset ? preset.dataset.theme : this.element.querySelector("[data-saved-theme]").dataset.savedTheme)

    this.element.querySelectorAll("[name^='theme[']").forEach(({ name }) => {
      const [, role, side] = name.match(THEME_FIELD)
      this.setThemeField(name, theme[role]?.[side] ?? "")
    })
  }

  setThemeField(name, value) {
    const field = this.element.querySelector(`[name="${name}"]`)
    if (!field) return

    const picker = field.closest("[data-controller~='color-picker']")
    if (picker) {
      this.setPickerValue(picker, value)
    } else {
      field.value = value
    }
    field.dispatchEvent(new Event("change", { bubbles: true }))
  }

  showPanel({ detail: { index } }) {
    this.element.querySelectorAll("[data-editor-panel]").forEach((panel, place) => panel.toggleAttribute("data-shown", place === index))
  }

  customColorChanged() {
    if (this.hasCustomRadioTarget) this.customRadioTarget.checked = true
    this.highlightTemplate("custom")
  }

  highlightTemplate(selected) {
    this.templateLabelTargets.forEach(label => {
      const border = label.querySelector("span")
      if (label.dataset.template === selected) {
        border.classList.remove("border-transparent")
        border.classList.add("border-accent-500")
      } else {
        border.classList.remove("border-accent-500")
        border.classList.add("border-transparent")
      }
    })
  }

  setPickerValue(wrapper, hex) {
    const input = wrapper.querySelector("input[type='hidden']")
    const swatch = wrapper.querySelector("[data-color-picker-target='swatch']")
    const hexLabel = wrapper.querySelector("[data-color-picker-target='hexLabel']")
    const text = wrapper.querySelector("[data-color-picker-target='text']")

    if (input) input.value = hex
    if (swatch) swatch.style.backgroundColor = hex
    if (hexLabel) hexLabel.textContent = hex
    if (text) text.value = hex
  }

  #writeExport() {
    const exported = this.element.querySelector("[data-theme-export]")
    if (!exported) return

    const roles = Object.keys(this.#roles())
    const block = side => roles.flatMap(role => {
      const field = this.element.querySelector(`[name="theme[${role}][${side}]"]`)
      return field?.value && !ENDS_DECLARATION.test(field.value) ? [`  --${role}: ${field.value};\n`] : []
    }).join("")
    const css = `:root {\n${block("light")}}\n\n.dark {\n${block("dark")}}\n`
    exported.value = css
    this.element.querySelector("[data-controller~='clipboard']").dataset.clipboardText = css
  }

  #drawUnsavedFields() {
    this.#unsavedFields().forEach(field => this.apply({ target: field }))
  }

  #unsavedFields() {
    const saved = this.#savedTheme()
    return [...this.element.querySelectorAll("[name^='theme[']")].filter(field => {
      const [, role, side] = field.name.match(THEME_FIELD)
      return field.value !== (saved[role]?.[side] ?? "")
    })
  }

  #savedTheme() {
    return JSON.parse(this.element.querySelector("[data-saved-theme]")?.dataset.savedTheme ?? "{}")
  }

  #hasUnsavedChanges() {
    return !this.#leaveAllowed && (this.#unsavedFields().length > 0 || this.#quickChoicesChanged())
  }

  #quickChoicesChanged() {
    return this.#quickChoices().some((choice, place) => choice !== this.#loadedChoices[place])
  }

  #quickChoices() {
    return [...this.element.querySelectorAll(QUICK_CHOICES)].map(field => (field.type === "radio" ? field.checked : field.value))
  }

  #roles() {
    return JSON.parse(this.element.querySelector("[data-theme-roles]").dataset.themeRoles)
  }

  #set(variable, value) {
    this.#rootStyle().setProperty(variable, value)
    this.#setVariables.add(variable)
  }

  #remove(variable) {
    this.#rootStyle().removeProperty(variable)
    this.#setVariables.delete(variable)
  }

  #rootStyle() {
    return this.element.ownerDocument.documentElement.style
  }
}
