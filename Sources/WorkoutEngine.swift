// WorkoutEngine.swift
// BLE 连接 + 训练计划执行 + 数据累计
// iOS 10 兼容: 使用 Timer + 回调, 不使用 async/await

import Foundation
import CoreBluetooth
import UIKit

// MARK: - FTMS UUIDs
private let kFTMSService      = CBUUID(string: "00001826-0000-1000-8000-00805f9b34fb")
private let kCrossTrainer     = CBUUID(string: "00002ace-0000-1000-8000-00805f9b34fb")
private let kControlPoint     = CBUUID(string: "00002ad9-0000-1000-8000-00805f9b34fb")
private let kStatus           = CBUUID(string: "00002ada-0000-1000-8000-00805f9b34fb")

// MARK: - Delegate
protocol WorkoutEngineDelegate: AnyObject {
    func engineDidConnect()
    func engineDidDisconnect()
    func engineDidTick()           // 每秒调用，刷新 UI
}

// MARK: - WorkoutEngine
class WorkoutEngine: NSObject {

    weak var delegate: WorkoutEngineDelegate?

    // ── 连接状态 ──────────────────────────────
    private(set) var isConnected    = false
    private(set) var workoutStarted = false
    private(set) var workoutDone    = false
    private      var demoMode       = false

    // ── 设备当前数据 ──────────────────────────
    private(set) var currentData = FTMSData()

    // ── 历史曲线（最多 3600 个点）─────────────
    private let maxHistory = 3600
    private(set) var timestamps:       [Double] = []
    private(set) var spmHistory:       [Double] = []
    private(set) var speedHistory:     [Double] = []
    private(set) var powerHistory:     [Double] = []
    private(set) var calHistory:       [Double] = []
    private(set) var stepsHistory:     [Double] = []
    private(set) var distanceHistory:  [Double] = []
    private(set) var resistanceHistory:[Double] = []

    // ── 累计值 ────────────────────────────────
    private(set) var totalSteps:      Double = 0
    private(set) var totalDistM:      Double = 0
    private(set) var workoutElapsed:  Double = 0

    // ── 当前训练阶段 ──────────────────────────
    private(set) var phaseIndex:   Int    = 0
    private(set) var phaseElapsed: Double = 0
    private(set) var phaseName:    String = ""
    private(set) var phaseResist:  Int    = 0
    private(set) var phaseTotal:   Int    = 0

    // ── 内部状态 ──────────────────────────────
    private var spmWindow:      [Int]  = []
    private var tickTimer:      Timer?
    private var phaseTimer:     Timer?
    private var phaseStartDate: Date?
    private var tickLastDate:   Date?

    // ── BLE ───────────────────────────────────
    private var central:           CBCentralManager?
    private var peripheral:        CBPeripheral?
    private var cpCharacteristic:  CBCharacteristic?
    private var cpCompletion:      ((Bool) -> Void)?

    // MARK: - 启动

    func start(demo: Bool = false) {
        demoMode = demo
        if demo {
            runDemo()
        } else {
            central = CBCentralManager(delegate: self, queue: .main)
        }
    }

    func stop() {
        tickTimer?.invalidate(); tickTimer = nil
        phaseTimer?.invalidate(); phaseTimer = nil
        peripheral.map { central?.cancelPeripheralConnection($0) }
    }

    // MARK: - Tick（每秒）

    @objc private func onTick() {
        let now = Date()
        let dt: Double
        if let last = tickLastDate {
            dt = now.timeIntervalSince(last)
        } else {
            dt = 1.0
        }
        tickLastDate = now

        let rawSpm = currentData.spm
        spmWindow.append(rawSpm)
        if spmWindow.count > 5 { spmWindow.removeFirst() }
        let nonZero = spmWindow.filter { $0 > 0 }
        let spm = nonZero.isEmpty ? 0 : Int(round(Double(nonZero.reduce(0, +)) / Double(nonZero.count)))

        if rawSpm > 0 {
            let steps = Double(rawSpm) * 2.0 / 60.0 * dt
            totalSteps += steps
            totalDistM += steps * kStrideLength
        }
        let speed = spm > 0 ? Double(spm) * 2.0 * kStrideLength * 60.0 / 1000.0 : 0.0

        workoutElapsed += dt

        func push(_ arr: inout [Double], _ v: Double) {
            arr.append(v)
            if arr.count > maxHistory { arr.removeFirst() }
        }
        push(&timestamps,        workoutElapsed)
        push(&spmHistory,        Double(spm))
        push(&speedHistory,      speed)
        push(&powerHistory,      Double(currentData.powerW))
        push(&calHistory,        Double(currentData.caloriesKcal))
        push(&stepsHistory,      totalSteps)
        push(&distanceHistory,   totalDistM / 1000.0)
        push(&resistanceHistory, Double(currentData.currentResistance))

        delegate?.engineDidTick()
    }

    // MARK: - 训练计划（Timer 驱动）

    private func startWorkout() {
        workoutStarted = true
        advanceToPhase(0)
    }

