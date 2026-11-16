import SwiftUI
import UniformTypeIdentifiers

struct FilesView: View {
    @StateObject private var model = FilePickerModel()
    @State private var showPicker = false
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Pick files from iCloud Drive or On My iPhone. Sift can only see the files you choose.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)

                    if model.files.isEmpty {
                        Card {
                            VStack(spacing: 16) {
                                EmptyState(
                                    symbol: "folder",
                                    title: "No files chosen",
                                    message: "Use the picker to add large downloads, archives, exports or old documents."
                                )
                                Button("Choose files") { showPicker = true }
                                    .buttonStyle(SecondaryButtonStyle())
                            }
                            .padding(.vertical, 8)
                        }
                    } else {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(Format.count(model.files.count, "file"))
                                    .font(.headline)
                                    .foregroundStyle(Theme.ink)
                                Text(Format.bytes(model.files.reduce(0) { $0 + $1.bytes }) + " chosen")
                                    .font(.footnote)
                                    .foregroundStyle(Theme.secondaryInk)
                            }
                            Spacer()
                            Button("Choose more") { showPicker = true }
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Theme.ink)
                                .padding(.horizontal, 14)
                                .frame(height: 36)
                                .background(Capsule().fill(Theme.card))
                        }

                        Card(padding: 0) {
                            VStack(spacing: 0) {
                                ForEach(model.files) { file in
                                    fileRow(file)
                                    if file.id != model.files.last?.id {
                                        Rectangle()
                                            .fill(Theme.separator)
                                            .frame(height: 0.5)
                                            .padding(.leading, 66)
                                    }
                                }
                            }
                        }

                        Text("Deleting removes a file from its folder. iCloud Drive may keep a Recently Deleted copy; files stored locally do not.")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, Theme.margin)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Files & documents")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            if !model.files.isEmpty {
                SelectionBar(
                    count: model.selected.count,
                    bytes: model.selectedBytes,
                    actionTitle: "Delete files",
                    action: { showDeleteConfirm = true },
                    isBusy: model.isDeleting,
                    note: "Files are removed from their folder. There is no Trash in Sift."
                )
            }
        }
        .fileImporter(
            isPresented: $showPicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                model.add(urls)
            case .failure(let error):
                model.errorMessage = error.localizedDescription
            }
        }
        .alert("Delete selected files?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { model.deleteSelected() }
        } message: {
            Text("This removes \(Format.count(model.selected.count, "file")) (\(Format.bytes(model.selectedBytes))) from their folders. It cannot be undone inside Sift.")
        }
        .alert(
            "Could not finish",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )
        ) {
            Button("OK") { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
        .onDisappear { model.releaseScopes() }
    }

    private func fileRow(_ file: PickedFile) -> some View {
        HStack(spacing: 12) {
            Button {
                model.toggle(file.id)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: icon(for: file))
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Theme.fill))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(file.name)
                            .font(.body.weight(.medium))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Text(file.bytes > 0 ? Format.bytes(file.bytes) : "Size unavailable")
                            .font(.footnote.monospacedDigit())
                            .foregroundStyle(Theme.secondaryInk)
                    }

                    Spacer(minLength: 8)

                    ZStack {
                        Circle()
                            .fill(model.selected.contains(file.id) ? Theme.ink : Theme.fill)
                        if model.selected.contains(file.id) {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Theme.background)
                        }
                    }
                    .frame(width: 26, height: 26)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(file.name)
            .accessibilityValue(model.selected.contains(file.id) ? "Selected" : "Not selected")

            Button {
                model.remove(file)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.secondaryInk)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(file.name) from the list")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func icon(for file: PickedFile) -> String {
        let type = UTType(filenameExtension: file.url.pathExtension)
        if type?.conforms(to: .movie) == true { return "film" }
        if type?.conforms(to: .image) == true { return "photo" }
        if type?.conforms(to: .audio) == true { return "waveform" }
        if type?.conforms(to: .archive) == true { return "archivebox" }
        if type?.conforms(to: .pdf) == true { return "doc.richtext" }
        return "doc"
    }
}
