// DashboardViewController.swift
// iPhone 6s 横屏布局：单顶栏（5块）+ 2行×3列数值方格 + 底部留空28pt + 长按停止

import UIKit

class DashboardViewController: UIViewController {

    // MARK: - Engine（由外部传入）
    private let engine: WorkoutEngine
    init(engine: WorkoutEngine) {
        self.engine = engine
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Colors
    private let bgColor     = UIColor(hex: "#1a1a2e")
    private let topBarColor = UIColor(hex: "#0d1b2a")

    // MARK: - Top bar
    private let topBar = UIView()

    private let lblElapsedTitle = makeLabel("已用时",  size: 10, color: "#888888")
    private let lblElapsed      = UILabel()
    private let lblResistTitle  = makeLabel("阻力",    size: 10, color: "#888888")
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

    // MARK: - Metric boxes
    private let boxSPM   = MetricBox(label: "SPM",      unit: "steps/min", color: UIColor(hex: "#00d4ff"))
    private let boxSpeed = MetricBox(label: "Speed",    unit: "km/h",      color: UIColor(hex: "#00ff88"))
    private let boxPower = MetricBox(label: "Power",    unit: "W",         color: UIColor(hex: "#ff6b6b"))
    private let boxSteps = MetricBox(label: "Steps",    unit: "total",     color: UIColor(hex: "#4dd0e1"))
    private let boxPace  = MetricBox(label: "Pace",     unit: "min/km",    color: UIColor(hex: "#00ff88"))
    private let boxCal   = MetricBox(label: "Calories", unit: "kcal",      color: UIColor(hex: "#ffa726"))

    // MARK: - Stop button
    private let stopWrap  = UIView()
    private let stopBtn   = UIButton(type: .custom)
    private let stopHint  = UILabel()
    private let stopRing  = CAShapeLayer()
    private var stopTimer: Timer?
    private var stopStart: Date?
    private let holdDuration: TimeInterval = 3.0

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        engine.delegate = self
    }

    override var prefersStatusBarHidden: Bool { return true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .landscape }

    // MARK: - Build UI

    private func buildUI() {
        view.backgroundColor = bgColor

        // Top bar
        topBar.backgroundColor    = topBarColor
        topBar.layer.cornerRadius = 10
        view.addSubview(topBar)

        lblElapsed.font = UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .bold)
        lblElapsed.textColor = UIColor(hex: "#00ff88"); lblElapsed.text = "--:--"

        lblResist.font = UIFont.boldSystemFont(ofSize: 20)
        lblResist.textColor = UIColor(hex: "#ffeb3b"); lblResist.text = "Lv --"
        lblResist.textAlignment = .center

        phaseDot.layer.cornerRadius = 4
        phaseDot.backgroundColor   = UIColor(hex: "#ffeb3b")

        lblPhaseName.font = UIFont.boldSystemFont(ofSize: 13)
        lblPhaseName.textColor = .white; lblPhaseName.text = "--"

        lblPhaseRes.font = UIFont.systemFont(ofSize: 10)
        lblPhaseRes.textColor = UIColor(hex: "#ffeb3b")
        lblPhaseRes.backgroundColor = UIColor(hex: "#1a1a2e")
        lblPhaseRes.layer.cornerRadius = 3; lblPhaseRes.layer.masksToBounds = true
        lblPhaseRes.textAlignment = .center; lblPhaseRes.text = "R--"

        lblPhaseIdx.font = UIFont.systemFont(ofSize: 10)
        lblPhaseIdx.textColor = UIColor(hex: "#888888"); lblPhaseIdx.text = "0 / 9"

