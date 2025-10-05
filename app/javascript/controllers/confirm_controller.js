import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]


  show(event) {
    event.preventDefault()
    this.form = event.target.closest("form")
    this.modalTarget.classList.remove("hidden")
    console.log("I'm here")
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
