import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modalContainer", "editButton"]
  static values = {
    cardId: Number,
    cardName: String
  }

  connect() {

    // Check if modalContainer is visible
    const modalContainerStyle = window.getComputedStyle(this.modalContainerTarget)
    // Add event listener for open-modal event
    this.element.addEventListener('open-modal', () => {
      console.log("🔔 open-modal event received")
      this.openModal()
    })

    // Find and attach event listener to edit button directly
    this.setupEditButton()
  }

  setupEditButton() {
    // Find the edit button within the controller's element
    const editButton = this.element.querySelector('.btn-update')
    if (editButton) {
      // Remove any existing event listeners
      const newEditButton = editButton.cloneNode(true)
      editButton.parentNode.replaceChild(newEditButton, editButton)

      // Add click event listener
      newEditButton.addEventListener('click', (event) => {
        event.preventDefault()
        console.log("🖱️ Edit button clicked directly")
        this.openModal()
      })
    } else {
      console.log("❓ No edit button found")
    }
  }

  disconnect() {
    this.closeModal()
  }

  openModal() {
    console.log("🔓 openModal method called")

    // Fetch card details
    fetch(`/cards/${this.cardIdValue}.json`)
      .then(response => {
        console.log("📥 Card details response received:", response)
        return response.json()
      })
      .then(card => {
        console.log("📋 Card details:", card)
        this.createModal(card)
      })
      .catch(error => {
        console.error("❌ Error fetching card details:", error)
      })
  }

  createModal(card) {
    console.log("🎨 Creating modal for card:", card.name)

    // Remove any existing modal
    this.closeModal()

    // Create modal elements
    const overlay = document.createElement('div')
    overlay.classList.add('card-modal-overlay')

    // Add inline styles to ensure visibility
    overlay.style.position = 'fixed';
    overlay.style.top = '0';
    overlay.style.left = '0';
    overlay.style.right = '0';
    overlay.style.bottom = '0';
    overlay.style.backgroundColor = 'rgba(0, 0, 0, 0.8)';
    overlay.style.display = 'flex';
    overlay.style.justifyContent = 'center';
    overlay.style.alignItems = 'center';
    overlay.style.zIndex = '10000';

    const modal = document.createElement('div')
    modal.classList.add('card-modal')

    // Add inline styles to ensure visibility
    modal.style.backgroundColor = 'white';
    modal.style.padding = '20px';
    modal.style.borderRadius = '10px';
    modal.style.maxWidth = '500px';
    modal.style.width = '90%';
    modal.style.boxShadow = '0 5px 15px rgba(0, 0, 0, 0.3)';

    // Create modal header
    const header = document.createElement('div')
    header.classList.add('card-modal-header')

    const title = document.createElement('h2')
    title.classList.add('card-modal-title')
    title.textContent = this.cardNameValue

    const closeBtn = document.createElement('button')
    closeBtn.classList.add('card-modal-close')
    closeBtn.innerHTML = '&times;'
    closeBtn.addEventListener('click', () => {
      this.closeModal()
    })

    header.appendChild(title)
    header.appendChild(closeBtn)

    // Create modal content
    const content = document.createElement('div')
    content.classList.add('card-modal-content')

    const image = document.createElement('img')
    image.classList.add('card-modal-image')
    image.id = 'card-version-image'
    image.src = card.photo_url || card.image_url
    image.alt = card.name

    // Add fixed dimensions to prevent image from shrinking when changing versions
    image.style.width = '200px';
    image.style.height = 'auto';
    image.style.minHeight = '280px';
    image.style.objectFit = 'contain';

    const details = document.createElement('div')
    details.classList.add('card-modal-details')

    // Create form for editing
    const form = document.createElement('form')
    form.action = `/cards/${this.cardIdValue}`
    form.method = 'post'

    // Add CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
    if (csrfToken) {
      const csrfInput = document.createElement('input')
      csrfInput.type = 'hidden'
      csrfInput.name = 'authenticity_token'
      csrfInput.value = csrfToken
      form.appendChild(csrfInput)
    }

    // Add method override for PUT
    const methodInput = document.createElement('input')
    methodInput.type = 'hidden'
    methodInput.name = '_method'
    methodInput.value = 'patch'
    form.appendChild(methodInput)

    // Create version selector
    const versionContainer = document.createElement('div')
    versionContainer.classList.add('card-modal-version-container')

    const versionLabel = document.createElement('label')
    versionLabel.textContent = 'Card Version:'
    versionLabel.classList.add('card-modal-label')

    const versionSelect = document.createElement('select')
    versionSelect.classList.add('card-modal-select')
    versionSelect.id = 'version-select'
    versionSelect.name = 'card[scryfall_id]'

    // Add loading option
    const loadingOption = document.createElement('option')
    loadingOption.textContent = 'Loading versions...'
    loadingOption.disabled = true
    loadingOption.selected = true
    versionSelect.appendChild(loadingOption)

    versionContainer.appendChild(versionLabel)
    versionContainer.appendChild(versionSelect)

    // Create version details
    const versionDetails = document.createElement('div')
    versionDetails.classList.add('card-modal-version-details')
    versionDetails.id = 'version-details'

    // Create a container for the quantity and submit button (side by side)
    const actionsRow = document.createElement('div')
    actionsRow.style.display = 'flex';
    actionsRow.style.justifyContent = 'space-between';
    actionsRow.style.alignItems = 'flex-end';
    actionsRow.style.width = '100%';
    actionsRow.style.marginTop = '20px';

    // Create quantity selector
    const quantityContainer = document.createElement('div')
    quantityContainer.classList.add('card-modal-quantity-container')
    quantityContainer.style.marginBottom = '0';
    quantityContainer.style.width = 'auto';

    const quantityLabel = document.createElement('label')
    quantityLabel.textContent = 'Quantity:'
    quantityLabel.classList.add('card-modal-label')

    const quantityInput = document.createElement('input')
    quantityInput.type = 'number'
    quantityInput.name = 'card[quantity]'
    quantityInput.min = '1'
    quantityInput.value = card.quantity || '1'
    quantityInput.classList.add('card-modal-quantity')

    quantityContainer.appendChild(quantityLabel)
    quantityContainer.appendChild(quantityInput)

    // Create modal actions
    const actions = document.createElement('div')
    actions.classList.add('card-modal-actions')
    actions.style.marginBottom = '0';
    actions.style.width = 'auto';

    // Create a submit button for the modal
    const submitBtn = document.createElement('button')
    submitBtn.type = 'submit'
    submitBtn.classList.add('.btn-update')
    submitBtn.textContent = 'Update Card'

    actions.appendChild(submitBtn)

    // Add quantity and submit button to the actions row
    actionsRow.appendChild(quantityContainer)
    actionsRow.appendChild(actions)

    // Assemble form
    form.appendChild(versionContainer)
    form.appendChild(versionDetails)
    form.appendChild(actionsRow)

    // Assemble modal
    content.appendChild(image)
    content.appendChild(details)
    content.appendChild(form)

    modal.appendChild(header)
    modal.appendChild(content)
    overlay.appendChild(modal)

    // Add modal directly to the document body instead of the modalContainer
    console.log("🎯 Adding modal directly to document body")

    document.body.appendChild(overlay)
    this.modalElement = overlay
    console.log("🖼️ Modal added to the page")

    // Add event listener to close modal when clicking outside
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) {
        this.closeModal()
      }
    })

    // Fetch card versions
    this.fetchCardVersions(card.name, versionSelect, card.scryfall_id)
  }

  fetchCardVersions(cardName, versionSelect, currentScryfallId) {
    fetch(`/cards/versions?name=${encodeURIComponent(cardName)}`)
      .then(res => res.json())
      .then(data => {
        console.log("📦 Got versions:", data)

        if (!Array.isArray(data)) {
          console.error("❌ Versions data is not an array:", data)
          return
        }

        // Clear loading option
        versionSelect.innerHTML = ''

        // Add options for each version
        data.forEach(version => {
          const option = document.createElement('option')
          option.value = version.id
          option.textContent = `${version.set_name}`

          // Select the current version if it matches
          if (version.id === currentScryfallId) {
            option.selected = true

            // Update version details
            const versionDetails = document.getElementById('version-details')
            if (versionDetails) {
              versionDetails.innerHTML = `
                <p><strong>Set:</strong> ${version.set_name} </p>
                <p><strong>Collector Number:</strong> ${version.collector_number}</p>
                <p><strong>Rarity:</strong> ${version.rarity}</p>
                <p><strong>Artist:</strong> ${version.artist}</p>
              `
            }
          }

          versionSelect.appendChild(option)
        })

        // Add event listener to version select
        versionSelect.addEventListener('change', (e) => {
          const selectedId = e.target.value
          const selectedVersion = data.find(v => v.id === selectedId)
          if (selectedVersion) {
            // Update the image while maintaining dimensions
            const versionImage = document.getElementById('card-version-image')
            if (versionImage) {
              // Store current dimensions
              const currentWidth = versionImage.style.width;
              const currentHeight = versionImage.style.height;
              const currentMinHeight = versionImage.style.minHeight;
              const currentObjectFit = versionImage.style.objectFit;

              // Update image source
              versionImage.src = selectedVersion.image;

              // Ensure dimensions are maintained
              versionImage.style.width = currentWidth;
              versionImage.style.height = currentHeight;
              versionImage.style.minHeight = currentMinHeight;
              versionImage.style.objectFit = currentObjectFit;
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

  closeModal() {
    if (this.modalElement) {
      this.modalElement.remove()
      this.modalElement = null
    }
  }
}
