import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image", "price", "scryfallId", "cardId"]
  static values = {
    printings: Array
  }

  connect() {
    console.log("Card preview connected")
  }

  updateImage(event) {
    const selectedId = event.target.value
    const selectedPrinting = this.printingsValue.find(p =>
      String(p.id) === selectedId
    )

    if (selectedPrinting) {
      const imageUrl = selectedPrinting.image_uris?.normal ||
                       selectedPrinting.card_faces?.[0]?.image_uris?.normal ||
                       selectedPrinting.image_uri

      if (imageUrl && this.hasImageTarget) {
        this.imageTarget.src = imageUrl
      }

      if (this.hasScryfallIdTarget) {
        this.scryfallIdTarget.value = selectedId
      }

      if (this.hasCardIdTarget) {
        this.cardIdTarget.value = selectedId
      }

      if (this.hasPriceTarget) {
        const price = selectedPrinting.prices?.eur || selectedPrinting.eur_price
        const container = this.priceTarget.closest('[data-price-container]')

        if (price) {
          this.priceTarget.textContent = `€${parseFloat(price).toFixed(2)}`
          if (container) container.classList.remove('hidden')
        } else {
          this.priceTarget.textContent = ''
          if (container) container.classList.add('hidden')
        }
      }
    }
  }
}
