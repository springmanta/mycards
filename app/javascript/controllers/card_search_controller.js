import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "hidden", "quantity", "submit"]

  // Use a regular property instead of a Stimulus value
  selectedCard = null
  modalElement = null
  cardVersions = []
  selectedVersion = null

  connect() {
    console.log("✅ Connected to card-search controller")
    // ⛔ DO NOT use `data` here — it doesn't exist yet
  }

  // Create and show modal with card details
  showCardModal(card, cardTile) {
    // Remove any existing modal
    this.closeModal()

    // Set the initial selected version
    this.selectedVersion = card

    // Create modal elements
    const overlay = document.createElement('div')
    overlay.classList.add('card-modal-overlay')

    const modal = document.createElement('div')
    modal.classList.add('card-modal')

    // Create modal header
    const header = document.createElement('div')
    header.classList.add('card-modal-header')

    const title = document.createElement('h2')
    title.classList.add('card-modal-title')
    title.textContent = 'Confirm Card Import'

    const closeBtn = document.createElement('button')
    closeBtn.classList.add('card-modal-close')
    closeBtn.innerHTML = '&times;'
    closeBtn.addEventListener('click', () => this.closeModal())

    header.appendChild(title)
    header.appendChild(closeBtn)

    // Create modal content
    const content = document.createElement('div')
    content.classList.add('card-modal-content')

    const image = document.createElement('img')
    image.classList.add('card-modal-image')
    image.id = 'card-version-image'
    image.src = card.image
    image.alt = card.name

    const details = document.createElement('div')
    details.classList.add('card-modal-details')
    details.innerHTML = `<h3>${card.name}</h3>`

    // Create version selector
    const versionContainer = document.createElement('div')
    versionContainer.classList.add('card-modal-version-container')

    const versionLabel = document.createElement('label')
    versionLabel.textContent = 'Card Version:'
    versionLabel.classList.add('card-modal-label')

    const versionSelect = document.createElement('select')
    versionSelect.classList.add('card-modal-select')
    versionSelect.id = 'version-select'

    // Add loading option
    const loadingOption = document.createElement('option')
    loadingOption.textContent = 'Loading versions...'
    loadingOption.disabled = true
    loadingOption.selected = true
    versionSelect.appendChild(loadingOption)

    // Add event listener to version select
    versionSelect.addEventListener('change', (e) => {
      const selectedId = e.target.value
      const selectedVersion = this.cardVersions.find(v => v.id === selectedId)
      if (selectedVersion) {
        this.selectedVersion = selectedVersion
        this.hiddenTarget.value = selectedVersion.id

        // Update the image
        const versionImage = document.getElementById('card-version-image')
        if (versionImage) {
          versionImage.src = selectedVersion.image
        }

        // Update version details
        const versionDetails = document.getElementById('version-details')
        if (versionDetails) {
          versionDetails.innerHTML = `
            <p>Set: ${selectedVersion.set_name} (${selectedVersion.set})</p>
            <p>Collector Number: ${selectedVersion.collector_number}</p>
            <p>Rarity: ${selectedVersion.rarity}</p>
            <p>Artist: ${selectedVersion.artist}</p>
          `
        }
      }
    })

    versionContainer.appendChild(versionLabel)
    versionContainer.appendChild(versionSelect)

    // Create version details
    const versionDetails = document.createElement('div')
    versionDetails.classList.add('card-modal-version-details')
    versionDetails.id = 'version-details'

    // Create quantity selector
    const quantityContainer = document.createElement('div')
    quantityContainer.classList.add('card-modal-quantity-container')

    const quantityLabel = document.createElement('label')
    quantityLabel.textContent = 'Quantity:'
    quantityLabel.classList.add('card-modal-label')

    const quantityInput = document.createElement('input')
    quantityInput.type = 'number'
    quantityInput.min = '1'
    quantityInput.value = '1'
    quantityInput.classList.add('card-modal-quantity')

    // Update hidden quantity field when input changes
    quantityInput.addEventListener('change', (e) => {
      const quantity = parseInt(e.target.value, 10)
      if (quantity > 0) {
        this.quantityTarget.value = quantity
      } else {
        quantityInput.value = '1'
        this.quantityTarget.value = 1
      }
    })

    quantityContainer.appendChild(quantityLabel)
    quantityContainer.appendChild(quantityInput)

    // Create modal actions
    const actions = document.createElement('div')
    actions.classList.add('card-modal-actions')

    // Create a new submit button for the modal
    const submitBtn = document.createElement('button')
    submitBtn.type = 'submit'
    submitBtn.classList.add('btn-import')
    submitBtn.textContent = 'Import Card'

    // Add click handler to submit the form
    submitBtn.addEventListener('click', (e) => {
      e.preventDefault()
      // Submit the form
      this.element.submit()
      // Close the modal
      this.closeModal()
    })

    actions.appendChild(submitBtn)

    // Assemble modal
    content.appendChild(image)
    content.appendChild(details)
    content.appendChild(versionContainer)
    content.appendChild(versionDetails)
    content.appendChild(quantityContainer)
    content.appendChild(actions)

    modal.appendChild(header)
    modal.appendChild(content)
    overlay.appendChild(modal)

    // Add modal to the page
    document.body.appendChild(overlay)
    this.modalElement = overlay

    // Add event listener to close modal when clicking outside
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) {
        this.closeModal()
      }
    })

    // Fetch card versions
    this.fetchCardVersions(card.name, versionSelect)
  }

  // Fetch different versions of a card
  fetchCardVersions(cardName, versionSelect) {
    fetch(`/cards/versions?name=${encodeURIComponent(cardName)}`)
      .then(res => res.json())
      .then(data => {
        console.log("📦 Got versions:", data)

        if (!Array.isArray(data)) {
          console.error("❌ Versions data is not an array:", data)
          return
        }

        // Store versions
        this.cardVersions = data

        // Clear loading option
        versionSelect.innerHTML = ''

        // Add options for each version
        data.forEach(version => {
          const option = document.createElement('option')
          option.value = version.id
          option.textContent = `${version.set_name} (#${version.collector_number})`

          // Select the current version if it matches
          if (version.id === this.selectedVersion.id) {
            option.selected = true

            // Update version details
            const versionDetails = document.getElementById('version-details')
            if (versionDetails) {
              versionDetails.innerHTML = `
                <p>Set: ${version.set_name} (${version.set})</p>
                <p>Collector Number: ${version.collector_number}</p>
                <p>Rarity: ${version.rarity}</p>
                <p>Artist: ${version.artist}</p>
              `
            }
          }

          versionSelect.appendChild(option)
        })
      })
      .catch(err => {
        console.error("❌ Fetch versions failed:", err)

        // Show error in select
        versionSelect.innerHTML = ''
        const errorOption = document.createElement('option')
        errorOption.textContent = 'Error loading versions'
        errorOption.disabled = true
        errorOption.selected = true
        versionSelect.appendChild(errorOption)
      })
  }

  // Close and remove the modal
  closeModal() {
    if (this.modalElement) {
      document.body.removeChild(this.modalElement)
      this.modalElement = null
    }
  }

  search() {
    const query = this.inputTarget.value.trim()
    if (query.length < 2) {
      this.resultsTarget.innerHTML = ""
      return
    }

    fetch(`/cards/search?q=${encodeURIComponent(query)}`)
    .then(res => res.json())
    .then(data => {
    console.log("📦 Got data:", data)

    if (!Array.isArray(data)) {
      console.error("❌ Data is not an array:", data)
      return
    }

    this.resultsTarget.innerHTML = ""

    data.forEach(card => {
      const cardTile = document.createElement("div")
      cardTile.classList.add("card-tile") // Optional: if you use this in your CSS

      cardTile.innerHTML = `
        <img src="${card.image}" alt="${card.name}" class="card-image" />
      `

      cardTile.addEventListener("click", () => {
        // Check if this card is already selected
        const isAlreadySelected = this.selectedCard === cardTile;

        // If clicking on already selected card, unselect it
        if (isAlreadySelected) {
          // Clear the selection
          cardTile.classList.remove('card-selected')
          this.selectedCard = null
          this.inputTarget.value = ''
          this.hiddenTarget.value = ''

          // Close the modal if it's open
          this.closeModal()
        } else {
          // Set the form values
          this.inputTarget.value = card.name
          this.hiddenTarget.value = card.id

          // Remove selected class from previously selected card
          if (this.selectedCard) {
            this.selectedCard.classList.remove('card-selected')
          }

          // Add selected class to current card
          cardTile.classList.add('card-selected')

          // Update the selected card value
          this.selectedCard = cardTile

          // Show the modal with card details
          this.showCardModal(card, cardTile)
        }
      })

      this.resultsTarget.appendChild(cardTile)
    })
  })
  .catch(err => {
    console.error("❌ Fetch failed:", err)
  })
  }
}
