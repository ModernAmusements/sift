import Foundation

enum Format {
    /// Human-friendly decimal size, e.g. "4.2 MB". Uses megabytes, not mebibytes.
    static func bytes(_ value: Int64) -> String {
        guard value > 0 else { return "—" }
        let units = ["B", "KB", "MB", "GB", "TB"]
        var amount = Double(value)
        var index = 0
        while amount >= 1000 && index < units.count - 1 {
            amount /= 1000
            index += 1
        }
        if index == 0 {
            return "\(Int(amount)) B"
        }
        let digits = amount >= 100 ? 0 : 1
        return String(format: "%.\(digits)f %@", amount, units[index])
    }

    static func count(_ value: Int, _ singular: String, _ plural: String? = nil) -> String {
        "\(value) \(value == 1 ? singular : (plural ?? singular + "s"))"
    }

    static func duration(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds > 0 else { return "—" }
        let total = Int(seconds.rounded())
        let minutes = total / 60
        let secs = total % 60
        if minutes >= 60 {
            return String(format: "%d:%02d:%02d", minutes / 60, minutes % 60, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }

    static func date(_ date: Date?) -> String {
        guard let date else { return "Date unknown" }
        return date.formatted(.dateTime.day().month(.abbreviated).year())
    }
}

enum ContactNormalizer {
    static func digits(_ value: String) -> String {
        value.filter(\.isNumber)
    }

    /// Last 8 digits is enough to match the same number with different country/format codes.
    /// Anything shorter than 7 digits is too ambiguous to merge on.
    static func phoneKey(_ value: String) -> String? {
        let normalized = digits(value)
        guard normalized.count >= 7 else { return nil }
        return String(normalized.suffix(8))
    }

    static func emailKey(_ value: String) -> String? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalized.contains("@"), normalized.count >= 5 else { return nil }
        return normalized
    }

    static func displayName(given: String, family: String, organization: String) -> String {
        let person = [given, family].filter { !$0.isEmpty }.joined(separator: " ")
        if !person.isEmpty { return person }
        return organization.isEmpty ? "No name" : organization
    }
}
