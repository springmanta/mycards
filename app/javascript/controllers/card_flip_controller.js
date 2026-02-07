import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image", "button"]
  static values = {
    front: String,
    back: String
  }

  connect() {
    this.showingFront = true
  }

  flip() {
    if (!this.backValue) return

    if (this.showingFront) {
      this.imageTarget.src = this.backValue
      this.buttonTarget.textContent = "Show Front"
    } else {
      this.imageTarget.src = this.frontValue
      this.buttonTarget.textContent = "Show Back"
    }

    this.showingFront = !this.showingFront
  }
}
