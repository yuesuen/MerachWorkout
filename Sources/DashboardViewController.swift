// DashboardViewController.swift
// iPhone 6s 横屏布局：单顶栏（5块）+ 2行×3列数值方格 + 底部留空28pt

import UIKit

class DashboardViewController: UIViewController {

    // MARK: - Engine
    private let engine = WorkoutEngine()
    var demoMode = false

    // MARK: - Colors
    private let bgColor     = UIColor(hex: "#1a1a2e")
    private let cardColor   = UIColor(hex: "#16213e")
    private let topBarColor = UIColor(hex: "#0d1b2a")

    // MARK: - Top bar
    private let topBar = UIView()

    private let lblElapsedTitle = makeLabel("已用时", size: 10, color: "#888888")
    private let lblElapsed      = UILabel()

    private let lblResistTitle  = makeLabel("阻力",   size: 10, color: "#888888")
    private let lblResist       = UILabel()

    private let phaseDot        = UIView()
    private let lblPhaseName    = UILabel()
    private let lblPhaseRes     = UILabel()
    private let lblPhaseIdx     = UILabel()

    private let lblCDTitle      = makeLabel("本段剩余", size: 10, color: "#888888")
    private let lblPhaseCD      = UILabel()

    private let lblRemainTitle  = makeLabel("总剩余",  size: 10, color: "#888888")
    private let lblRemain       = UILabel()

    private var dividers: [UIView] = []

