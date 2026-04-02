// DashboardViewController.swift
// 主界面：状态栏 + 训练计划进度 + 4个指标图表
// UIKit 全程序化布局，兼容 iOS 10 + 横屏 iPad

import UIKit

class DashboardViewController: UIViewController {

    // MARK: - Engine
    private let engine = WorkoutEngine()

    // MARK: - UI
    private let statusBar    = UILabel()
    private let planView     = PlanProgressView()
    private let spmChart     = MetricChartView(title: "Cadence / SPM", unit: "spm",  color: UIColor(hex: "#00d4ff"))
    private let speedChart   = MetricChartView(title: "Speed",         unit: "km/h", color: UIColor(hex: "#00ff88"))
    private let powerChart   = MetricChartView(title: "Power",         unit: "W",    color: UIColor(hex: "#ff6b6b"))
    private let calChart     = MetricChartView(title: "Calories",      unit: "kcal", color: UIColor(hex: "#ffa726"))

    private let bgColor = UIColor(hex: "#1a1a2e")

    // MARK: - Demo flag (set before presenting)
    var demoMode = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        engine.delegate = self
        engine.start(demo: demoMode)
    }

    override var prefersStatusBarHidden: Bool { return true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = bgColor

        // ── 状态栏 ──
        statusBar.backgroundColor  = UIColor(hex: "#0d1b2a")
        statusBar.textColor        = .white
        statusBar.font             = UIFont.boldSystemFont(ofSize: 13)
        statusBar.textAlignment    = .center
        statusBar.text             = "Connecting…"
        statusBar.layer.cornerRadius  = 6
        statusBar.layer.masksToBounds = true
        view.addSubview(statusBar)

        // ── 训练计划进度条 ──
        view.addSubview(planView)

        // ── 4 个图表 ──
        [spmChart, speedChart, powerChart, calChart].forEach { view.addSubview($0) }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutDashboard()
    }

    private func layoutDashboard() {
        let p: CGFloat = 8
        let W = view.bounds.width
        let H = view.bounds.height

        let statusH: CGFloat = 36
        let planH:   CGFloat = 80
        let topH     = statusH + p + planH + p
        let chartH   = (H - topH - p) / 2
        let chartW   = (W - p * 3) / 2

        statusBar.frame = CGRect(x: p, y: p, width: W - p * 2, height: statusH)
        planView.frame  = CGRect(x: p, y: p + statusH + p,
                                 width: W - p * 2, height: planH)

        let chartTop1 = p + statusH + p + planH + p
        let chartTop2 = chartTop1 + chartH + p

        spmChart.frame   = CGRect(x: p,           y: chartTop1, width: chartW, height: chartH)
        speedChart.frame = CGRect(x: p * 2 + chartW, y: chartTop1, width: chartW, height: chartH)
        powerChart.frame = CGRect(x: p,           y: chartTop2, width: chartW, height: chartH)
        calChart.frame   = CGRect(x: p * 2 + chartW, y: chartTop2, width: chartW, height: chartH)
    }

    // MARK: - UI Refresh

    private func refreshUI() {
        let e = engine
        let spm     = e.spmHistory.last ?? 0
        let speed   = e.speedHistory.last ?? 0
        let pwr     = e.powerHistory.last ?? 0
        let cal     = e.calHistory.last ?? 0
        let res     = e.resistanceHistory.last ?? 0
        let dist    = e.distanceHistory.last ?? 0
        let steps   = e.stepsHistory.last ?? 0

        // ── 状态栏 ──
        if !e.isConnected {
            statusBar.text = "Connecting…"
        } else if e.workoutDone {
            statusBar.text = String(format: "训练完成！%@  步数 %d  距离 %.2fkm  %.0fkcal",
                                    formatTime(e.workoutElapsed), Int(steps), dist, cal)
        } else {
            let remain = max(0.0, Double(e.phaseTotal) - e.phaseElapsed)
            statusBar.text = String(format: "%@  |  %@ 剩余%@  |  SPM %d  |  %.1fkm/h  |  %@  |  %dW  |  %.0fkcal  |  阻力%d",
                                    formatTime(e.workoutElapsed),
                                    e.phaseName, formatTime(remain),
                                    Int(spm), speed, formatPace(spm),
                                    Int(pwr), cal, Int(res))
        }

        // ── 进度条 ──
        planView.currentSecs = e.workoutElapsed
        planView.phaseIndex  = e.phaseIndex
        let phaseRemain = max(0.0, Double(e.phaseTotal) - e.phaseElapsed)
        planView.updatePhaseLabel(name: e.phaseName, resistance: e.phaseResist,
                                  elapsed: e.phaseElapsed, remaining: phaseRemain)

        // ── SPM 图 ──
        spmChart.update(
            data: e.spmHistory,
            valueText: String(format: "%d", Int(spm)),
            subText: "Steps  \(Int(steps))"
        )

        // ── Speed 图 ──
        speedChart.update(
            data: e.speedHistory,
            valueText: String(format: "%.1f", speed),
            subText: "Pace  \(formatPace(spm))"
        )

        // ── Power 图 ──
        powerChart.update(
            data: e.powerHistory,
            valueText: String(format: "%d", Int(pwr)),
            subText: String(format: "Resist  Lv %d", Int(res))
        )

        // ── Calories 图 ──
        calChart.update(
            data: e.calHistory,
            valueText: String(format: "%d", Int(cal)),
            subText: String(format: "Dist  %.3f km", dist)
        )
    }
}

// MARK: - WorkoutEngineDelegate
extension DashboardViewController: WorkoutEngineDelegate {

    func engineDidConnect() {
        statusBar.text = "Connected — starting workout…"
    }

    func engineDidDisconnect() {
        statusBar.text = "Disconnected"
        statusBar.backgroundColor = UIColor(hex: "#b71c1c")
    }

    func engineDidTick() {
        refreshUI()
    }
}