    private func advanceToPhase(_ index: Int) {
        guard index < workoutPlan.count else {
            workoutDone = true
            phaseTimer?.invalidate(); phaseTimer = nil
            return
        }
        phaseTimer?.invalidate()

        let seg = workoutPlan[index]
        phaseIndex   = index
        phaseName    = seg.name
        phaseResist  = seg.resistance
        phaseTotal   = seg.duration
        phaseElapsed = 0
        phaseStartDate = Date()

        setResistance(seg.resistance) { _ in }

        phaseTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.phaseStartDate else { return }
            self.phaseElapsed = Date().timeIntervalSince(start)
            if self.phaseElapsed >= Double(seg.duration) {
                self.advanceToPhase(index + 1)
            }
        }
    }

    // MARK: - 阻力控制

    func setResistance(_ level: Int, completion: @escaping (Bool) -> Void) {
        let l = max(1, min(32, level))

        if demoMode {
            currentData.currentResistance = l
            completion(true)
            return
        }

        guard let char = cpCharacteristic, let p = peripheral else {
            completion(false); return
        }

        let v = l * 10
        var data: Data
        if v <= 255 {
            data = Data([0x04, UInt8(v)])
        } else {
            data = Data([0x04])
            var val = UInt16(v).littleEndian
            withUnsafeBytes(of: &val) { data.append(contentsOf: $0) }
        }

        cpCompletion = completion
        p.writeValue(data, for: char, type: .withResponse)

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self, let comp = self.cpCompletion else { return }
            self.cpCompletion = nil
            comp(false)
        }
    }

    // MARK: - Demo 模式

    private func runDemo() {
        isConnected = true
        delegate?.engineDidConnect()

        tickLastDate = Date()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // 模拟传感器数据
            let t = self.workoutElapsed
            let base = 65.0 + 6.0 * sin(t / 40.0)
            let noise = Double.random(in: -4.0...4.0)
            self.currentData.spm = max(0, Int(base + noise))
            let res = self.currentData.currentResistance > 0 ? self.currentData.currentResistance : 10
            self.currentData.powerW = Int(Double(res) * 4.8 + Double.random(in: -8.0...8.0))
            self.currentData.caloriesKcal = Int(self.workoutElapsed * 0.18)
            self.onTick()
        }
        startWorkout()
    }
}

// MARK: - CBCentralManagerDelegate
extension WorkoutEngine: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else { return }
        central.scanForPeripherals(withServices: [kFTMSService], options: nil)
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        self.peripheral = peripheral
        central.stopScan()
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([kFTMSService])
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        isConnected = false
        tickTimer?.invalidate(); tickTimer = nil
        phaseTimer?.invalidate(); phaseTimer = nil
        delegate?.engineDidDisconnect()
    }
}

// MARK: - CBPeripheralDelegate
extension WorkoutEngine: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let svc = peripheral.services?.first(where: { $0.uuid == kFTMSService }) else { return }
        peripheral.discoverCharacteristics([kCrossTrainer, kControlPoint, kStatus], for: svc)
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        for char in service.characteristics ?? [] {
            switch char.uuid {
            case kCrossTrainer:
                peripheral.setNotifyValue(true, for: char)
            case kControlPoint:
                cpCharacteristic = char
                peripheral.setNotifyValue(true, for: char)
            case kStatus:
                peripheral.setNotifyValue(true, for: char)
            default: break
            }
        }

        guard cpCharacteristic != nil else { return }

        // 请求控制权
        cpCompletion = { [weak self] _ in
            // 不管控制权是否获取成功都继续（部分设备不响应 REQUEST_CONTROL）
            guard let self = self else { return }
            self.isConnected = true
            self.delegate?.engineDidConnect()
            self.tickLastDate = Date()
            self.tickTimer = Timer.scheduledTimer(
                withTimeInterval: 1.0, repeats: true) { [weak self] _ in self?.onTick() }
            self.startWorkout()
        }
        peripheral.writeValue(Data([0x00]), for: cpCharacteristic!, type: .withResponse)
        // 2 秒后若无响应也直接继续
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self = self, let comp = self.cpCompletion else { return }
            self.cpCompletion = nil
            comp(false)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard let data = characteristic.value else { return }

        if characteristic.uuid == kCrossTrainer {
            let parsed = parseCrossTrainerData(data)
            if parsed.spm > 0              { currentData.spm              = parsed.spm }
            if parsed.powerW != 0          { currentData.powerW           = parsed.powerW }
            if parsed.caloriesKcal > 0     { currentData.caloriesKcal     = parsed.caloriesKcal }
            if parsed.currentResistance > 0 { currentData.currentResistance = parsed.currentResistance }
            if parsed.elapsedS > 0         { currentData.elapsedS         = parsed.elapsedS }
        }

        // Control Point indication 响应
        if characteristic.uuid == kControlPoint {
            let bytes = [UInt8](data)
            if bytes.count >= 3 && bytes[0] == 0x80 {
                let success = bytes[2] == 0x01
                let comp = cpCompletion
                cpCompletion = nil
                comp?(success)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {}
}
