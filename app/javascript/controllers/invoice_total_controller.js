import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["quantity", "price", "total", "container", "template"]

  connect() {
    this.calculate()
  }

  addRow(event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.containerTarget.insertAdjacentHTML('beforeend', content)
  }

  removeRow(event) {
    event.preventDefault()
    const wrapper = event.target.closest('.nested-fields')
    if (wrapper.dataset.newRecord === "true") {
      wrapper.remove()
    } else {
      wrapper.style.display = 'none'
      wrapper.querySelector("input[name*='_destroy']").value = '1'
    }
    this.calculate()
  }

  calculate() {
    let grandTotal = 0
    this.quantityTargets.forEach((qtyField, index) => {
      const wrapper = qtyField.closest('.nested-fields')
      if (wrapper && wrapper.style.display !== 'none') {
        const priceField = this.priceTargets[index]
        const qty = parseFloat(qtyField.value) || 0
        const price = parseFloat(priceField.value) || 0
        grandTotal += (qty * price)
      }
    })

    if (this.hasTotalTarget) {
      this.totalTarget.innerHTML = new Intl.NumberFormat('en-US', {
        style: 'currency', currency: 'PKR'
      }).format(grandTotal)
    }
  }
}