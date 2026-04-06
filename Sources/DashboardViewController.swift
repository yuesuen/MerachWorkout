// DashboardViewController.swift
// iPhone 6s 竖屏布局：顶部信息栏 + 阶段栏 + 3行×2列数值方格

import UIKit

class DashboardViewController: UIViewController {

    // MARK: - Engine
    private let engine = WorkoutEngine()
    var demoMode = false

    // MARK: - 颜色
    private let bgColor      = UIColor(hex: "#1a1a2e")
    private let cardColor    = UIColor(hex: "#16213e")
    private let topBarColor  = UIColor(hex: "#0d1b2a")

    // MARK: - 顶部综合栏
    private let topBar       = UIView()
    private let lblElapsed   = UILabel()   // 已用时
    private let lblResist    = UILabel()   // 当前阻力
    private let lblRemain    = UILabel()   // 总剩余

    // MARK: - 阶段栏
    private let phaseBar     = UIView()
    private let lblPhaseDot  = UIView()
    private let lblPhaseName = UILabel()
    private let lblPhaseRes  = UILabel()
    private let lblPhaseCD   = UILabel()   // 倒计时
    private let lblPhaseIdx  = UILabel()   // 第 X/9 段

    // MARK: - 数值方格（3行×2列）
    // row0: SPM | Steps
    private let boxSPM       = MetricBox(label: "SPM",      unit: "steps/min", color: UIColor(hex: "#00d4ff"))
    private let boxSteps     = MetricBox(label: "Steps",    unit: "total",     color: UIColor(hex: "#4dd0e1"))
    // row1: Speed | Pace
    private let boxSpeed     = MetricBox(label: "Speed",    unit: "km/h",      color: UIColor(hex: "#00ff88"))
    private let boxPace      = MetricBox(label: "Pace",     unit: "min/km",    color: UIColor(hex: "#00ff88"))
    // row2: Power | Calories
    private let boxPower     = MetricBox(label: "Power",    unit: "W",         color: UIColor(hex: "#ff6b6b"))
    private let boxCal       = MetricBox(label: "Calories", unit: "kcal",      color: UIColor(hex: "#ffa726"))

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        engine.delegate = self
        engine.start(demo: demoMode)
    }

    override var prefersStatusBarHidden: Bool { return true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    // MARK: - Build UI

    private func buildUI() {
        view.backgroundColor = bgColor

        // ── 顶部栏 ──
        topBar.backgroundColor    = topBarColor
        topBar.layer.cornerRadius = 10
        view.addSubview(topBar)

        lblElapsed.font      = UIFont.monospacedDigitSystemFont(ofSize: 28, weight: .bold)
        lblElapsed.textColor = UIColor(hex: "#00ff88")
        lblElapsed.text      = "--:--"

        let elapsedLabel = makeSmallLabel("已用时")
        let elapsedStack = vstack(elapsedLabel, lblElapsed)

        lblResist.font      = UIFont.boldSystemFont(ofSize: 26)
        lblResist.textColor = UIColor(hex: "#ffeb3b")
        lblResist.text      = "Lv --"
        lblResist.textAlignment = .center

        let resistLabel = makeSmallLabel("阻力")
        resistLabel.textAlignment = .center
        let resistStack = vstack(resistLabel, lblResist)
        resistStack.alignment = .center

        lblRemain.font      = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        lblRemain.textColor = UIColor(hex: "#ffa726")
        lblRemain.text      = "--:--"
        lblRemain.textAlignment = .right

        let remainLabel = makeSmallLabel("总剩余")
        remainLabel.textAlignment = .right
        let remainStack = vstack(remainLabel, lblRemain)
        remainStack.alignment = .trailing

        let topStack = UIStackView(arrangedSubviews: [elapsedStack, resistStack, remainStack])
        topStack.axis         = .horizontal
        topStack.distribution = .equalSpacing
        topStack.alignment    = .center
        topBar.addSubview(topStack)
        topStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topStack.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 14),
            topStack.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -14),
            topStack.topAnchor.constraint(equalTo: topBar.topAnchor, constant: 8),
            topStack.bottomAnchor.constraint(equalTo: topBar.bottomAnchor, constant: -8),
        ])

        // ── 阶段栏 ──
        phaseBar.backgroundColor    = cardColor
        phaseBar.layer.cornerRadius = 10
        view.addSubview(phaseBar)

        lblPhaseDot.layer.cornerRadius = 5
        lblPhaseDot.backgroundColor    = UIColor(hex: "#ffeb3b")
        phaseBar.addSubview(lblPhaseDot)

        lblPhaseName.font      = UIFont.boldSystemFont(ofSize: 15)
        lblPhaseName.textColor = .white
        lblPhaseName.text      = "--"
        phaseBar.addSubview(lblPhaseName)

        lblPhaseRes.font             = UIFont.systemFont(ofSize: 11)
        lblPhaseRes.textColor        = UIColor(hex: "#aaaaaa")
        lblPhaseRes.backgroundColor  = topBarColor
        lblPhaseRes.layer.cornerRadius = 4
        lblPhaseRes.layer.masksToBounds = true
        lblPhaseRes.textAlignment    = .center
        lblPhaseRes.text             = "R--"
        phaseBar.addSubview(lblPhaseRes)

        lblPhaseIdx.font      = UIFont.systemFont(ofSize: 11)
        lblPhaseIdx.textColor = UIColor(hex: "#888888")
        lblPhaseIdx.text      = "0 / 9"
        phaseBar.addSubview(lblPhaseIdx)

        lblPhaseCD.font      = UIFont.monospacedDigitSystemFont(ofSize: 26, weight: .bold)
        lblPhaseCD.textColor = UIColor(hex: "#ff6b6b")
        lblPhaseCD.text      = "--:--"
        lblPhaseCD.textAlignment = .right
        phaseBar.addSubview(lblPhaseCD)

        let cdLabel = makeSmallLabel("本段剩余")
        cdLabel.textAlignment = .right
        phaseBar.addSubview(cdLabel)

        // ── 方格 ──
        [boxSPM, boxSteps, boxSpeed, boxPace, boxPower, boxCal].forEach { view.addSubview($0) }

        // ── 连接提示 overlay（初始可见）──
        // 由 engineDidConnect 隐藏，暂不添加额外 view，直接用 lblElapsed 显示状态
    }

    // MARK: - Layout

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutAll()
    }

    private func layoutAll() {
        let safe  = view.safeAreaInsets
        let p: CGFloat = 10
        let W = view.bounds.width - safe.left - safe.right
        let x0 = safe.left + p
        var y = safe.top + p

        // 顶部栏
        let topH: CGFloat = 60
        topBar.frame = CGRect(x: x0, y: y, width: W - 2*p, height: topH)
        y += topH + p

        // 阶段栏
        let phaseH: CGFloat = 52
        phaseBar.frame = CGRect(x: x0, y: y, width: W - 2*p, height: phaseH)
        layoutPhaseBar(in: phaseBar.bounds)
        y += phaseH + p

        // 剩余高度平均分配给 3 行
        let remaining = view.bounds.height - safe.bottom - y - p
        let rowH = (remaining - 2*p) / 3
        let colW = (W - 2*p - p) / 2

        let rows: [[MetricBox]] = [[boxSPM, boxSteps], [boxSpeed, boxPace], [boxPower, boxCal]]
        for (ri, row) in rows.enumerated() {
            let rowY = y + CGFloat(ri) * (rowH + p)
            for (ci, box) in row.enumerated() {
                let colX = x0 + CGFloat(ci) * (colW + p)
                box.frame = CGRect(x: colX, y: rowY, width: colW, height: rowH)
            }
        }
    }

    private func layoutPhaseBar(in bounds: CGRect) {
        let p: CGFloat = 10
        let h = bounds.height

        // 左侧：dot + name + resist tag + idx
        lblPhaseDot.frame = CGRect(x: p, y: (h-10)/2, width: 10, height: 10)
        lblPhaseName.frame = CGRect(x: p+14, y: (h-20)/2, width: 80, height: 20)
        lblPhaseRes.frame  = CGRect(x: p+14+84, y: (h-18)/2, width: 36, height: 18)
        lblPhaseIdx.frame  = CGRect(x: p+14+84+40, y: (h-16)/2, width: 60, height: 16)

        // 右侧：countdown + label
        let W = bounds.width
        lblPhaseCD.frame = CGRect(x: W-90-p, y: (h-30)/2-2, width: 90, height: 30)

        // small label above countdown
        for sub in phaseBar.subviews {
            if let lbl = sub as? UILabel, lbl.text == "本段剩余" {
                lbl.frame = CGRect(x: W-90-p, y: 4, width: 90, height: 14)
            }
        }
    }

    // MARK: - Helpers

    private func makeSmallLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text      = text
        l.font      = UIFont.systemFont(ofSize: 10)
        l.textColor = UIColor(hex: "#888888")
        return l
    }

    private func vstack(_ a: UIView, _ b: UIView) -> UIStackView {
        let s = UIStackView(arrangedSubviews: [a, b])
        s.axis    = .vertical
        s.spacing = 2
        s.alignment = .leading
        return s
    }

    // MARK: - Refresh

    private func refreshUI() {
        let e    = engine
        let spm  = e.spmHistory.last   ?? 0
        let spd  = e.speedHistory.last ?? 0
        let pwr  = e.powerHistory.last ?? 0
        let cal  = e.calHistory.last   ?? 0
        let steps = e.stepsHistory.last ?? 0

        let totalRemain = max(0.0, Double(kTotalSecs) - e.workoutElapsed)
        let phaseRemain = max(0.0, Double(e.phaseTotal) - e.phaseElapsed)

        // ── 顶部栏 ──
        lblElapsed.text = formatTime(e.workoutElapsed)
        lblResist.text  = "Lv \(e.currentData.currentResistance)"
        lblRemain.text  = formatTime(totalRemain)

        // ── 阶段栏 ──
        lblPhaseName.text = e.phaseName.isEmpty ? "--" : e.phaseName
        lblPhaseRes.text  = "R\(e.phaseResist)"
        lblPhaseCD.text   = formatTime(phaseRemain)
        lblPhaseIdx.text  = "\(e.phaseIndex + 1) / \(workoutPlan.count)"

        // 阶段颜色
        if let color = resistanceColors[e.phaseResist] {
            lblPhaseDot.backgroundColor = color
            lblPhaseRes.textColor       = color
        }

        // ── 方格 ──
        boxSPM.setValue(String(Int(spm)))
        boxSteps.setValue(formatInt(Int(steps)))
        boxSpeed.setValue(String(format: "%.1f", spd))
        boxPace.setValue(formatPace(spm))
        boxPower.setValue(String(Int(pwr)))
        boxCal.setValue(String(Int(cal)))
    }

    private func formatInt(_ n: Int) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        return nf.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}

