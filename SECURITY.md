# Security Policy

## Supported versions

This project is pre-1.0. Security fixes land on `main` and are released in the
next tagged version; older tags are not backported.

| Version | Supported |
| ------- | --------- |
| `main`  | ✅        |
| < 0.1   | ❌        |

## Reporting a vulnerability

Please **do not** open a public issue for a security problem.

Report it privately through
[GitHub Security Advisories](https://github.com/blastre/scribe-meetbot/security/advisories/new).

Include a description of the issue, the steps to reproduce it, and the affected
version or commit. You can expect an initial response within a few days. If the
report is accepted, a fix and an advisory will follow; if it is declined, you
will get an explanation of why.

## Scope

This project self-hosts and handles meeting audio, transcripts, and API tokens.
Reports that are especially relevant include authentication and token-scoping
flaws, cross-tenant data access (`owner_email` isolation), recording storage
exposure, and secrets leaking into logs.

## Running it safely

- Keep `INTERNAL_API_SECRET` and all API keys out of version control — use `.env`.
- Do not expose the admin API or internal service ports to the public internet;
  only the API gateway should be reachable.
- Rotate API tokens if a deployment is ever shared or decommissioned.
