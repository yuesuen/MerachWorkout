// SummaryViewController.swift
// 训练汇总页：6项数据 + 底部全宽完成按钮

import UIKit

struct WorkoutStats {
    let planName:       String
    let elapsedSeconds: Double
    let totalSteps:     Double
    let totalDistM:     Double
    let avgSpm:         Double
    let avgPower:       Double
    let totalCal:       Double
}

class SummaryViewController: UIViewController {

    private let stats: WorkoutStats
    init(stats: WorkoutStats) {
        self.stats = stats
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    private let checkLabel = UILabel()
    private let titleLabel = UILabel()
    private let planLabel  = UILabel()
    private var boxes: [SumBox] = []
    private let doneBtn = UIButton(type: .custom)

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
    }

    override var prefersStatusBarHidden: Bool { return true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .landscape }

    private func buildUI() {
        let grad = CAGradientLayer()
        grad.colors     = [UIColor(hex: "#0d1b2a").cgColor, UIColor(hex: "#1a1a3e").cgColor]
        grad.startPoint = CGPoint(x: 0, y: 0); grad.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(grad, at: 0)

        checkLabel.text = "✅"; checkLabel.font = UIFont.systemFont(ofSize: 22)
        checkLabel.textAlignment = .center
        view.addSubview(checkLabel)

        titleLabel.text = "训练完成"; titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = .white
        view.addSubview(titleLabel)

        let elapsed = formatTime(stats.elapsedSeconds)
        planLabel.text = "\(stats.planName)  ·  \(elapsed)"
        planLabel.font = UIFont.systemFont(ofSize: 12)
        planLabel.textColor = UIColor(hex: "#888888")
        view.addSubview(planLabel)

        let items: [(String, String, String, UIColor)] = [
            ("总时长",   formatTime(stats.elapsedSeconds),             "mm:ss",    UIColor(hex: "#00ff88")),
            ("总步数",   formatInt(Int(stats.totalSteps)),             "步",        UIColor(hex: "#4dd0e1")),
            ("总距离",   String(format: "%.2f", stats.totalDistM/1000),"km",        UIColor(hex: "#00d4ff")),
            ("平均 SPM", String(Int(stats.avgSpm)),                    "步/分钟",   UIColor(hex: "#00d4ff")),
            ("平均功率", String(Int(stats.avgPower)),                   "W",         UIColor(hex: "#ff6b6b")),
            ("消耗热量", String(Int(stats.totalCal)),                   "kcal",      UIColor(hex: "#ffa726")),
        ]
        for (lbl, val, unit, color) in items {
            let box = SumBox(label: lbl, value: val, unit: unit, color: color)
            view.addSubview(box); boxes.append(box)
        }

        // 完成按钮：全宽，底部
        doneBtn.setTitle("完  成", for: .normal)
        doneBtn.setTitleColor(UIColor(hex: "#0d1b2a"), for: .normal)
        doneBtn.titleLabel?.font  = UIFont.boldSystemFont(ofSize: 17)
        doneBtn.layer.cornerRadius = 21; doneBtn.clipsToBounds = true
        let gl = CAGradientLayer()
        gl.colors     = [UIColor(hex: "#00d4ff").cgColor, UIColor(hex: "#00ff88").cgColor]
        gl.startPoint = CGPoint(x: 0, y: 0.5); gl.endPoint = CGPoint(x: 1, y: 0.5)
        doneBtn.layer.insertSublayer(gl, at: 0)
        doneBtn.addTarget(self, action: #selector(onDone), for: .touchUpInside)
        view.addSubview(doneBtn)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.layer.sublayers?.first?.frame = view.bounds
        if let gl = doneBtn.layer.sublayers?.first { gl.frame = doneBtn.bounds }

        let safe = view.safeAreaInsets
        let p: CGFloat = 12
        let x0 = safe.left + p
        let y0 = safe.top + p
        let W  = view.bounds.width  - safe.left - safe.right - 2*p
        let H  = view.bounds.height - safe.top  - safe.bottom

        // Header row
        let hdrH: CGFloat = 28
        checkLabel.frame = CGRect(x: x0,      y: y0, width: 30,      height: hdrH)
        titleLabel.frame = CGRect(x: x0 + 34, y: y0, width: 160,     height: hdrH)
        planLabel.frame  = CGRect(x: x0 + 34 + 164, y: y0 + 8, width: W - 34 - 164, height: 14)

        // Done button at bottom
        let btnH: CGFloat = 42
        let btnY = y0 + H - btnH - p
        doneBtn.frame = CGRect(x: x0, y: btnY, width: W, height: btnH)

        // 6 boxes in 2×3 grid between header and button
        let gridY = y0 + hdrH + 8
        let gridH = btnY - gridY - 8
        let rowH  = (gridH - 8) / 2
        let colW  = (W - 2*8) / 3

        for (i, box) in boxes.enumerated() {
            let col = i % 3; let row = i / 3
            box.frame = CGRect(
                x: x0 + CGFloat(col) * (colW + 8),
                y: gridY + CGFloat(row) * (rowH + 8),
                width: colW, height: rowH
            )
        }
    }

    @objc private func onDone() {
        view.window?.rootViewController?.dismiss(animated: true)
    }

    private func formatInt(_ n: Int) -> String {
        let nf = NumberFormatter(); nf.numberStyle = .decimal
        return nf.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}

// MARK: - SumBox

private class SumBox: UIView {
    init(label: String, value: String, unit: String, color: UIColor) {
        super.init(frame: .zero)
        backgroundColor = UIColor(hex: "#16213e"); layer.cornerRadius = 10

        let lbl = UILabel(); lbl.text = label
        lbl.font = UIFont.systemFont(ofSize: 10); lbl.textColor = UIColor(hex: "#888888")
        lbl.textAlignment = .center

        let val = UILabel(); val.text = value
        val.font = UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .bold)
        val.textColor = color; val.textAlignment = .center
        val.adjustsFontSizeToFitWidth = true; val.minimumScaleFactor = 0.6

        let unt = UILabel(); unt.text = unit
        unt.font = UIFont.systemFont(ofSize: 10); unt.textColor = UIColor(hex: "#555555")
        unt.textAlignment = .center

        [lbl, val, unt].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        NSLayoutConstraint.activate([
            lbl.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            lbl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            lbl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            val.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 4),
            val.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            val.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            unt.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            unt.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            unt.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}
