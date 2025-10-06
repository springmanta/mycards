import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image"]
  static values = {
    printings: Array
  }

  connect() {
    console.log("Card preview connected")
    console.log("Printings data:", this.printingsValue)
  }

  updateImage(event) {
    const selectedId = event.target.value
    console.log("Selected ID:", selectedId)
    console.log("Looking in printings:", this.printingsValue)

    const selectedPrinting = this.printingsValue.find(p => p.id === selectedId)
    console.log("Found printing:", selectedPrinting)

    if (selectedPrinting) {
      const imageUrl = selectedPrinting.image_uris?.normal ||
                      selectedPrinting.card_faces?.[0]?.image_uris?.normal

      console.log("Image URL:", imageUrl)

      if (imageUrl && this.hasImageTarget) {
        this.imageTarget.src = imageUrl
        console.log("Image updated!")
      } else {
        console.log("No image URL found or no image target")
      }
    }
  }
}
