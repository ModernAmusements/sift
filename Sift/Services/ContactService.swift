import Contacts
import Foundation

enum ContactServiceError: LocalizedError {
    case accessDenied
    case mergeFailed

    var errorDescription: String? {
        switch self {
        case .accessDenied: return "Sift needs contact access to merge duplicate cards."
        case .mergeFailed: return "Sift could not merge that contact. Nothing was changed."
        }
    }
}

enum ContactService {
    private static let store = CNContactStore()

    static var status: CNAuthorizationStatus {
        CNContactStore.authorizationStatus(for: .contacts)
    }

    static func requestAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            store.requestAccess(for: .contacts) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    private static var fetchKeys: [CNKeyDescriptor] {
        [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor
        ]
    }

    static func loadGroups() async -> [ContactGroup] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: loadGroupsSync())
            }
        }
    }

    private static func loadGroupsSync() -> [ContactGroup] {
        var contacts: [CNContact] = []
        let request = CNContactFetchRequest(keysToFetch: fetchKeys)
        request.sortOrder = .userDefault
        do {
            try store.enumerateContacts(with: request) { contact, _ in
                contacts.append(contact)
            }
        } catch {
            return []
        }

        guard !contacts.isEmpty else { return [] }
        var union = UnionFind(count: contacts.count)
        var handles: [String: Int] = [:]

        for (index, contact) in contacts.enumerated() {
            for phone in contact.phoneNumbers {
                guard let key = ContactNormalizer.phoneKey(phone.value.stringValue) else { continue }
                let handle = "p:\(key)"
                if let existing = handles[handle] {
                    union.union(index, existing)
                } else {
                    handles[handle] = index
                }
            }
            for email in contact.emailAddresses {
                guard let key = ContactNormalizer.emailKey(email.value as String) else { continue }
                let handle = "e:\(key)"
                if let existing = handles[handle] {
                    union.union(index, existing)
                } else {
                    handles[handle] = index
                }
            }
        }

        var buckets: [Int: [CNContact]] = [:]
        for index in contacts.indices {
            let root = union.find(index)
            buckets[root, default: []].append(contacts[index])
        }

        return buckets.values
            .filter { $0.count >= 2 }
            .map { members in
                let records = members.map(record(from:)).sorted { lhs, rhs in
                    if lhs.fieldCount != rhs.fieldCount { return lhs.fieldCount > rhs.fieldCount }
                    return lhs.name < rhs.name
                }
                return ContactGroup(id: records[0].id, contacts: records)
            }
            .sorted { lhs, rhs in
                if lhs.contacts.count != rhs.contacts.count { return lhs.contacts.count > rhs.contacts.count }
                return lhs.title < rhs.title
            }
    }

    private static func record(from contact: CNContact) -> ContactRecord {
        let name = ContactNormalizer.displayName(
            given: contact.givenName,
            family: contact.familyName,
            organization: contact.organizationName
        )
        let phones = contact.phoneNumbers
            .map { $0.value.stringValue }
            .filter { !ContactNormalizer.digits($0).isEmpty }
        let emails = contact.emailAddresses
            .map { $0.value as String }
            .filter { ContactNormalizer.emailKey($0) != nil }
        let image = contact.thumbnailImageData
        let fields = phones.count + emails.count + (name == "No name" ? 0 : 1) + (image == nil ? 0 : 1)
        return ContactRecord(
            id: contact.identifier,
            name: name,
            phoneNumbers: unique(phones),
            emails: unique(emails),
            imageData: image,
            fieldCount: fields
        )
    }

    private static func unique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }

    /// Merges every member into the richest contact: missing phone numbers, emails and
    /// the photo are copied over, then the redundant cards are deleted in one save.
    @discardableResult
    static func merge(group: ContactGroup) async throws -> Int {
        guard group.contacts.count >= 2 else { return 0 }
        let keys = fetchKeys + [CNContactImageDataKey as CNKeyDescriptor]
        var fetched: [CNContact] = []
        for record in group.contacts {
            if let contact = try? store.unifiedContact(withIdentifier: record.id, keysToFetch: keys) {
                fetched.append(contact)
            }
        }
        guard fetched.count >= 2 else { return 0 }

        let keeperID = group.keeper?.id
        let keeperSource = fetched.first(where: { $0.identifier == keeperID })
            ?? fetched.max { richness($0) < richness($1) }
        guard let keeperSource, let keeper = keeperSource.mutableCopy() as? CNMutableContact else {
            throw ContactServiceError.mergeFailed
        }

        var phoneKeys = Set(keeper.phoneNumbers.compactMap {
            ContactNormalizer.phoneKey($0.value.stringValue)
        })
        var emailKeys = Set(keeper.emailAddresses.compactMap {
            ContactNormalizer.emailKey($0.value as String)
        })

        var removed = 0
        let save = CNSaveRequest()

        for other in fetched where other.identifier != keeper.identifier {
            for phone in other.phoneNumbers {
                guard let key = ContactNormalizer.phoneKey(phone.value.stringValue) else { continue }
                guard !phoneKeys.contains(key) else { continue }
                phoneKeys.insert(key)
                keeper.phoneNumbers.append(CNLabeledValue(label: phone.label, value: phone.value))
            }
            for email in other.emailAddresses {
                guard let key = ContactNormalizer.emailKey(email.value as String) else { continue }
                guard !emailKeys.contains(key) else { continue }
                emailKeys.insert(key)
                keeper.emailAddresses.append(CNLabeledValue(label: email.label, value: email.value))
            }
            if keeper.imageData == nil, let image = other.imageData {
                keeper.imageData = image
            }
            if keeper.organizationName.isEmpty, !other.organizationName.isEmpty {
                keeper.organizationName = other.organizationName
            }
            if let mutable = other.mutableCopy() as? CNMutableContact {
                save.delete(mutable)
                removed += 1
            }
        }

        guard removed > 0 else { return 0 }
        save.update(keeper)
        do {
            try store.execute(save)
            return removed
        } catch {
            throw ContactServiceError.mergeFailed
        }
    }

    private static func richness(_ contact: CNContact) -> Int {
        var score = contact.phoneNumbers.count + contact.emailAddresses.count
        if !contact.givenName.isEmpty || !contact.familyName.isEmpty { score += 1 }
        if contact.imageData != nil { score += 1 }
        if !contact.organizationName.isEmpty { score += 1 }
        return score
    }
}
