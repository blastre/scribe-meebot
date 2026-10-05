/**
 * Get the webapp URL (example.com marketing + billing/account).
 * Used for "Account & Billing" links etc.
 */
export function getWebappUrl(): string {
  return process.env.NEXT_PUBLIC_WEBAPP_URL || "https://example.com";
}

/**
 * Get the full URL for a docs path on the docs site (Mintlify at
 * example.com). Previously this was wrongly rooted at webapp host;
 * fixed 2026-05-01 — `API Docs` in the sidebar pointed at
 * api.example.com which is not a docs site.
 */
export function getDocsUrl(path: string): string {
  const docsUrl = process.env.NEXT_PUBLIC_DOCS_URL || "https://example.com";
  // Remove leading slash if present to avoid double slashes
  const cleanPath = path.startsWith("/") ? path : `/${path}`;
  return `${docsUrl}${cleanPath}`;
}
