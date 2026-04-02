// WorkoutPlan.swift
// 训练计划常量 — 与 merach_combined.py 保持一致

import Foundation

// MARK: - 椭圆机参数
let kStrideLength: Double = 0.47   // 步距 47 cm

// MARK: - 训练阶段
struct WorkoutSegment {
    let name: String
    let resistance: Int
    let duration: Int  // 秒
}

// MARK: - 训练计划构建
private let _segResistances = [10, 15, 22, 30, 15, 22, 30]
private let _midSecs   = 40 * 60                               // 2400 s
private let _base      = _midSecs / _segResistances.count      // 342
private let _rem       = _midSecs - _base * _segResistances.count // 6

let workoutPlan: [WorkoutSegment] = {
    var plan: [WorkoutSegment] = [
        WorkoutSegment(name: "热身", resistance: 5, duration: 2 * 60)
    ]
    for (i, res) in _segResistances.enumerated() {
        let dur = _base + (i < _rem ? 1 : 0)
        plan.append(WorkoutSegment(name: "段\(i + 1)", resistance: res, duration: dur))
    }
    plan.append(WorkoutSegment(name: "放松", resistance: 5, duration: 3 * 60))
    return plan
}()

let kTotalSecs: Int = workoutPlan.reduce(0) { $0 + $1.duration }  // 2700

// MARK: - 阻力颜色映射
let resistanceColors: [Int: UIColor] = [
    5:  UIColor(hex: "#4caf50"),
    10: UIColor(hex: "#8bc34a"),
    15: UIColor(hex: "#ffeb3b"),
    22: UIColor(hex: "#ff9800"),
    30: UIColor(hex: "#f44336"),
]

// MARK: - 格式化工具
func formatTime(_ seconds: Double) -> String {
    let s = max(0, Int(seconds))
    return String(format: "%02d:%02d", s / 60, s % 60)
}

func formatPace(_ spm: Double) -> String {
    guard spm > 0 else { return "--'--\"" }
    let p = 1000.0 / (spm * 2.0 * kStrideLength)
    let m = Int(p)
    let s = Int((p - Double(m)) * 60.0)
    return "\(m)'\(String(format: "%02d", s))\""
}

// MARK: - UIColor hex 扩展
extension UIColor {
    convenience init(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h = String(h.dropFirst()) }
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        let r = CGFloat((rgb >> 16) & 0xFF) / 255
        let g = CGFloat((rgb >> 8)  & 0xFF) / 255
        let b = CGFloat( rgb        & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