// MARK: - WorkoutEngineDelegate

extension DashboardViewController: WorkoutEngineDelegate {

    func engineDidConnect() {
        lblElapsed.text = "00:00"
        lblRemain.text  = formatTime(Double(kTotalSecs))
    }

    func engineDidDisconnect() {
        lblElapsed.text      = "ERR"
        lblElapsed.textColor = UIColor(hex: "#ff6b6b")
    }

    func engineDidTick() {
        refreshUI()
    }
}

// MARK: - MetricBox

private class MetricBox: UIView {

    private let labelLbl = UILabel()
    private let valueLbl = UILabel()
    private let unitLbl  = UILabel()
    private let accent: UIColor

    init(label: String, unit: String, color: UIColor) {
        self.accent = color
        super.init(frame: .zero)
        backgroundColor    = UIColor(hex: "#16213e")
        layer.cornerRadius = 12

        labelLbl.text      = label
        labelLbl.font      = UIFont.systemFont(ofSize: 12)
        labelLbl.textColor = UIColor(hex: "#888888")
        labelLbl.textAlignment = .center

        valueLbl.text      = "--"
        valueLbl.font      = UIFont.monospacedDigitSystemFont(ofSize: 40, weight: .bold)
        valueLbl.textColor = color
        valueLbl.textAlignment = .center
        valueLbl.adjustsFontSizeToFitWidth = true
        valueLbl.minimumScaleFactor = 0.5

        unitLbl.text      = unit
        unitLbl.font      = UIFont.systemFont(ofSize: 11)
        unitLbl.textColor = UIColor(hex: "#666666")
        unitLbl.textAlignment = .center

        [labelLbl, valueLbl, unitLbl].forEach { addSubview($0) }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let W = bounds.width
        let H = bounds.height
        labelLbl.frame = CGRect(x: 4, y: 8,        width: W-8, height: 16)
        valueLbl.frame = CGRect(x: 4, y: 24,       width: W-8, height: H-48)
        unitLbl.frame  = CGRect(x: 4, y: H-20,     width: W-8, height: 16)
    }

    func setValue(_ text: String) {
        valueLbl.text = text
    }
}
