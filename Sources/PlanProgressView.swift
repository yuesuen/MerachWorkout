// PlanProgressView.swift
// 训练计划进度条：各阶段彩色色块 + 当前进度竖线 + 当前阶段高亮

import UIKit

class PlanProgressView: UIView {

    // MARK: - 公开属性
    var currentSecs: Double = 0 {
        didSet { updateProgress() }
    }
    var phaseIndex: Int = 0 {
        didSet { updatePhaseHighlight() }
    }

    // MARK: - 私有 UI
    private let phaseLabel = UILabel()   // "段1 (阻力10)  已过 01:23 / 剩余 04:19"
    private let progressLine = UIView()
    private var phaseLayers:    [CALayer]       = []
    private var phaseRects:     [CGRect]        = []   // 归一化 x (0..1)
    private let highlightLayer  = CALayer()

    private let bgColor = UIColor(hex: "#16213e")

    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setup() {
        backgroundColor = bgColor
        layer.cornerRadius = 8
        layer.masksToBounds = false   // 允许 phaseLabel 画在外面的情况

        // 高亮层
        highlightLayer.backgroundColor = UIColor.white.withAlphaComponent(0.18).cgColor
        highlightLayer.cornerRadius = 4
        layer.addSublayer(highlightLayer)

        // 阶段色块 + 文字
        buildPhaseLayers()

        // 进度竖线
        progressLine.backgroundColor = .white
        progressLine.layer.cornerRadius = 1
        addSubview(progressLine)

        // 阶段信息文字 (显示在进度条上方)
        phaseLabel.textColor     = .white
        phaseLabel.font          = UIFont.boldSystemFont(ofSize: 12)
        phaseLabel.textAlignment = .left
        addSubview(phaseLabel)
    }

    private func buildPhaseLayers() {
        // 清除旧的
        phaseLayers.forEach { $0.removeFromSuperlayer() }
        phaseLayers.removeAll()

        let total = Double(kTotalSecs)
        var cursor = 0.0

        for seg in workoutPlan {
            let xFrac = cursor / total
            let wFrac = Double(seg.duration) / total

            // 色块
            let segLayer = CALayer()
            segLayer.backgroundColor = (resistanceColors[seg.resistance] ?? UIColor.gray)
                                        .withAlphaComponent(0.6).cgColor
            segLayer.cornerRadius = 3
            layer.insertSublayer(segLayer, below: highlightLayer)
            phaseLayers.append(segLayer)

            // 阶段名 label (段1, 热身 …)
            let nameLabel = UILabel()
            nameLabel.text          = seg.name
            nameLabel.textColor     = .white
            nameLabel.font          = UIFont.boldSystemFont(ofSize: 9)
            nameLabel.textAlignment = .center
            addSubview(nameLabel)

            // 阻力标签
            let resLabel = UILabel()
            resLabel.text          = "R\(seg.resistance)"
            resLabel.textColor     = UIColor(white: 0.9, alpha: 0.85)
            resLabel.font          = UIFont.systemFont(ofSize: 8)
            resLabel.textAlignment = .center
            addSubview(resLabel)

            // 存归一化起点/宽度，layoutSubviews 时计算像素位置
            phaseRects.append(CGRect(x: xFrac, y: 0, width: wFrac, height: 1))
            cursor += Double(seg.duration)
        }
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        let barTop:    CGFloat = 26
        let barHeight: CGFloat = bounds.height - barTop - 14
        let w = bounds.width

        // 阶段标签文字的子视图列表（名称 + 阻力交替）
        var labelIdx = 0
        let labelSubviews = subviews.filter { $0 is UILabel && $0 !== phaseLabel }

        for (i, frac) in phaseRects.enumerated() {
            let x = frac.minX * w
            let sw = frac.width * w

            // 色块
            let layerFrame = CGRect(x: x, y: barTop, width: sw, height: barHeight)
            phaseLayers[i].frame = layerFrame

            // 名称 label
            if labelIdx < labelSubviews.count {
                labelSubviews[labelIdx].frame = CGRect(
                    x: x, y: barTop + barHeight * 0.6,
                    width: sw, height: 14)
                labelIdx += 1
            }
            // 阻力 label
            if labelIdx < labelSubviews.count {
                labelSubviews[labelIdx].frame = CGRect(
                    x: x, y: barTop + 2,
                    width: sw, height: 12)
                labelIdx += 1
            }
        }

        // 高亮层初始位置
        updatePhaseHighlight()

        // 进度线初始位置
        updateProgress()

        // 阶段信息文字
        phaseLabel.frame = CGRect(x: 8, y: 2, width: w - 16, height: 22)
    }

    // MARK: - 动态更新

    private func updateProgress() {
        let frac = min(1, Double(currentSecs) / Double(kTotalSecs))
        let x = bounds.width * CGFloat(frac)
        progressLine.frame = CGRect(x: x - 1, y: 24, width: 2, height: bounds.height - 24 - 10)
    }

    private func updatePhaseHighlight() {
        guard phaseIndex < phaseRects.count else { return }
        let frac = phaseRects[phaseIndex]
        let x  = frac.minX * bounds.width
        let sw = frac.width * bounds.width
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        highlightLayer.frame = CGRect(x: x, y: 26, width: sw, height: bounds.height - 26 - 14)
        CATransaction.commit()
    }

    func updatePhaseLabel(name: String, resistance: Int,
                          elapsed: Double, remaining: Double) {
        phaseLabel.text = "\(name)  (阻力\(resistance))  " +
                          "已过 \(formatTime(elapsed)) / 剩余 \(formatTime(remaining))"
    }
}
