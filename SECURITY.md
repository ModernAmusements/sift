# Security policy

## Design

- Sift has no networking code and no server component.
- Photo and contact data stay inside the app sandbox and Apple's frameworks.
- Deletions go through PhotoKit's system confirmation; contacts merges require an in-app preview and confirmation.
- There are no third-party dependencies.

## Supported versions

| Version | Supported |
| --- | --- |
| 1.0.x | Yes |
| < 1.0 | No |

## Reporting a vulnerability

Use GitHub's **Report a vulnerability** (private security advisory) on the repository. Do not open a public issue for:

- data exposure or unintended data flow,
- a path that deletes without user confirmation,
- a contact merge that loses fields,
- a privacy-manifest or permission mismatch.

Include the app version, iOS version, reproduction steps and impact. You will get an acknowledgement within a few days. Please give us time to ship a fix before disclosure.

## Out of scope

- Claims that Sift does not clear system or third-party caches. It is documented behaviour, not a vulnerability.
- Issues requiring a jailbroken device or private APIs.
- Simulator-only Vision limitations.
