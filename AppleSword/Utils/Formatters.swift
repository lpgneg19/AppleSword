import Foundation

struct ByteCountFormatterUtil {
    static func string(fromByteCount count: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: count)
    }
}
