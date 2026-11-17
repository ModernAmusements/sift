import Contacts
import SwiftUI

struct ContactsView: View {
    @EnvironmentObject private var engine: ScanEngine
    @Environment(\.scenePhase) private var scenePhase

    @State private var isLoading = false
    @State private var status = ContactService.status
    @State private var pendingGroup: ContactGroup?
    @State private var showMergeAll = false
    @State private var mergeNote: String?
    @State private var appeared = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    if isLoading || (status == .authorized && !engine.contactsLoaded) {
                        loadingCard
                    } else if status == .denied || status == .restricted || engine.contactsDenied {
                        deniedCard
                    } else if status == .notDetermined {
                        requestCard
                    } else {
                        content
                    }
                }
                .padding(.horizontal, Theme.margin)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Duplicate contacts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            if !engine.contactGroups.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Merge all") { showMergeAll = true }
                        .font(Typo.footnoteSemibold)
                        .foregroundStyle(Theme.ink)
                }
            }
        }
        .sheet(item: $pendingGroup) { group in
            ContactMergeSheet(group: group)
                .environmentObject(engine)
        }
        .alert("Merge all duplicate cards?", isPresented: $showMergeAll) {
            Button("Cancel", role: .cancel) {}
            Button("Merge", role: .destructive) {
                Task {
                    let merged = await engine.mergeAllContacts()
                    if merged > 0 { mergeNote = "Merged \(merged) cards." }
                }
            }
        } message: {
            Text("Sift keeps the richest card in each group and copies missing phone numbers, emails and photos into it. The other cards are deleted from Contacts and sync to iCloud if Contacts sync is on.")
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { engine.errorMessage != nil },
                set: { if !$0 { engine.dismissError() } }
            )
        ) {
            Button("OK") { engine.dismissError() }
        } message: {
            Text(engine.errorMessage ?? "")
        }
        .overlay(alignment: .bottom) {
            if let mergeNote {
                Text(mergeNote)
                    .font(Typo.footnoteMedium)
                    .foregroundStyle(Theme.background)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Theme.ink))
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task {
                        try? await Task.sleep(for: .seconds(2.4))
                        withAnimation(.snappy) { self.mergeNote = nil }
                    }
            }
        }
        .onAppear {
            appeared = true
            status = ContactService.status
            if status == .authorized && !engine.contactsLoaded {
                load(requestAccess: false)
            }
        }
        .animation(.snappy(duration: 0.3), value: engine.contactGroups.count)
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            status = ContactService.status
        }
    }

    private var loadingCard: some View {
        Card {
            VStack(spacing: 14) {
                ProgressView()
                Text("Looking through your contacts")
                    .font(Typo.headline)
                    .foregroundStyle(Theme.ink)
                Text("Only shared phone numbers and emails are compared.")
                    .font(Typo.footnote)
                    .foregroundStyle(Theme.secondaryInk)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
    }

    private var requestCard: some View {
        PermissionState(
            symbol: "person.2",
            title: "Duplicates hide in Contacts",
            message: "Sift can merge repeated cards into one. It only reads names, phone numbers, emails and photos, and it never uploads them.",
            primaryTitle: "Find duplicate contacts",
            primaryAction: { load(requestAccess: true) }
        )
    }

    private var deniedCard: some View {
        PermissionState(
            symbol: "person.crop.circle.badge.exclamationmark",
            title: "Contacts access is off",
            message: "Allow Contacts access in Settings to find repeated cards. Everything stays on this iPhone.",
            primaryTitle: "Open Settings",
            primaryAction: openSettings
        )
    }

    @ViewBuilder
    private var content: some View {
        if engine.contactGroups.isEmpty {
            EmptyState(
                symbol: "person.crop.circle.badge.checkmark",
                title: "No duplicates found",
                message: "Your contact list is already tidy."
            )
        } else {
            summary
            ForEach(Array(engine.contactGroups.enumerated()), id: \.element.id) { index, group in
                Button {
                    Haptics.selection()
                    pendingGroup = group
                } label: {
                    groupCard(group)
                }
                .buttonStyle(PressableStyle())
                .riseIn(appeared, index: index + 1)
            }
            Text("Merging deletes the extra cards from Contacts. There is no Recently Deleted for contacts.")
                .font(Typo.caption)
                .foregroundStyle(Theme.secondaryInk)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
        }
    }

    private var summary: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(Format.count(engine.contactGroups.count, "group"))
                    .font(Typo.headline)
                    .foregroundStyle(Theme.ink)
                Text("\(Format.count(engine.contactGroups.reduce(0) { $0 + $1.removableCount }, "extra card")) to merge")
                    .font(Typo.footnote)
                    .foregroundStyle(Theme.secondaryInk)
            }
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private func groupCard(_ group: ContactGroup) -> some View {
        Card {
            HStack(spacing: 14) {
                avatar(group.keeper)
                VStack(alignment: .leading, spacing: 3) {
                    Text(group.title)
                        .font(Typo.bodyMedium)
                        .foregroundStyle(Theme.ink)
                    Text("\(Format.count(group.contacts.count, "card")) · \(group.keeper?.subtitle ?? "")")
                        .font(Typo.footnote)
                        .foregroundStyle(Theme.secondaryInk)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Text("Merge")
                    .font(Typo.footnoteSemibold)
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(Capsule().fill(Theme.fill))
                Image(systemName: "chevron.right")
                    .font(Typo.captionSemibold)
                    .foregroundStyle(Theme.tertiaryInk)
            }
        }
    }

    @ViewBuilder
    private func avatar(_ record: ContactRecord?) -> some View {
        if let data = record?.imageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
        } else {
            Text(record?.initials ?? "?")
                .font(Typo.subheadlineSemibold)
                .foregroundStyle(Theme.ink)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Theme.fill))
        }
    }

    private func load(requestAccess: Bool) {
        guard !isLoading else { return }
        isLoading = true
        Task {
            await engine.loadContacts(requestAccess: requestAccess)
            isLoading = false
            status = ContactService.status
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

struct ContactMergeSheet: View {
    let group: ContactGroup

    @EnvironmentObject private var engine: ScanEngine
    @Environment(\.dismiss) private var dismiss
    @State private var isMerging = false
    @State private var showConfirm = false

    private var keeper: ContactRecord? { group.keeper }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(group.title)
                            .font(Typo.title2Semibold)
                            .foregroundStyle(Theme.ink)
                        Text("One card is kept. Missing numbers, emails and the photo are copied into it.")
                            .font(Typo.subheadline)
                            .foregroundStyle(Theme.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 0) {
                        ForEach(group.contacts) { contact in
                            row(contact)
                            if contact.id != group.contacts.last?.id {
                                Rectangle()
                                    .fill(Theme.separator)
                                    .frame(height: 0.5)
                                    .padding(.leading, 58)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                            .fill(Theme.card)
                    )

                    Text("The other cards are deleted from Contacts. If Contacts syncs to iCloud, the deletion syncs too. This cannot be undone inside Sift.")
                        .font(Typo.caption)
                        .foregroundStyle(Theme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Theme.margin)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Merge contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    showConfirm = true
                } label: {
                    HStack(spacing: 8) {
                        if isMerging { ProgressView().tint(Theme.background) }
                        Text(isMerging ? "Merging…" : "Merge \(group.removableCount) duplicate card\(group.removableCount == 1 ? "" : "s")")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isMerging)
                .padding(.horizontal, Theme.margin)
                .padding(.bottom, 8)
            }
            .alert("Merge these cards?", isPresented: $showConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Merge", role: .destructive) { merge() }
            } message: {
                Text("Sift keeps \(keeper?.name ?? "the richest card") and deletes \(group.removableCount) other card\(group.removableCount == 1 ? "" : "s").")
            }
        }
    }

    private func row(_ contact: ContactRecord) -> some View {
        HStack(spacing: 12) {
            avatar(contact)
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(Typo.bodyMedium)
                    .foregroundStyle(Theme.ink)
                Text(contact.subtitle)
                    .font(Typo.footnote)
                    .foregroundStyle(Theme.secondaryInk)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if contact.id == keeper?.id {
                Text("Kept")
                    .font(Typo.captionSemibold)
                    .foregroundStyle(Theme.reclaim)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Theme.reclaim.opacity(0.12)))
            } else {
                Text("Merged")
                    .font(Typo.caption)
                    .foregroundStyle(Theme.tertiaryInk)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func avatar(_ contact: ContactRecord) -> some View {
        if let data = contact.imageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 34, height: 34)
                .clipShape(Circle())
        } else {
            Text(contact.initials)
                .font(Typo.captionSemibold)
                .foregroundStyle(Theme.ink)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Theme.fill))
        }
    }

    private func merge() {
        guard !isMerging else { return }
        isMerging = true
        Task {
            let succeeded = await engine.merge(group)
            isMerging = false
            if succeeded { dismiss() }
        }
    }
}