        lblPhaseCD.font = UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .bold)
        lblPhaseCD.textColor = UIColor(hex: "#ff6b6b"); lblPhaseCD.text = "--:--"
        lblPhaseCD.textAlignment = .center

        lblRemain.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .bold)
        lblRemain.textColor = UIColor(hex: "#ffa726"); lblRemain.text = "--:--"
        lblRemain.textAlignment = .right

        [lblElapsedTitle, lblElapsed, lblResistTitle, lblResist,
         phaseDot, lblPhaseName, lblPhaseRes, lblPhaseIdx,
         lblCDTitle, lblPhaseCD, lblRemainTitle, lblRemain].forEach { topBar.addSubview($0) }

        for _ in 0..<4 {
            let d = UIView(); d.backgroundColor = UIColor(hex: "#2a3a4a")
            topBar.addSubview(d); dividers.append(d)
        }

        [boxSPM, boxSpeed, boxPower, boxSteps, boxPace, boxCal].forEach { view.addSubview($0) }

        // Stop button
        stopHint.text = "长按 3 秒停止"
        stopHint.font = UIFont.systemFont(ofSize: 9)
        stopHint.textColor = UIColor(hex: "#555555")
        stopHint.textAlignment = .center

        stopBtn.layer.cornerRadius = 23
        stopBtn.layer.borderColor  = UIColor(hex: "#ff6b6b").cgColor
        stopBtn.layer.borderWidth  = 2.5
        stopBtn.backgroundColor    = UIColor(hex: "#ff6b6b").withAlphaComponent(0.12)
        stopBtn.setTitle("⏹", for: .normal)
        stopBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)

        // 进度环
        stopRing.fillColor    = UIColor.clear.cgColor
        stopRing.strokeColor  = UIColor(hex: "#ff6b6b").cgColor
        stopRing.lineWidth    = 3
        stopRing.lineCap      = .round
        stopRing.strokeEnd    = 0
        stopBtn.layer.addSublayer(stopRing)

        stopBtn.addTarget(self, action: #selector(stopTouchDown),  for: .touchDown)
        stopBtn.addTarget(self, action: #selector(stopTouchUp),    for: [.touchUpInside, .touchUpOutside, .touchCancel])

        stopWrap.addSubview(stopHint)
        stopWrap.addSubview(stopBtn)
        view.addSubview(stopWrap)
    }

    // MARK: - Layout

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutAll()
    }

    private func layoutAll() {
        let safe = view.safeAreaInsets
        let p: CGFloat = 8
        let bottomPad: CGFloat = 28
        let x0 = safe.left + p
        let y0 = safe.top + p
        let W  = view.bounds.width  - safe.left - safe.right - 2*p
        let H  = view.bounds.height - safe.top  - safe.bottom

        let topH: CGFloat = 54
        topBar.frame = CGRect(x: x0, y: y0, width: W, height: topH)
        layoutTopBar(bounds: topBar.bounds)

        let gridY = y0 + topH + p
        let gridH = H - topH - p - p - bottomPad
        let rowH  = (gridH - p) / 2

        // Stop button takes up one "column" width on right
        let stopSize: CGFloat = 46
        let colW = (W - 2*p - stopSize - p) / 3

        let rows: [[MetricBox]] = [[boxSPM, boxSpeed, boxPower], [boxSteps, boxPace, boxCal]]
        for (ri, row) in rows.enumerated() {
            let rowY = gridY + CGFloat(ri) * (rowH + p)
            for (ci, box) in row.enumerated() {
                let colX = x0 + CGFloat(ci) * (colW + p)
                box.frame = CGRect(x: colX, y: rowY, width: colW, height: rowH)
            }
        }

        // Stop wrap: vertically centered in grid area, right side
        let wrapW: CGFloat = stopSize + 4
        let wrapH: CGFloat = stopSize + 20
        let wrapX = x0 + W - wrapW
        let wrapY = gridY + (gridH - wrapH) / 2
        stopWrap.frame = CGRect(x: wrapX, y: wrapY, width: wrapW, height: wrapH)
        stopHint.frame = CGRect(x: 0, y: 0, width: wrapW, height: 14)
        stopBtn.frame  = CGRect(x: (wrapW - stopSize)/2, y: 16, width: stopSize, height: stopSize)

        // Stop ring path
        let center = CGPoint(x: stopSize/2, y: stopSize/2)
        let radius = stopSize/2 - 3
        let path = UIBezierPath(arcCenter: center, radius: radius,
                                startAngle: -.pi/2, endAngle: 1.5 * .pi, clockwise: true)
        stopRing.path   = path.cgPath
        stopRing.frame  = stopBtn.bounds
        stopRing.strokeEnd = 0
    }

    private func layoutTopBar(bounds: CGRect) {
        let W = bounds.width; let H = bounds.height; let p: CGFloat = 10
        let w0: CGFloat = 76; let w1: CGFloat = 66; let w3: CGFloat = 76; let w4: CGFloat = 72
        let dW: CGFloat = 1
        let phaseW = W - w0 - w1 - w3 - w4 - 4*(dW + p*2) - 2*p
        var x = p

        lblElapsedTitle.frame = CGRect(x: x, y: 6, width: w0, height: 12)
        lblElapsed.frame      = CGRect(x: x, y: H/2 - 2, width: w0, height: 26)
        x += w0 + p
        dividers[0].frame = CGRect(x: x, y: 8, width: dW, height: H-16); x += dW + p

        lblResistTitle.frame = CGRect(x: x, y: 6, width: w1, height: 12)
        lblResistTitle.textAlignment = .center
        lblResist.frame = CGRect(x: x, y: H/2 - 2, width: w1, height: 24)
        x += w1 + p
        dividers[1].frame = CGRect(x: x, y: 8, width: dW, height: H-16); x += dW + p

        phaseDot.frame     = CGRect(x: x,     y: (H-8)/2 - 8,  width: 8,          height: 8)
        lblPhaseName.frame = CGRect(x: x+12,  y: (H-16)/2 - 8, width: phaseW-14,  height: 16)
        lblPhaseRes.frame  = CGRect(x: x+12,  y: (H-16)/2 + 10, width: 30,        height: 14)
        lblPhaseIdx.frame  = CGRect(x: x+46,  y: (H-16)/2 + 10, width: phaseW-50, height: 14)
        x += phaseW + p
        dividers[2].frame = CGRect(x: x, y: 8, width: dW, height: H-16); x += dW + p

        lblCDTitle.frame = CGRect(x: x, y: 6, width: w3, height: 12)
        lblCDTitle.textAlignment = .center
        lblPhaseCD.frame = CGRect(x: x, y: H/2 - 2, width: w3, height: 26)
        x += w3 + p
        dividers[3].frame = CGRect(x: x, y: 8, width: dW, height: H-16); x += dW + p

        lblRemainTitle.frame = CGRect(x: x, y: 6, width: w4, height: 12)
        lblRemainTitle.textAlignment = .right
        lblRemain.frame = CGRect(x: x, y: H/2 - 2, width: w4, height: 24)
    }

    // MARK: - Stop Button Logic

    @objc private func stopTouchDown() {
        stopStart = Date()
        stopTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateStopProgress()
        }
    }

    @objc private func stopTouchUp() {
        cancelStopTimer()
    }

    private func updateStopProgress() {
        guard let start = stopStart else { return }
        let progress = min(Date().timeIntervalSince(start) / holdDuration, 1.0)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        stopRing.strokeEnd = CGFloat(progress)
        CATransaction.commit()
        if progress >= 1.0 {
            cancelStopTimer()
            triggerStop()
        }
    }

    private func cancelStopTimer() {
        stopTimer?.invalidate(); stopTimer = nil; stopStart = nil
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        stopRing.strokeEnd = 0
        CATransaction.commit()
    }

    private func triggerStop() {
        engine.stop()
        showSummary()
    }

    // MARK: - Summary

    private func showSummary() {
        let history = engine.powerHistory
        let avgPwr = history.isEmpty ? 0 : history.reduce(0, +) / Double(history.count)
        let spmHist = engine.spmHistory
        let nonZeroSpm = spmHist.filter { $0 > 0 }
        let avgSpm = nonZeroSpm.isEmpty ? 0 : nonZeroSpm.reduce(0, +) / Double(nonZeroSpm.count)

        let stats = WorkoutStats(
            elapsedSeconds: engine.workoutElapsed,
            totalSteps:     engine.totalSteps,
            totalDistM:     engine.totalDistM,
            avgSpm:         avgSpm,
            avgPower:       avgPwr,
            totalCal:       Double(engine.currentData.caloriesKcal)
        )
        let vc = SummaryViewController(stats: stats)
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle   = .crossDissolve
        present(vc, animated: true)
    }

    // MARK: - Refresh

    private func refreshUI() {
        let e = engine
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
        if engine.workoutDone { showSummary() }
    }
}

