import { Controller } from "@hotwired/stimulus"

const storageKey = "todo.fontSize"

export default class extends Controller {
  static targets = ["option"]

  connect() {
    try {
      const saved = localStorage.getItem(storageKey)
      const option = this.optionTargets.find(input => input.value === saved)
      if (option) option.checked = true
    } catch {
      // 保存領域を使えない場合も、この画面内ではサイズを変更できる。
    }
  }

  save(event) {
    try {
      localStorage.setItem(storageKey, event.target.value)
    } catch {
      // 次の画面への引き継ぎは、保存できるブラウザーでのみ行う。
    }
  }
}
