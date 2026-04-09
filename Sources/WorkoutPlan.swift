// WorkoutPlan.swift
// 训练计划配置 — 支持多计划

import UIKit

// MARK: - 椭圆机参数
let kStrideLength: Double = 0.47   // 步距 47 cm

// MARK: - 阶段
struct WorkoutSegment {
    let name: String
    let resistance: Int
    let duration: Int   // 秒
}

// MARK: - 计划模式
enum PlanMode { case structured, free }

// MARK: - 计划配置
struct WorkoutPlanConfig {
    let id:          Int
    let name:        String
    let badge:       String
    let colorHex:    String
    let description: String
    let mode:        PlanMode
    let segments:    [WorkoutSegment]

    var isFree:         Bool { mode == .free }
    var totalSeconds:   Int  { segments.reduce(0) { $0 + $1.duration } }
}

// MARK: - 计划1：阶梯间歇（我的计划）
// 热身30s · R10/15/22/30/15/22/30 共40分钟 · 放松2分钟
private let _p1Res   = [10, 15, 22, 30, 15, 22, 30]
private let _p1Mid   = 40 * 60
private let _p1Base  = _p1Mid / _p1Res.count          // 342
private let _p1Rem   = _p1Mid - _p1Base * _p1Res.count // 6

private let _plan1Segs: [WorkoutSegment] = {
    var s = [WorkoutSegment(name: "热身", resistance: 5, duration: 30)]
    for (i, r) in _p1Res.enumerated() {
        s.append(WorkoutSegment(name: "段\(i+1)", resistance: r, duration: _p1Base + (i < _p1Rem ? 1 : 0)))
    }
    s.append(WorkoutSegment(name: "放松", resistance: 5, duration: 2 * 60))
    return s
}()

// MARK: - 计划2：爬坡保持（入门计划）
// 爬坡5分钟 R1→20（每步+3）· 保持R20 25分钟 · 放松2分钟 R20→1（每步-3）
private let _p2RampRes  = [1, 4, 7, 10, 13, 16, 19, 20]   // 8步
private let _p2RampBase = (5 * 60) / _p2RampRes.count      // 37
private let _p2RampRem  = (5 * 60) - _p2RampBase * _p2RampRes.count  // 4

private let _p2CoolRes  = [20, 17, 14, 11, 8, 5, 2, 1]    // 8步
private let _p2CoolBase = (2 * 60) / _p2CoolRes.count      // 15

private let _plan2Segs: [WorkoutSegment] = {
    var s: [WorkoutSegment] = []
    // 爬坡（前4步38s，后4步37s）
    for (i, r) in _p2RampRes.enumerated() {
        s.append(WorkoutSegment(name: "爬坡\(i+1)", resistance: r,
                                duration: _p2RampBase + (i < _p2RampRem ? 1 : 0)))
    }
    // 保持 R20 25分钟
    s.append(WorkoutSegment(name: "保持", resistance: 20, duration: 25 * 60))
    // 放松（每步15s，逐步降回R1）
    for (i, r) in _p2CoolRes.enumerated() {
        s.append(WorkoutSegment(name: "放松\(i+1)", resistance: r, duration: _p2CoolBase))
    }
    return s
}()

// MARK: - 全部计划
let allWorkoutPlans: [WorkoutPlanConfig] = [
    WorkoutPlanConfig(
        id: 0, name: "阶梯间歇", badge: "我的计划", colorHex: "#00d4ff",
        description: "热身30秒 · R10→15→22→30 阶梯×2 · 放松2分钟",
        mode: .structured, segments: _plan1Segs
    ),
    WorkoutPlanConfig(
        id: 1, name: "爬坡保持", badge: "入门计划", colorHex: "#00ff88",
        description: "R1→20 爬坡5分钟 · 保持R20 25分钟 · 放松2分钟降回R1",
        mode: .structured, segments: _plan2Segs
    ),
    WorkoutPlanConfig(
        id: 2, name: "实时监控", badge: "自由模式", colorHex: "#ce93d8",
        description: "仅显示实时数据，不执行训练计划，不自动调节阻力",
        mode: .free, segments: []
    ),
]

// MARK: - 阻力颜色（按阻力大小渐变：绿→黄→橙→红）
let resistanceColors: [Int: UIColor] = {
    var map: [Int: UIColor] = [:]
    for r in 1...32 {
        let t = Double(r - 1) / 31.0   // 0.0 (R1) → 1.0 (R32)
        let color: UIColor
        switch t {
        case 0..<0.25:  color = UIColor(hex: "#4caf50")   // 绿
        case 0.25..<0.5: color = UIColor(hex: "#ffeb3b")  // 黄
        case 0.5..<0.75: color = UIColor(hex: "#ff9800")  // 橙
        default:         color = UIColor(hex: "#f44336")  // 红
        }
        map[r] = color
    }
    return map
}()

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
