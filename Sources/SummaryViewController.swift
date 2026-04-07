// SummaryViewController.swift
// 训练汇总页：6项数据 + 完成按钮

import UIKit

struct WorkoutStats {
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

    private let headerView = UIView()
    private let checkLabel = UILabel()
    private let titleLabel = UILabel()
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
        grad.startPoint = CGPoint(x: 0, y: 0)
        grad.endPoint   = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(grad, at: 0)

        // Header
        checkLabel.text      = "✅"
        checkLabel.font      = UIFont.systemFont(ofSize: 22)
        checkLabel.textAlignment = .center
        view.addSubview(checkLabel)

        titleLabel.text      = "训练完成"
        titleLabel.font      = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)

        // Stats boxes
        let items: [(String, String, String, UIColor)] = [
            ("总时长",   formatTime(stats.elapsedSeconds), "mm:ss",    UIColor(hex: "#00ff88")),
            ("总步数",   formatInt(Int(stats.totalSteps)), "步",        UIColor(hex: "#4dd0e1")),
            ("总距离",   String(format: "%.2f", stats.totalDistM/1000), "km", UIColor(hex: "#00d4ff")),
            ("平均 SPM", String(Int(stats.avgSpm)),        "步/分钟",   UIColor(hex: "#00d4ff")),
            ("平均功率", String(Int(stats.avgPower)),      "W",         UIColor(hex: "#ff6b6b")),
            ("消耗热量", String(Int(stats.totalCal)),      "kcal",      UIColor(hex: "#ffa726")),
        ]
        for (lbl, val, unit, color) in items {
            let box = SumBox(label: lbl, value: val, unit: unit, color: color)
            view.addSubview(box)
            boxes.append(box)
        }

        // Done button
        doneBtn.setTitle("完成", for: .normal)
        doneBtn.setTitleColor(UIColor(hex: "#0d1b2a"), for: .normal)
        doneBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        doneBtn.layer.cornerRadius = 22
        doneBtn.clipsToBounds = true
        let gl = CAGradientLayer()
        gl.colors     = [UIColor(hex: "#00d4ff").cgColor, UIColor(hex: "#00ff88").cgColor]
        gl.startPoint = CGPoint(x: 0, y: 0.5)
        gl.endPoint   = CGPoint(x: 1, y: 0.5)
        doneBtn.layer.insertSublayer(gl, at: 0)
        doneBtn.addTarget(self, action: #selector(onDone), for: .touchUpInside)
        view.addSubview(doneBtn)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.layer.sublayers?.first?.frame = view.bounds
        if let gl = doneBtn.layer.sublayers?.first { gl.frame = doneBtn.bounds }

        let safe = view.safeAreaInsets
        let p: CGFloat = 10
        let W = view.bounds.width  - safe.left - safe.right - 2*p
        let H = view.bounds.height - safe.top  - safe.bottom
        let x0 = safe.left + p
        var y = safe.top + p

        // Header
        let hdrH: CGFloat = 36
        checkLabel.frame = CGRect(x: x0, y: y, width: 30, height: hdrH)
        titleLabel.frame = CGRect(x: x0 + 34, y: y, width: W - 34, height: hdrH)
        y += hdrH + 8

        // Done button (right side, fixed)
        let btnW: CGFloat = 110
        let btnH: CGFloat = 44
        doneBtn.frame = CGRect(x: x0 + W - btnW, y: y,
                               width: btnW, height: H - hdrH - 8 - p)
        // align button vertically centered in remaining space
        let gridH = H - hdrH - 8 - p
        doneBtn.frame = CGRect(x: x0 + W - btnW,
                               y: y + (gridH - btnH) / 2,
                               width: btnW, height: btnH)

        // 6 boxes in 2 rows × 3 cols, left of done button
        let gridW = W - btnW - p
        let colW = (gridW - 2*p) / 3
        let rowH = (gridH - p) / 2
        for (i, box) in boxes.enumerated() {
            let col = i % 3
            let row = i / 3
            box.frame = CGRect(
                x: x0 + CGFloat(col) * (colW + p),
                y: y  + CGFloat(row) * (rowH + p),
                width: colW, height: rowH
            )
        }
    }

    @objc private func onDone() {
        // 一路 dismiss 回到 StartViewController
        if let root = view.window?.rootViewController {
            root.dismiss(animated: true)
        }
    }

    private func formatInt(_ n: Int) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        return nf.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}

// MARK: - SumBox

private class SumBox: UIView {

    init(label: String, value: String, unit: String, color: UIColor) {
        super.init(frame: .zero)
        backgroundColor    = UIColor(hex: "#16213e")
        layer.cornerRadius = 10

        let lbl = UILabel()
        lbl.text = label; lbl.font = UIFont.systemFont(ofSize: 10)
        lbl.textColor = UIColor(hex: "#888888"); lbl.textAlignment = .center

        let val = UILabel()
        val.text = value
        val.font = UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .bold)
        val.textColor = color; val.textAlignment = .center
        val.adjustsFontSizeToFitWidth = true; val.minimumScaleFactor = 0.6

        let unt = UILabel()
        unt.text = unit; unt.font = UIFont.systemFont(ofSize: 10)
        unt.textColor = UIColor(hex: "#555555"); unt.textAlignment = .center

        [lbl, val, unt].forEach { addSubview($0) }

        lbl.translatesAutoresizingMaskIntoConstraints = false
        val.translatesAutoresizingMaskIntoConstraints = false
        unt.translatesAutoresizingMaskIntoConstraints = false
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
