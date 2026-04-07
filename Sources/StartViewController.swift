// StartViewController.swift
// 开始页：图标 + 标题 + 训练计划描述 + 开始锻炼按钮

import UIKit

class StartViewController: UIViewController {

    private let iconView   = AppIconView()
    private let titleLabel = UILabel()
    private let descLabel  = UILabel()
    private let startBtn   = UIButton(type: .custom)

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
    }

    override var prefersStatusBarHidden: Bool { return true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .landscape }

    private func buildUI() {
        // 渐变背景
        let grad = CAGradientLayer()
        grad.colors = [UIColor(hex: "#0d1b2a").cgColor, UIColor(hex: "#1a1a3e").cgColor]
        grad.startPoint = CGPoint(x: 0, y: 0)
        grad.endPoint   = CGPoint(x: 1, y: 1)
        grad.frame      = UIScreen.main.bounds
        view.layer.insertSublayer(grad, at: 0)

        // 图标
        iconView.layer.cornerRadius = 16
        iconView.layer.masksToBounds = true
        view.addSubview(iconView)

        // 标题
        titleLabel.text          = "Merach Workout"
        titleLabel.font          = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textColor     = .white
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)

        // 描述
        let total = kTotalSecs / 60
        descLabel.text          = "\(total) 分钟  ·  热身 + \(workoutPlan.count - 2) 段阶梯 + 放松"
        descLabel.font          = UIFont.systemFont(ofSize: 13)
        descLabel.textColor     = UIColor(hex: "#888888")
        descLabel.textAlignment = .center
        view.addSubview(descLabel)

        // 开始按钮
        startBtn.setTitle("开始锻炼", for: .normal)
        startBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        startBtn.setTitleColor(UIColor(hex: "#0d1b2a"), for: .normal)
        startBtn.layer.cornerRadius = 25
        startBtn.clipsToBounds = true
        let gl = CAGradientLayer()
        gl.colors     = [UIColor(hex: "#00d4ff").cgColor, UIColor(hex: "#00ff88").cgColor]
        gl.startPoint = CGPoint(x: 0, y: 0.5)
        gl.endPoint   = CGPoint(x: 1, y: 0.5)
        gl.frame      = CGRect(x: 0, y: 0, width: 180, height: 50)
        startBtn.layer.insertSublayer(gl, at: 0)
        startBtn.addTarget(self, action: #selector(onStart), for: .touchUpInside)
        view.addSubview(startBtn)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let cx = view.bounds.midX
        let cy = view.bounds.midY

        iconView.frame  = CGRect(x: cx - 36, y: cy - 90, width: 72, height: 72)
        titleLabel.frame = CGRect(x: cx - 130, y: cy - 10, width: 260, height: 30)
        descLabel.frame  = CGRect(x: cx - 150, y: cy + 26, width: 300, height: 18)
        startBtn.frame   = CGRect(x: cx - 90,  y: cy + 58, width: 180, height: 50)

        // 更新渐变 frame
        view.layer.sublayers?.first?.frame = view.bounds
        if let gl = startBtn.layer.sublayers?.first {
            gl.frame = startBtn.bounds
        }
    }

    @objc private func onStart() {
        let vc = ConnectingViewController()
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle   = .crossDissolve
        present(vc, animated: true)
    }
}

// MARK: - AppIconView（代码绘制图标）

private class AppIconView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(hex: "#0d1b2a")
    }
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let s = rect.width / 72.0

        func sc(_ v: CGFloat) -> CGFloat { v * s }
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x*s, y: y*s) }

        // 椭圆轨迹
        let cx = sc(36), cy = sc(43)
        let ePath = UIBezierPath(ovalIn: CGRect(x: cx-sc(21), y: cy-sc(10), width: sc(42), height: sc(20)))
        UIColor(hex: "#00d4ff").withAlphaComponent(0.5).setStroke()
        ePath.lineWidth = sc(1.5)
        ePath.stroke()

        // 人物（白→青渐变用白色代替）
        let fig = UIColor(hex: "#c8e6ff")
        ctx.setLineCap(.round)

        func line(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat, _ color: UIColor, _ w: CGFloat) {
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(w * s)
            ctx.move(to: pt(x1, y1)); ctx.addLine(to: pt(x2, y2))
            ctx.strokePath()
        }
        func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) {
            fig.setFill()
            UIBezierPath(ovalIn: CGRect(x: pt(cx-r, cy-r).x, y: pt(cx-r, cy-r).y,
                                        width: sc(r*2), height: sc(r*2))).fill()
        }

        circle(36, 17, 4.5)
        line(36,22, 36,35, fig, 2)
        line(36,26, 25,20, fig, 1.5)
        line(25,20, 25,31, UIColor(hex: "#00d4ff"), 1.2)
        line(36,26, 47,31, fig, 1.5)
        line(47,20, 47,31, UIColor(hex: "#00ff88"), 1.2)
        line(36,35, 27,43, fig, 2)
        line(27,43, 22,47, fig, 1.5)
        line(36,35, 45,43, fig, 2)
        line(45,43, 50,47, fig, 1.5)

        // 脉冲线
        let pulsePts: [(CGFloat, CGFloat)] = [
            (12,59),(19,59),(22,54),(26,63),(29,56),(32,59),
            (40,59),(43,56),(46,62),(50,57),(53,59),(60,59)
        ]
        let pulsePath = UIBezierPath()
        pulsePath.move(to: pt(pulsePts[0].0, pulsePts[0].1))
        for p2 in pulsePts.dropFirst() { pulsePath.addLine(to: pt(p2.0, p2.1)) }
        UIColor(hex: "#00d4ff").withAlphaComponent(0.8).setStroke()
        pulsePath.lineWidth = s
        pulsePath.lineCapStyle = .round
        pulsePath.stroke()
    }
}
