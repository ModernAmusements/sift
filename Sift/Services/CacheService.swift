import Foundation

enum CacheService {
    static func bytes() -> Int64 {
        directories.reduce(Int64(0)) { $0 + size(of: $1) }
    }

    static func clear() throws {
        let manager = FileManager.default
        for directory in directories {
            let contents = (try? manager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil
            )) ?? []
            for item in contents {
                try manager.removeItem(at: item)
            }
        }
    }

    private static var directories: [URL] {
        let manager = FileManager.default
        let caches = manager.urls(for: .cachesDirectory, in: .userDomainMask).first
        return [caches, manager.temporaryDirectory].compactMap { $0 }
    }

    private static func size(of directory: URL) -> Int64 {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }
        var total: Int64 = 0
        for case let url as URL in enumerator {
            let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
            guard values?.isRegularFile == true else { continue }
            total += Int64(values?.fileSize ?? 0)
        }
        return total
    }
}
