// FTMSParser.swift
// 解析 FTMS Cross Trainer Data (UUID 0x2ACE)
// 逻辑与 merach_combined.py 中 _parse() 完全一致

import Foundation

struct FTMSData {
    var spm: Int             = 0
    var powerW: Int          = 0
    var caloriesKcal: Int    = 0
    var heartRate: Int       = 0
    var elapsedS: Int        = 0
    var currentResistance: Int = 0
}

func parseCrossTrainerData(_ data: Data) -> FTMSData {
    var result = FTMSData()
    guard data.count >= 5 else { return result }

    let bytes = [UInt8](data)

    // 3字节 flags，小端序
    let flags = Int(bytes[0]) | (Int(bytes[1]) << 8) | (Int(bytes[2]) << 16)
    var offset = 3

    // Instantaneous Speed — 跳过 (设备值不可信)
    offset += 2

    // Average Speed
    if flags & (1 << 1) != 0 { offset += 2 }

    // Total Distance (uint24)
    if flags & (1 << 2) != 0 { offset += 3 }

    // Step Count → SPM (uint16 + uint16, 取前两字节)
    if flags & (1 << 3) != 0 {
        if offset + 4 <= data.count {
            result.spm = Int(bytes[offset]) | (Int(bytes[offset + 1]) << 8)
        }
        offset += 4
    }

    // Stride Count → 实际是阻力 × 10
    if flags & (1 << 4) != 0 {
        if offset + 2 <= data.count {
            let raw = Int(bytes[offset]) | (Int(bytes[offset + 1]) << 8)
            result.currentResistance = raw / 10
        }
        offset += 2
    }

    // Elevation Gain
    if flags & (1 << 5) != 0 { offset += 4 }

    // Inclination
    if flags & (1 << 6) != 0 { offset += 4 }

    // Resistance Level
    if flags & (1 << 7) != 0 { offset += 2 }

    // Instantaneous Power (sint16)
    if flags & (1 << 8) != 0 {
        if offset + 2 <= data.count {
            let raw = Int(bytes[offset]) | (Int(bytes[offset + 1]) << 8)
            result.powerW = raw > 32767 ? raw - 65536 : raw
        }
        offset += 2
    }

    // Average Power
    if flags & (1 << 9) != 0 { offset += 2 }

    // Expended Energy (uint16 total + uint16 per-hour + uint8 per-minute)
    if flags & (1 << 10) != 0 {
        if offset + 5 <= data.count {
            result.caloriesKcal = Int(bytes[offset]) | (Int(bytes[offset + 1]) << 8)
        }
        offset += 5
    }

    // Heart Rate
    if flags & (1 << 11) != 0 {
        if offset + 1 <= data.count {
            result.heartRate = Int(bytes[offset])
        }
        offset += 1
    }

    // Metabolic Equivalent
    if flags & (1 << 12) != 0 { offset += 1 }

    // Elapsed Time
    if flags & (1 << 13) != 0 {
        if offset + 2 <= data.count {
            result.elapsedS = Int(bytes[offset]) | (Int(bytes[offset + 1]) << 8)
        }
    }

    return result
}
