# Security Policy

Mecha Connect takes the security of the application and its users seriously.
This document describes how to report vulnerabilities and the project's
security commitments.

## Supported Versions

Security updates are applied to the latest release and the current Sprint 2
development branch. Older RC snapshots are not patched.

## Reporting a Vulnerability

**Do not** open a public issue for security problems.

Please report vulnerabilities privately to the project maintainers through a
private channel (maintainer email or a private/draft message). Include:

- Description of the issue and affected component.
- Steps to reproduce, if possible.
- Impact assessment (what an attacker can do).
- Suggested fix, if you have one.

You will receive an acknowledgement within a few days and a status update
after triage.

## Security Commitments

- **No secrets in the repository.** Environment configuration, API keys,
  service accounts, certificates, and credential files are never committed.
  They must be loaded from environment variables or a secret store at runtime.
  See `docs/common/INSTALLATION.md` for the environment-variable contract
  (names only — values stay out of the repo).
- **Least privilege.** Production access is restricted; only maintainers
  deploy to production.
- **Dependency hygiene.** Third-party dependencies are reviewed before
  introduction, and security-relevant updates are tracked.
- **Safe disclosure.** Security details, internal findings, and operational
  procedures are tracked internally and are not published in public
  documentation.

## Scope

This policy applies to the Mecha Connect application code, documentation, and
infrastructure. Reporting a bug is a contribution to the project's safety —
thank you.
