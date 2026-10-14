import { Controller } from "@hotwired/stimulus"

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

    if (input) input.value = hex
    if (swatch) swatch.style.backgroundColor = hex
    if (hexLabel) hexLabel.textContent = hex
  }
}
