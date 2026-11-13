import Foundation

struct PickedFile: Identifiable, Equatable {
    let id: String
    let url: URL
    let name: String
    let bytes: Int64
}

@MainActor
final class FilePickerModel: ObservableObject {
    @Published private(set) var files: [PickedFile] = []
    @Published var selected: Set<String> = []
    @Published var errorMessage: String?
    @Published private(set) var isDeleting = false

    private var scopedIDs: Set<String> = []

    var selectedBytes: Int64 {
        files.filter { selected.contains($0.id) }.reduce(0) { $0 + $1.bytes }
    }

    func add(_ urls: [URL]) {
        var skippedFolder = false
        for url in urls {
            let id = url.standardizedFileURL.path
            if files.contains(where: { $0.id == id }) { continue }

            let scoped = url.startAccessingSecurityScopedResource()
            let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey, .nameKey])
            if values?.isDirectory == true {
                if scoped { url.stopAccessingSecurityScopedResource() }
                skippedFolder = true
                continue
            }

            if scoped { scopedIDs.insert(id) }
            files.append(
                PickedFile(
                    id: id,
                    url: url,
                    name: values?.name ?? url.lastPathComponent,
                    bytes: Int64(values?.fileSize ?? 0)
                )
            )
        }
        files.sort { $0.bytes > $1.bytes }
        if skippedFolder {
            errorMessage = "Folders are not supported. Pick individual files."
        }
    }

    func toggle(_ id: String) {
        if selected.contains(id) {
            selected.remove(id)
        } else {
            selected.insert(id)
        }
        Haptics.selection()
    }

    func remove(_ file: PickedFile) {
        releaseScope(file.id)
        files.removeAll { $0.id == file.id }
        selected.remove(file.id)
    }

    func deleteSelected() {
        guard !selected.isEmpty, !isDeleting else { return }
        isDeleting = true
        var failures = 0
        let targets = files.filter { selected.contains($0.id) }
        for file in targets {
            do {
                try FileManager.default.removeItem(at: file.url)
                releaseScope(file.id)
                files.removeAll { $0.id == file.id }
                selected.remove(file.id)
            } catch {
                failures += 1
            }
        }
        isDeleting = false
        if failures > 0 {
            errorMessage = "\(failures) file\(failures == 1 ? "" : "s") could not be deleted. They may be read-only, still downloading from iCloud, or managed by another app."
        } else {
            Haptics.success()
        }
    }

    func releaseScopes() {
        for id in scopedIDs {
            if let file = files.first(where: { $0.id == id }) {
                file.url.stopAccessingSecurityScopedResource()
            }
        }
        scopedIDs.removeAll()
    }

    private func releaseScope(_ id: String) {
        guard scopedIDs.contains(id), let file = files.first(where: { $0.id == id }) else { return }
        file.url.stopAccessingSecurityScopedResource()
        scopedIDs.remove(id)
    }
}
