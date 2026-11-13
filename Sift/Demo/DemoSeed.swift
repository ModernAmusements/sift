#if DEBUG
import Contacts
import Foundation
import Photos

/// Debug-only fixtures for the simulator. Never compiled into Release builds.
enum DemoSeed {
    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-uiFixtures")
    }

    /// PhotoKit has no public API for marking an imported image as a screenshot.
    /// The simulator fixture treats the 1170×2532 test PNGs as screenshots so the
    /// review and deletion flows can be exercised without a physical device.
    static func isFixtureScreenshot(_ asset: PHAsset) -> Bool {
        isUITesting
            && asset.mediaType == .image
            && asset.pixelWidth == 1170
            && asset.pixelHeight == 2532
    }

    static func runIfRequested() {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-reseedContacts") {
            removeDemoContacts()
        }
        if arguments.contains("-seedContacts") || arguments.contains("-reseedContacts") {
            seedContacts()
        }
    }

    private static func removeDemoContacts() {
        let store = CNContactStore()
        guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else { return }
        let keys = [CNContactIdentifierKey as CNKeyDescriptor]
        let predicates = ["Lovelace", "Hopper", "Johnson"].map {
            CNContact.predicateForContacts(matchingName: $0)
        }
        let demo = predicates.flatMap {
            (try? store.unifiedContacts(matching: $0, keysToFetch: keys)) ?? []
        }
        guard !demo.isEmpty else { return }
        let save = CNSaveRequest()
        for contact in demo {
            if let mutable = contact.mutableCopy() as? CNMutableContact {
                save.delete(mutable)
            }
        }
        try? store.execute(save)
    }

    private static func seedContacts() {
        let store = CNContactStore()
        guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else { return }

        let keys = [CNContactIdentifierKey as CNKeyDescriptor, CNContactGivenNameKey as CNKeyDescriptor]
        let existing = (try? store.unifiedContacts(
            matching: CNContact.predicateForContacts(matchingName: "Lovelace"),
            keysToFetch: keys
        )) ?? []
        guard existing.isEmpty else { return }

        let save = CNSaveRequest()

        let ada = CNMutableContact()
        ada.givenName = "Ada"
        ada.familyName = "Lovelace"
        ada.organizationName = "Analytical Engines"
        ada.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: "+49 151 2345 6789"))]
        ada.emailAddresses = [CNLabeledValue(label: CNLabelHome, value: "ada@example.com" as NSString)]
        save.add(ada, toContainerWithIdentifier: nil)

        let adaDuplicate = CNMutableContact()
        adaDuplicate.givenName = "Ada"
        adaDuplicate.familyName = "Lovelace"
        adaDuplicate.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: "0151 2345 6789"))]
        save.add(adaDuplicate, toContainerWithIdentifier: nil)

        let adaThird = CNMutableContact()
        adaThird.givenName = "A."
        adaThird.familyName = "Lovelace"
        adaThird.emailAddresses = [CNLabeledValue(label: CNLabelOther, value: "Ada@Example.com" as NSString)]
        save.add(adaThird, toContainerWithIdentifier: nil)

        let grace = CNMutableContact()
        grace.givenName = "Grace"
        grace.familyName = "Hopper"
        grace.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: "+1 202 555 0143"))]
        save.add(grace, toContainerWithIdentifier: nil)

        let graceDuplicate = CNMutableContact()
        graceDuplicate.givenName = "Grace"
        graceDuplicate.familyName = "Hopper"
        graceDuplicate.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: "202 555 0143"))]
        graceDuplicate.emailAddresses = [CNLabeledValue(label: CNLabelWork, value: "grace@navy.example" as NSString)]
        save.add(graceDuplicate, toContainerWithIdentifier: nil)

        let single = CNMutableContact()
        single.givenName = "Katherine"
        single.familyName = "Johnson"
        single.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: "+1 202 555 0199"))]
        save.add(single, toContainerWithIdentifier: nil)

        try? store.execute(save)
    }
}
#endif
