import { Controller } from "@hotwired/stimulus"

// 倒计时和自动刷新控制器
export default class extends Controller {
  static targets = ["countdown", "button", "lastRefreshed"]
  static values = { 
    url: String,             // 刷新请求的URL
    interval: { type: Number, default: 120 } // 倒计时秒数，默认60秒
  }

  connect() {
    console.log("Timer controller connected")
    
    // 设置初始倒计时值
    if (this.hasCountdownTarget) {
      this.countdownTarget.textContent = this.intervalValue
    }
    
    // 开始倒计时
    this.startCountdown()
  }

  disconnect() {
    // 清除定时器
    if (this.countdownTimer) {
      clearInterval(this.countdownTimer)
    }
  }

  // 开始倒计时
  startCountdown() {
    let seconds = this.intervalValue
    
    // 清除之前的定时器（如果存在）
    if (this.countdownTimer) {
      clearInterval(this.countdownTimer)
    }
    
    // 设置新的定时器
    this.countdownTimer = setInterval(() => {
      seconds -= 1
      
      // 更新倒计时显示
      if (this.hasCountdownTarget) {
        this.countdownTarget.textContent = seconds
      }
      
      // 当倒计时到0时，触发刷新
      if (seconds <= 0) {
        this.refresh()
        // 重新开始倒计时
        seconds = this.intervalValue
        if (this.hasCountdownTarget) {
          this.countdownTarget.textContent = seconds
        }
      }
    }, 1000) // 每秒更新一次
  }

  // 手动刷新（当用户点击刷新按钮时）  
  manualRefresh(event) {
    event.preventDefault()
    this.refresh()
    
    // 重置倒计时
    if (this.hasCountdownTarget) {
      this.countdownTarget.textContent = this.intervalValue
    }
    this.startCountdown()
  }

  // 执行刷新
  refresh() {
    if (!this.urlValue) {
      console.error("No URL provided for refresh action")
      return
    }
    
    // 禁用刷新按钮以防止重复点击
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = true
      this.buttonTarget.classList.add("opacity-50", "cursor-not-allowed")
    }
    
    // 发送刷新请求并触发页面重新加载
    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      },
      credentials: "same-origin"
    })
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP error! Status: ${response.status}`)
      }
      
      // 刷新整个页面而不是处理Turbo Stream
      window.location.reload()
    })
    .catch(error => {
      console.error("Error refreshing content:", error)
      // 出错时也可以选择刷新整个页面
      window.location.reload()
    })
    .finally(() => {
      // 重新启用刷新按钮
      if (this.hasButtonTarget) {
        this.buttonTarget.disabled = false
        this.buttonTarget.classList.remove("opacity-50", "cursor-not-allowed")
      }
    })
  }
}