// MARK: - Helpers

private func makeLabel(_ text: String, size: CGFloat, color: String) -> UILabel {
    let l = UILabel()
    l.text = text; l.font = UIFont.systemFont(ofSize: size)
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
        backgroundColor = UIColor(hex: "#16213e"); layer.cornerRadius = 12

        labelLbl.text = label; labelLbl.font = UIFont.systemFont(ofSize: 11)
        labelLbl.textColor = UIColor(hex: "#888888"); labelLbl.textAlignment = .center

        valueLbl.text = "--"
        valueLbl.font = UIFont.monospacedDigitSystemFont(ofSize: 40, weight: .bold)
        valueLbl.textColor = color; valueLbl.textAlignment = .center
        valueLbl.adjustsFontSizeToFitWidth = true; valueLbl.minimumScaleFactor = 0.5

        unitLbl.text = unit; unitLbl.font = UIFont.systemFont(ofSize: 10)
        unitLbl.textColor = UIColor(hex: "#666666"); unitLbl.textAlignment = .center

        [labelLbl, valueLbl, unitLbl].forEach { addSubview($0) }
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let W = bounds.width; let H = bounds.height
        labelLbl.frame = CGRect(x: 4, y: 6,    width: W-8, height: 14)
        valueLbl.frame = CGRect(x: 4, y: 20,   width: W-8, height: H-40)
        unitLbl.frame  = CGRect(x: 4, y: H-18, width: W-8, height: 14)
    }

    func setValue(_ text: String) { valueLbl.text = text }
}
