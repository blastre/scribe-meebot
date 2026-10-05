import { cookies } from "next/headers";
import { getAuthCookieName, getUserInfoCookieName } from "@/lib/auth-cookies";

/**
 * Resolve the authenticated user's ID from the configured auth cookie.
 *
 * Uses the auth cookie (an API key) to look up the owning user via the
 * Admin API's user-facing auth endpoint, which resolves token -> user.
 * Resolves through the configured admin /users/email/ endpoint when user-info is available.
 *
 * Returns the numeric user ID as a string, or null if unauthenticated.
 */
export async function getAuthenticatedUserId(): Promise<string | null> {
  const SCRIBE_ADMIN_API_URL = process.env.SCRIBE_ADMIN_API_URL;
  const SCRIBE_ADMIN_API_KEY = process.env.SCRIBE_ADMIN_API_KEY || "";

  if (!SCRIBE_ADMIN_API_URL || !SCRIBE_ADMIN_API_KEY) return null;

  const cookieStore = await cookies();
  const token = cookieStore.get(getAuthCookieName())?.value;
  if (!token) return null;

  // Validate the token by calling the API gateway (same as /api/auth/me)
  const SCRIBE_API_URL = process.env.SCRIBE_API_URL;
  if (!SCRIBE_API_URL) return null;
  const verifyRes = await fetch(`${SCRIBE_API_URL}/meetings`, {
    headers: { "X-API-Key": token },
  });
  if (!verifyRes.ok) return null;

  // Get the user's email from the SSO cookie, then resolve to a user ID
  const userInfoStr = cookieStore.get(getUserInfoCookieName())?.value;
  if (!userInfoStr) return null;

  let email: string;
  try {
    const userInfo = JSON.parse(userInfoStr);
    email = userInfo.email;
    if (!email) return null;
  } catch {
    return null;
  }

  // Look up user by email using the admin API key (server-side only)
  try {
    const res = await fetch(
      `${SCRIBE_ADMIN_API_URL}/admin/users/email/${encodeURIComponent(email)}`,
      {
        headers: { "X-Admin-API-Key": SCRIBE_ADMIN_API_KEY },
        cache: "no-store",
      }
    );
    if (!res.ok) return null;
    const user = await res.json();
    return user.id != null ? String(user.id) : null;
  } catch {
    return null;
  }
}
