import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "cardName"]

  show(event) {
    event.preventDefault()
    this.form = event.target.closest("form")

    if (this.hasCardNameTarget) {
      const cardName = event.target.dataset.cardName || "this card"
      this.cardNameTarget.textContent = cardName
    }
    this.modalTarget.classList.remove("hidden")
  }

  confirm() {
    if (this.form) {
      this.form.submit()
    }
  }

  cancel() {
    this.modalTarget.classList.add("hidden")
  }

  stopPropagation(event) {
    event.stopPropagation()
  }
}
