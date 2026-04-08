// StartViewController.swift
// 开始页：App 标题 + 三个计划卡片 + 开始锻炼按钮

import UIKit

class StartViewController: UIViewController {

    private var selectedIndex = 0
    private var planCards: [PlanCardView] = []

    private let iconView   = AppIconView()
    private let titleLabel = UILabel()
    private let subLabel   = UILabel()
    private let startBtn   = UIButton(type: .custom)
    private var startBtnGrad: CAGradientLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
    }

    override var prefersStatusBarHidden: Bool { return true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .landscape }

    // MARK: - Build UI

    private func buildUI() {
        let grad = CAGradientLayer()
        grad.colors     = [UIColor(hex: "#0d1b2a").cgColor, UIColor(hex: "#1a1a3e").cgColor]
        grad.startPoint = CGPoint(x: 0, y: 0); grad.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(grad, at: 0)

        // Icon
        iconView.layer.cornerRadius  = 9
        iconView.layer.masksToBounds = true
        view.addSubview(iconView)

        // Title
        titleLabel.text          = "Merach Workout"
        titleLabel.font          = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textColor     = .white
        view.addSubview(titleLabel)

        // Sub
        subLabel.text      = "选择今天的训练计划"
        subLabel.font      = UIFont.systemFont(ofSize: 11)
        subLabel.textColor = UIColor(hex: "#888888")
        view.addSubview(subLabel)

        // Plan cards
        for (i, plan) in allWorkoutPlans.enumerated() {
            let card = PlanCardView(plan: plan)
            card.isSelected = (i == selectedIndex)
            card.tag = i
            let tap = UITapGestureRecognizer(target: self, action: #selector(onCardTap(_:)))
            card.addGestureRecognizer(tap)
            view.addSubview(card)
            planCards.append(card)
        }

        // Start button
        startBtn.setTitle("开始锻炼", for: .normal)
        startBtn.setTitleColor(UIColor(hex: "#0d1b2a"), for: .normal)
        startBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        startBtn.layer.cornerRadius = 21
        startBtn.clipsToBounds = true
        let gl = CAGradientLayer()
        gl.colors     = [UIColor(hex: "#00d4ff").cgColor, UIColor(hex: "#00ff88").cgColor]
        gl.startPoint = CGPoint(x: 0, y: 0.5); gl.endPoint = CGPoint(x: 1, y: 0.5)
        startBtn.layer.insertSublayer(gl, at: 0)
        startBtnGrad = gl
        startBtn.addTarget(self, action: #selector(onStart), for: .touchUpInside)
        view.addSubview(startBtn)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let safe = view.safeAreaInsets
        let p: CGFloat = 12
        let x0 = safe.left + p
        let y0 = safe.top  + p
        let W  = view.bounds.width  - safe.left - safe.right - 2*p
        let H  = view.bounds.height - safe.top  - safe.bottom

        // Header row
        iconView.frame   = CGRect(x: x0,      y: y0, width: 40, height: 40)
        titleLabel.frame = CGRect(x: x0 + 48, y: y0 + 2,  width: 200, height: 22)
        subLabel.frame   = CGRect(x: x0 + 48, y: y0 + 26, width: 200, height: 14)

        // Cards row
        let cardsY: CGFloat = y0 + 52 + 8
        let btnH:   CGFloat = 42
        let cardsH  = H - 52 - 8 - btnH - 8 - p
        let cardW   = (W - 2*p) / 3

        for (i, card) in planCards.enumerated() {
            card.frame = CGRect(x: x0 + CGFloat(i) * (cardW + p),
                                y: cardsY, width: cardW, height: cardsH)
        }

        // Start button — right aligned, vertically centered with header
        startBtn.frame = CGRect(x: x0 + W - 160,
                                y: y0 + (40 - btnH) / 2,
                                width: 160, height: btnH)
        startBtnGrad?.frame = startBtn.bounds
        view.layer.sublayers?.first?.frame = view.bounds
    }

    // MARK: - Actions

    @objc private func onCardTap(_ tap: UITapGestureRecognizer) {
        guard let i = tap.view?.tag else { return }
        selectedIndex = i
        for (j, card) in planCards.enumerated() { card.isSelected = (j == i) }
    }

    @objc private func onStart() {
        let plan = allWorkoutPlans[selectedIndex]
        let vc   = ConnectingViewController(plan: plan)
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle   = .crossDissolve
        present(vc, animated: true)
    }
}

// MARK: - PlanCardView

private class PlanCardView: UIView {

    var isSelected: Bool = false {
        didSet {
            layer.borderColor = isSelected
                ? UIColor(hex: plan.colorHex).cgColor
                : UIColor(hex: "#2a3a4a").cgColor
            layer.borderWidth = isSelected ? 2 : 1.5
            checkLabel.isHidden = !isSelected
        }
    }

    private let plan: WorkoutPlanConfig
    private let badgeLbl  = UILabel()
    private let nameLbl   = UILabel()
    private let durLbl    = UILabel()
    private let chartView = SegmentBarChart()
    private let descLbl   = UILabel()
    private let checkLabel = UILabel()
    private let freeIcon  = UILabel()

    init(plan: WorkoutPlanConfig) {
        self.plan = plan
        super.init(frame: .zero)
        backgroundColor      = UIColor(hex: "#16213e")
        layer.cornerRadius   = 12
        layer.borderWidth    = 1.5
        layer.borderColor    = UIColor(hex: "#2a3a4a").cgColor

        let accent = UIColor(hex: plan.colorHex)

        // Badge
        badgeLbl.text                 = plan.badge
        badgeLbl.font                 = UIFont.boldSystemFont(ofSize: 9)
        badgeLbl.textColor            = accent
        badgeLbl.backgroundColor      = accent.withAlphaComponent(0.15)
        badgeLbl.layer.cornerRadius   = 3
        badgeLbl.layer.masksToBounds  = true
        badgeLbl.textAlignment        = .center
        addSubview(badgeLbl)

        // Name
        nameLbl.text      = plan.name
        nameLbl.font      = UIFont.boldSystemFont(ofSize: 15)
        nameLbl.textColor = .white
        addSubview(nameLbl)

        // Duration
        let mins = plan.totalSeconds / 60
        let secs = plan.totalSeconds % 60
        durLbl.text      = plan.isFree ? "⏱ 无限制"
            : (secs == 0 ? "⏱ \(mins) 分钟" : "⏱ \(mins) 分 \(secs) 秒")
        durLbl.font      = UIFont.systemFont(ofSize: 11, weight: .semibold)
        durLbl.textColor = UIColor(hex: "#ffa726")
        addSubview(durLbl)

        // Chart or free icon
        if plan.isFree {
            freeIcon.text      = "📊"
            freeIcon.font      = UIFont.systemFont(ofSize: 28)
            freeIcon.textAlignment = .center
            addSubview(freeIcon)
        } else {
            chartView.segments = plan.segments
            addSubview(chartView)
        }

        // Description
        descLbl.text          = plan.description
        descLbl.font          = UIFont.systemFont(ofSize: 10)
        descLbl.textColor     = UIColor(hex: "#888888")
        descLbl.numberOfLines = 2
        addSubview(descLbl)

        // Check
        checkLabel.text      = "✓"
        checkLabel.font      = UIFont.boldSystemFont(ofSize: 13)
        checkLabel.textColor = accent
        checkLabel.isHidden  = true
        addSubview(checkLabel)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let W = bounds.width; let H = bounds.height; let p: CGFloat = 8

        badgeLbl.frame  = CGRect(x: p,      y: p,       width: W - 2*p - 20, height: 16)
        checkLabel.frame = CGRect(x: W - 22, y: p,      width: 18,           height: 16)
        nameLbl.frame   = CGRect(x: p,      y: p+20,    width: W - 2*p,      height: 18)
        durLbl.frame    = CGRect(x: p,      y: p+40,    width: W - 2*p,      height: 14)

        let midY: CGFloat = p + 58
        let midH = H - midY - 32 - p

        if plan.isFree {
            freeIcon.frame = CGRect(x: p, y: midY, width: W - 2*p, height: midH)
        } else {
            chartView.frame = CGRect(x: p, y: midY, width: W - 2*p, height: max(24, midH))
        }

        descLbl.frame = CGRect(x: p, y: H - 30 - p, width: W - 2*p, height: 30)
    }
}

// MARK: - SegmentBarChart

private class SegmentBarChart: UIView {

    var segments: [WorkoutSegment] = [] { didSet { setNeedsDisplay() } }

    override func draw(_ rect: CGRect) {
        guard !segments.isEmpty else { return }
        let maxRes = segments.map { $0.resistance }.max() ?? 1
        let totalDur = segments.reduce(0) { $0 + $1.duration }
        guard totalDur > 0 else { return }

        let W = rect.width; let H = rect.height
        var x: CGFloat = 0

        for seg in segments {
            let barW = W * CGFloat(seg.duration) / CGFloat(totalDur)
            let barH = H * CGFloat(seg.resistance) / CGFloat(maxRes)
            let barY = H - barH
            let color = resistanceColor(seg.resistance)
            let barRect = CGRect(x: x, y: barY, width: max(1, barW - 1), height: barH)
            let path = UIBezierPath(roundedRect: barRect, cornerRadius: 2)
            color.setFill(); path.fill()
            x += barW
        }
    }

    private func resistanceColor(_ r: Int) -> UIColor {
        return resistanceColors[r] ?? UIColor(hex: "#888888")
    }
}

// MARK: - AppIconView

private class AppIconView: UIView {
    override init(frame: CGRect) { super.init(frame: frame); backgroundColor = UIColor(hex: "#0d1b2a") }
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let s = rect.width / 72.0
        func sc(_ v: CGFloat) -> CGFloat { v * s }
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x*s, y: y*s) }

        let ePath = UIBezierPath(ovalIn: CGRect(x: sc(15), y: sc(33), width: sc(42), height: sc(20)))
        UIColor(hex: "#00d4ff").withAlphaComponent(0.5).setStroke()
        ePath.lineWidth = sc(1.5); ePath.stroke()

        let fig = UIColor(hex: "#c8e6ff")
        ctx.setLineCap(.round)
        func line(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat, _ c: UIColor, _ w: CGFloat) {
            ctx.setStrokeColor(c.cgColor); ctx.setLineWidth(w*s)
            ctx.move(to: pt(x1,y1)); ctx.addLine(to: pt(x2,y2)); ctx.strokePath()
        }
        UIBezierPath(ovalIn: CGRect(x: pt(31.5,12.5).x, y: pt(31.5,12.5).y, width: sc(9), height: sc(9))).fill()
        fig.setFill()
        UIBezierPath(ovalIn: CGRect(x: pt(31.5,12.5).x, y: pt(31.5,12.5).y, width: sc(9), height: sc(9))).fill()
        line(36,22, 36,35, fig, 2); line(36,26, 25,20, fig, 1.5)
        line(25,20, 25,31, UIColor(hex:"#00d4ff"), 1.2)
        line(36,26, 47,31, fig, 1.5); line(47,20, 47,31, UIColor(hex:"#00ff88"), 1.2)
        line(36,35, 27,43, fig, 2); line(27,43, 22,47, fig, 1.5)
        line(36,35, 45,43, fig, 2); line(45,43, 50,47, fig, 1.5)

        let pts: [(CGFloat,CGFloat)] = [(12,59),(19,59),(22,54),(26,63),(29,56),(32,59),(40,59),(43,56),(46,62),(50,57),(53,59),(60,59)]
        let pulse = UIBezierPath(); pulse.move(to: pt(pts[0].0,pts[0].1))
        for p2 in pts.dropFirst() { pulse.addLine(to: pt(p2.0,p2.1)) }
        UIColor(hex: "#00d4ff").withAlphaComponent(0.8).setStroke()
        pulse.lineWidth = s; pulse.lineCapStyle = .round; pulse.stroke()
    }
}
