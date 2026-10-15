import { Controller } from "@hotwired/stimulus"

const THEME_FIELD = /^theme\[([^\]]+)\]\[(light|dark)\]$/

export default class extends Controller {
  static targets = ["accentPicker", "surfacePicker", "textPicker", "customRadio", "templateLabel"]

  connect() {
    this.colorPickerTargets().forEach(picker => picker.addEventListener("change", () => this.customColorChanged()))
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
    const theme = JSON.parse(preset.dataset.theme)

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
}