    // MARK: - Metric boxes (row0: SPM | Speed | Power, row1: Steps | Pace | Cal)
    private let boxSPM   = MetricBox(label: "SPM",      unit: "steps/min", color: UIColor(hex: "#00d4ff"))
    private let boxSpeed = MetricBox(label: "Speed",    unit: "km/h",      color: UIColor(hex: "#00ff88"))
    private let boxPower = MetricBox(label: "Power",    unit: "W",         color: UIColor(hex: "#ff6b6b"))
    private let boxSteps = MetricBox(label: "Steps",    unit: "total",     color: UIColor(hex: "#4dd0e1"))
    private let boxPace  = MetricBox(label: "Pace",     unit: "min/km",    color: UIColor(hex: "#00ff88"))
    private let boxCal   = MetricBox(label: "Calories", unit: "kcal",      color: UIColor(hex: "#ffa726"))

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        engine.delegate = self
        engine.start(demo: demoMode)
    }

    override var prefersStatusBarHidden: Bool { return true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    // MARK: - Build UI

    private func buildUI() {
        view.backgroundColor = bgColor

        // Top bar
        topBar.backgroundColor    = topBarColor
        topBar.layer.cornerRadius = 10
        view.addSubview(topBar)

        // Elapsed
        lblElapsed.font      = UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .bold)
        lblElapsed.textColor = UIColor(hex: "#00ff88")
        lblElapsed.text      = "--:--"

        // Resistance
        lblResist.font          = UIFont.boldSystemFont(ofSize: 20)
        lblResist.textColor     = UIColor(hex: "#ffeb3b")
        lblResist.text          = "Lv --"
        lblResist.textAlignment = .center

        // Phase dot
        phaseDot.layer.cornerRadius = 4
        phaseDot.backgroundColor    = UIColor(hex: "#ffeb3b")

        // Phase name
        lblPhaseName.font      = UIFont.boldSystemFont(ofSize: 13)
        lblPhaseName.textColor = .white
        lblPhaseName.text      = "--"

        // Phase resist tag
        lblPhaseRes.font                 = UIFont.systemFont(ofSize: 10)
        lblPhaseRes.textColor            = UIColor(hex: "#ffeb3b")
        lblPhaseRes.backgroundColor      = UIColor(hex: "#1a1a2e")
        lblPhaseRes.layer.cornerRadius   = 3
        lblPhaseRes.layer.masksToBounds  = true
        lblPhaseRes.textAlignment        = .center
        lblPhaseRes.text                 = "R--"

        // Phase index
        lblPhaseIdx.font      = UIFont.systemFont(ofSize: 10)
        lblPhaseIdx.textColor = UIColor(hex: "#888888")
        lblPhaseIdx.text      = "0 / 9"

        // Phase countdown
        lblPhaseCD.font          = UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .bold)
        lblPhaseCD.textColor     = UIColor(hex: "#ff6b6b")
        lblPhaseCD.text          = "--:--"
        lblPhaseCD.textAlignment = .center

        // Total remain
        lblRemain.font          = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .bold)
        lblRemain.textColor     = UIColor(hex: "#ffa726")
        lblRemain.text          = "--:--"
        lblRemain.textAlignment = .right

        [lblElapsedTitle, lblElapsed,
         lblResistTitle,  lblResist,
         phaseDot, lblPhaseName, lblPhaseRes, lblPhaseIdx,
         lblCDTitle, lblPhaseCD,
         lblRemainTitle, lblRemain].forEach { topBar.addSubview($0) }

        // 4 dividers
        for _ in 0..<4 {
            let d = UIView()
            d.backgroundColor = UIColor(hex: "#2a3a4a")
            topBar.addSubview(d)
            dividers.append(d)
        }

        // Metric boxes
        [boxSPM, boxSpeed, boxPower, boxSteps, boxPace, boxCal].forEach { view.addSubview($0) }
    }

    // MARK: - Layout

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutAll()
    }

    private func layoutAll() {
        let safe      = view.safeAreaInsets
        let p: CGFloat     = 8
        let bottomPad: CGFloat = 28   // 卡槽遮挡预留

        let x0 = safe.left + p
        let y0 = safe.top  + p
        let W  = view.bounds.width  - safe.left - safe.right - 2*p
        let H  = view.bounds.height - safe.top  - safe.bottom

        // Top bar
        let topH: CGFloat = 54
        topBar.frame = CGRect(x: x0, y: y0, width: W, height: topH)
        layoutTopBar(bounds: topBar.bounds)

        // Grid
        let gridY = y0 + topH + p
        let gridH = H - (topH + p) - p - bottomPad
        let rowH  = (gridH - p) / 2
        let colW  = (W - 2*p) / 3

        let rows: [[MetricBox]] = [[boxSPM, boxSpeed, boxPower],
                                   [boxSteps, boxPace, boxCal]]
        for (ri, row) in rows.enumerated() {
            let rowY = gridY + CGFloat(ri) * (rowH + p)
            for (ci, box) in row.enumerated() {
                let colX = x0 + CGFloat(ci) * (colW + p)
                box.frame = CGRect(x: colX, y: rowY, width: colW, height: rowH)
            }
        }
    }

    private func layoutTopBar(bounds: CGRect) {
        let W = bounds.width
        let H = bounds.height
        let p: CGFloat = 10

        // Fixed widths for each section
        let w0: CGFloat = 76   // elapsed
        let w1: CGFloat = 66   // resistance
        let w3: CGFloat = 76   // countdown
        let w4: CGFloat = 72   // remain
        let dW: CGFloat = 1    // divider
        let phaseW = W - w0 - w1 - w3 - w4 - 4*(dW + p*2) - 2*p

        var x = p

        // 1. Elapsed
        lblElapsedTitle.frame = CGRect(x: x, y: 6,       width: w0, height: 12)
        lblElapsed.frame      = CGRect(x: x, y: H/2 - 2, width: w0, height: 26)
        x += w0 + p

        dividers[0].frame = CGRect(x: x, y: 8, width: dW, height: H - 16)
        x += dW + p

        // 2. Resistance
        lblResistTitle.frame  = CGRect(x: x, y: 6,       width: w1, height: 12)
        lblResistTitle.textAlignment = .center
        lblResist.frame       = CGRect(x: x, y: H/2 - 2, width: w1, height: 24)
        x += w1 + p

        dividers[1].frame = CGRect(x: x, y: 8, width: dW, height: H - 16)
        x += dW + p

        // 3. Phase block
        phaseDot.frame    = CGRect(x: x,      y: (H-8)/2 - 8,  width: 8,         height: 8)
        lblPhaseName.frame = CGRect(x: x+12,  y: (H-16)/2 - 8, width: phaseW-14, height: 16)
        lblPhaseRes.frame  = CGRect(x: x+12,  y: (H-16)/2 + 10, width: 30,       height: 14)
        lblPhaseIdx.frame  = CGRect(x: x+46,  y: (H-16)/2 + 10, width: phaseW-50, height: 14)
        x += phaseW + p

        dividers[2].frame = CGRect(x: x, y: 8, width: dW, height: H - 16)
        x += dW + p

        // 4. Phase countdown
        lblCDTitle.frame  = CGRect(x: x, y: 6,       width: w3, height: 12)
        lblCDTitle.textAlignment = .center
        lblPhaseCD.frame  = CGRect(x: x, y: H/2 - 2, width: w3, height: 26)
        x += w3 + p

        dividers[3].frame = CGRect(x: x, y: 8, width: dW, height: H - 16)
        x += dW + p

        // 5. Total remain
        lblRemainTitle.frame = CGRect(x: x, y: 6,       width: w4, height: 12)
        lblRemainTitle.textAlignment = .right
        lblRemain.frame      = CGRect(x: x, y: H/2 - 2, width: w4, height: 24)
    }

    // MARK: - Refresh

    private func refreshUI() {
        let e     = engine
        let spm   = e.spmHistory.last   ?? 0
        let spd   = e.speedHistory.last ?? 0
        let pwr   = e.powerHistory.last ?? 0
        let cal   = e.calHistory.last   ?? 0
        let steps = e.stepsHistory.last ?? 0

        let totalRemain = max(0.0, Double(kTotalSecs) - e.workoutElapsed)
        let phaseRemain = max(0.0, Double(e.phaseTotal) - e.phaseElapsed)

        lblElapsed.text   = formatTime(e.workoutElapsed)
        lblResist.text    = "Lv \(e.currentData.currentResistance)"
        lblRemain.text    = formatTime(totalRemain)
        lblPhaseName.text = e.phaseName.isEmpty ? "--" : e.phaseName
        lblPhaseRes.text  = "R\(e.phaseResist)"
        lblPhaseCD.text   = formatTime(phaseRemain)
        lblPhaseIdx.text  = "\(e.phaseIndex + 1) / \(workoutPlan.count)"

        if let color = resistanceColors[e.phaseResist] {
            phaseDot.backgroundColor = color
            lblPhaseRes.textColor    = color
        }

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

// MARK: - Helpers

private func makeLabel(_ text: String, size: CGFloat, color: String) -> UILabel {
    let l = UILabel()
    l.text      = text
    l.font      = UIFont.systemFont(ofSize: size)
    l.textColor = UIColor(hex: color)
    return l
}

// MARK: - MetricBox

private class MetricBox: UIView {

    private let labelLbl = UILabel()
    private let valueLbl = UILabel()
    private let unitLbl  = UILabel()

    init(label: String, unit: String, color: UIColor) {
        super.init(frame: .zero)
        backgroundColor    = UIColor(hex: "#16213e")
        layer.cornerRadius = 12

        labelLbl.text          = label
        labelLbl.font          = UIFont.systemFont(ofSize: 11)
        labelLbl.textColor     = UIColor(hex: "#888888")
        labelLbl.textAlignment = .center

        valueLbl.text                      = "--"
        valueLbl.font                      = UIFont.monospacedDigitSystemFont(ofSize: 40, weight: .bold)
        valueLbl.textColor                 = color
        valueLbl.textAlignment             = .center
        valueLbl.adjustsFontSizeToFitWidth = true
        valueLbl.minimumScaleFactor        = 0.5

        unitLbl.text          = unit
        unitLbl.font          = UIFont.systemFont(ofSize: 10)
        unitLbl.textColor     = UIColor(hex: "#666666")
        unitLbl.textAlignment = .center

        [labelLbl, valueLbl, unitLbl].forEach { addSubview($0) }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let W = bounds.width
        let H = bounds.height
        labelLbl.frame = CGRect(x: 4, y: 6,    width: W-8, height: 14)
        valueLbl.frame = CGRect(x: 4, y: 20,   width: W-8, height: H-40)
        unitLbl.frame  = CGRect(x: 4, y: H-18, width: W-8, height: 14)
    }

    func setValue(_ text: String) { valueLbl.text = text }
}
