import UIKit
class VibrationManager {
var vibrationTimer: Timer?
var vibrationInterval: TimeInterval = 1.0 // 默认振动间隔为1秒

func startVibrating() {
    vibrationTimer?.invalidate() // 停止之前的振动
    vibrationTimer = Timer.scheduledTimer(timeInterval: vibrationInterval, target: self, selector: #selector(triggerVibration), userInfo: nil, repeats: true)
}

func updateVibrationInterval(_ interval: TimeInterval) {
    vibrationInterval = interval
    startVibrating() // 重启振动以应用新的振动间隔
}

func stopVibrating() {
    vibrationTimer?.invalidate()
    vibrationTimer = nil
}

@objc private func triggerVibration() {
    // 触发振动
    let generator = UIImpactFeedbackGenerator(style: .heavy)
    generator.prepare()
    generator.impactOccurred()
}
}
