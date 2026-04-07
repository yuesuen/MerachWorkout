// ConnectingViewController.swift
// 蓝牙连接等待页：动画 + 取消按钮

import UIKit

class ConnectingViewController: UIViewController {

    private let engine      = WorkoutEngine()
    private let ringViews   = [UIView(), UIView(), UIView()]
    private let iconLabel   = UILabel()
    private let titleLabel  = UILabel()
    private let subLabel    = UILabel()
    private let cancelBtn   = UIButton(type: .custom)

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        engine.delegate = self
        engine.start(demo: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startPulse()
    }

    override var prefersStatusBarHidden: Bool { return true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .landscape }

    private func buildUI() {
        view.backgroundColor = UIColor(hex: "#0d1b2a")

        // 脉冲环
        let colors: [UIColor] = [
            UIColor(hex: "#00d4ff").withAlphaComponent(0.8),
            UIColor(hex: "#00d4ff").withAlphaComponent(0.5),
            UIColor(hex: "#00d4ff").withAlphaComponent(0.3),
        ]
        for (i, ring) in ringViews.enumerated() {
            ring.layer.borderColor = colors[i].cgColor
            ring.layer.borderWidth = 2
            ring.alpha = 0
            view.addSubview(ring)
        }

        // 图标
        iconLabel.text      = "📡"
        iconLabel.font      = UIFont.systemFont(ofSize: 28)
        iconLabel.textAlignment = .center
        view.addSubview(iconLabel)

        // 标题
        titleLabel.text          = "正在搜索麦瑞克椭圆机…"
        titleLabel.font          = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textColor     = .white
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)

        // 副标题
        subLabel.text          = "请确保椭圆机已开机，蓝牙未被其他设备占用"
        subLabel.font          = UIFont.systemFont(ofSize: 12)
        subLabel.textColor     = UIColor(hex: "#888888")
        subLabel.textAlignment = .center
        view.addSubview(subLabel)

        // 取消按钮
        cancelBtn.setTitle("取消", for: .normal)
        cancelBtn.setTitleColor(UIColor(hex: "#888888"), for: .normal)
        cancelBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        cancelBtn.layer.borderColor = UIColor(hex: "#444444").cgColor
        cancelBtn.layer.borderWidth = 1
        cancelBtn.layer.cornerRadius = 16
        cancelBtn.addTarget(self, action: #selector(onCancel), for: .touchUpInside)
        view.addSubview(cancelBtn)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let cx = view.bounds.midX
        let cy = view.bounds.midY

        let sizes: [CGFloat] = [52, 80, 108]
        for (i, ring) in ringViews.enumerated() {
            let sz = sizes[i]
            ring.frame = CGRect(x: cx - sz/2, y: cy - sz/2 - 30, width: sz, height: sz)
            ring.layer.cornerRadius = sz / 2
        }
        iconLabel.frame  = CGRect(x: cx - 20, y: cy - 44,  width: 40, height: 36)
        titleLabel.frame = CGRect(x: cx - 160, y: cy + 10,  width: 320, height: 22)
        subLabel.frame   = CGRect(x: cx - 200, y: cy + 36,  width: 400, height: 18)
        cancelBtn.frame  = CGRect(x: cx - 50,  y: cy + 70,  width: 100, height: 32)
    }

    private func startPulse() {
        let delays: [TimeInterval] = [0, 0.4, 0.8]
        for (i, ring) in ringViews.enumerated() {
            let anim = CABasicAnimation(keyPath: "opacity")
            anim.fromValue    = 0.8
            anim.toValue      = 0.0
            anim.duration     = 1.6
            anim.repeatCount  = .infinity
            anim.beginTime    = CACurrentMediaTime() + delays[i]
            anim.timingFunction = CAMediaTimingFunction(name: .easeOut)
            ring.layer.add(anim, forKey: "pulse")
        }
    }

    @objc private func onCancel() {
        engine.stop()
        dismiss(animated: true)
    }
}

// MARK: - WorkoutEngineDelegate

extension ConnectingViewController: WorkoutEngineDelegate {

    func engineDidConnect() {
        let dash = DashboardViewController(engine: engine)
        dash.modalPresentationStyle = .fullScreen
        dash.modalTransitionStyle   = .crossDissolve
        present(dash, animated: true)
    }

    func engineDidDisconnect() {}
    func engineDidTick() {}
}
