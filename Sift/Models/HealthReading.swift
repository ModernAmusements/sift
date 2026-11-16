import Foundation

/// What iOS will tell an app about why a phone feels slow. Nothing more is claimed.
struct HealthRow: Identifiable, Equatable {
    enum Kind: String, Equatable {
        case headroom
        case lowPowerMode
        case thermal
        case library
        case battery
    }

    let kind: Kind
    let title: String
    let value: String
    let note: String?
    let isNotable: Bool

    var id: String { kind.rawValue }
}

enum Headroom: Equatable {
    case critical
    case tight
    case comfortable

    static let criticalBytes: Int64 = 1_000_000_000
    static let tightBytes: Int64 = 5_000_000_000

    static func level(freeBytes: Int64) -> Headroom {
        if freeBytes < criticalBytes { return .critical }
        if freeBytes < tightBytes { return .tight }
        return .comfortable
    }

    /// One word, so the row never depends on colour alone.
    var word: String {
        switch self {
        case .critical: return "Critical"
        case .tight: return "Tight"
        case .comfortable: return "Fine"
        }
    }
}

enum HealthReading {
    /// Built from measurements only. This is a diagnosis, never a fix.
    static func rows(
        freeBytes: Int64,
        totalBytes: Int64,
        lowPowerMode: Bool,
        thermalState: ProcessInfo.ThermalState,
        libraryBytes: Int64?,
        libraryAssetCount: Int?
    ) -> [HealthRow] {
        var rows: [HealthRow] = []

        let level = Headroom.level(freeBytes: freeBytes)
        let free = Format.bytes(freeBytes)
        let total = totalBytes > 0 ? Format.bytes(totalBytes) : nil
        let amount = total.map { "\(free) of \($0)" } ?? free
        rows.append(
            HealthRow(
                kind: .headroom,
                title: "Free space",
                value: level == .comfortable ? amount : "\(amount) · \(level.word)",
                note: headroomNote(level),
                isNotable: level != .comfortable
            )
        )

        rows.append(
            HealthRow(
                kind: .lowPowerMode,
                title: "Low Power Mode",
                value: lowPowerMode ? "On" : "Off",
                note: lowPowerMode ? "iOS is holding back background work to save battery." : nil,
                isNotable: lowPowerMode
            )
        )

        rows.append(
            HealthRow(
                kind: .thermal,
                title: "Temperature",
                value: thermalWord(thermalState),
                note: thermalNote(thermalState),
                isNotable: thermalState == .serious || thermalState == .critical
            )
        )

        if let libraryBytes, let libraryAssetCount, libraryAssetCount > 0 {
            rows.append(
                HealthRow(
                    kind: .library,
                    title: "Photos",
                    value: "\(Format.bytes(libraryBytes)) · \(Format.count(libraryAssetCount, "item"))",
                    note: "Screenshots and repeat shots are usually the easy part.",
                    isNotable: false
                )
            )
        }

        rows.append(
            HealthRow(
                kind: .battery,
                title: "Battery health",
                value: "In Settings",
                note: "Sift cannot read it: iOS has no public API. Settings → Battery → Battery Health & Charging.",
                isNotable: false
            )
        )

        return rows
    }

    static func headroomNote(_ level: Headroom) -> String? {
        switch level {
        case .critical:
            return "iOS needs working room. Below about 1 GB the camera can refuse to save and updates stall."
        case .tight:
            return "Below about 5 GB iOS has little room to work with."
        case .comfortable:
            return nil
        }
    }

    static func thermalWord(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "Normal"
        case .fair: return "Warm"
        case .serious: return "Hot"
        case .critical: return "Very hot"
        @unknown default: return "Unknown"
        }
    }

    static func thermalNote(_ state: ProcessInfo.ThermalState) -> String? {
        switch state {
        case .nominal, .fair: return nil
        case .serious, .critical: return "iOS is limiting performance while the phone is warm."
        @unknown default: return nil
        }
    }
}
