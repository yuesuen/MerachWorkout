// MetricChartView.swift
// 单指标折线图 + 大字当前值 + 副指标文字
// 纯 CAShapeLayer 绘制，无第三方依赖，兼容 iOS 10

import UIKit

class MetricChartView: UIView {

    // MARK: - 公开属性
    var lineColor: UIColor = .white {
        didSet { lineLayer.strokeColor = lineColor.cgColor }
    }

    // MARK: - 私有 UI 元素
    private let titleLabel  = UILabel()
    private let valueLabel  = UILabel()
    private let subLabel    = UILabel()
    private let gridLayer   = CAShapeLayer()
    private let lineLayer   = CAShapeLayer()

    private let bgColor   = UIColor(hex: "#16213e")
    private let gridColor = UIColor(hex: "#2a3a5c")

    // MARK: - 数据
    private var dataPoints: [Double] = []

    // MARK: - 初始化
    init(title: String, unit: String, color: UIColor) {
        super.init(frame: .zero)
        lineColor = color
        setupLayers()
        setupLabels(title: title, unit: unit, color: color)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupLayers() {
        backgroundColor = bgColor
        layer.cornerRadius = 8
        layer.masksToBounds = true

        gridLayer.strokeColor = gridColor.cgColor
        gridLayer.fillColor   = UIColor.clear.cgColor
        gridLayer.lineWidth   = 0.5
        layer.addSublayer(gridLayer)

        lineLayer.strokeColor = lineColor.cgColor
        lineLayer.fillColor   = UIColor.clear.cgColor
        lineLayer.lineWidth   = 2.0
        lineLayer.lineJoin    = .round
        lineLayer.lineCap     = .round
        layer.addSublayer(lineLayer)
    }

    private func setupLabels(title: String, unit: String, color: UIColor) {
        // Title
        titleLabel.text          = title
        titleLabel.textColor     = color
        titleLabel.font          = UIFont.boldSystemFont(ofSize: 13)
        titleLabel.textAlignment = .left
        addSubview(titleLabel)

        // Big current value
        valueLabel.text          = "--"
        valueLabel.textColor     = color
        valueLabel.font          = UIFont.monospacedDigitSystemFont(ofSize: 28, weight: .bold)
        valueLabel.textAlignment = .right
        addSubview(valueLabel)

        // Sub label (pace / steps / distance / resistance)
        subLabel.text          = ""
        subLabel.textColor     = UIColor(white: 0.75, alpha: 1)
        subLabel.font          = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        subLabel.textAlignment = .right
        addSubview(subLabel)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        let p: CGFloat = 8
        titleLabel.frame = CGRect(x: p, y: p, width: bounds.width * 0.6, height: 20)
        valueLabel.frame = CGRect(x: bounds.width * 0.5, y: p,
                                  width: bounds.width * 0.5 - p, height: 34)
        subLabel.frame   = CGRect(x: bounds.width * 0.5, y: p + 34,
                                  width: bounds.width * 0.5 - p, height: 18)
        drawGrid()
        drawLine()
    }

    // MARK: - 更新数据

    func update(data: [Double], valueText: String, subText: String) {
        dataPoints = data
        valueLabel.text = valueText
        subLabel.text   = subText
        drawLine()
    }

    // MARK: - 绘制

    private func chartRect() -> CGRect {
        let top: CGFloat    = 64
        let bottom: CGFloat = 14
        let left: CGFloat   = 8
        let right: CGFloat  = 8
        return CGRect(x: left, y: top,
                      width: bounds.width - left - right,
                      height: bounds.height - top - bottom)
    }

    private func drawGrid() {
        let r = chartRect()
        let path = UIBezierPath()
        let lines = 4
        for i in 0...lines {
            let y = r.minY + r.height * CGFloat(i) / CGFloat(lines)
            path.move(to: CGPoint(x: r.minX, y: y))
            path.addLine(to: CGPoint(x: r.maxX, y: y))
        }
        gridLayer.path = path.cgPath
    }

    private func drawLine() {
        guard dataPoints.count >= 2 else { lineLayer.path = nil; return }

        let r = chartRect()
        let nonZero = dataPoints.filter { $0 > 0 }
        guard !nonZero.isEmpty else { lineLayer.path = nil; return }

        let minV = nonZero.min()!
        let maxV = nonZero.max()!
        let range = maxV - minV
        let margin = max(range * 0.15, 1.0)
        let lo = max(0, minV - margin)
        let hi = maxV + margin
        let vRange = hi - lo

        let n = dataPoints.count
        let path = UIBezierPath()
        var started = false

        for (i, v) in dataPoints.enumerated() {
            let x = r.minX + r.width * CGFloat(i) / CGFloat(n - 1)
            let y = r.maxY - r.height * CGFloat(v - lo) / CGFloat(vRange)
            let pt = CGPoint(x: x, y: y)
            if !started { path.move(to: pt); started = true }
            else        { path.addLine(to: pt) }
        }
        lineLayer.path = path.cgPath
    }
}
