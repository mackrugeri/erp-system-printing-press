// app/javascript/controllers/invoice_calc_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["qty", "price", "total", "grandTotal"]

  calculate() {
    let grand = 0
    
    // Loop through all line items
    this.qtyTargets.forEach((qtyField, index) => {
      const price = this.priceTargets[index].value || 0
      const qty = qtyField.value || 0
      const lineTotal = qty * price
      
      this.totalTargets[index].value = lineTotal.toFixed(2)
      grand += lineTotal
    })

    this.grandTotalTarget.value = grand.toFixed(2)
  }
}