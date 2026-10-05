import { NextRequest, NextResponse } from "next/server";
import { cookies } from "next/headers";
import { getAuthCookieName } from "@/lib/auth-cookies";

/**
 * GET /api/webhooks/deliveries/:meetingId
 *
 * Proxy to admin-api for meeting-specific webhook delivery attempts.
 */
export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ meetingId: string }> }
) {
  const SCRIBE_API_URL = process.env.SCRIBE_API_URL;
  if (!SCRIBE_API_URL) {
    return NextResponse.json({ error: "SCRIBE_API_URL is required" }, { status: 500 });
  }
  const cookieStore = await cookies();
  const userToken = cookieStore.get(getAuthCookieName())?.value;
  // Multi-user mode: no shared-key fallback — webhook delivery history is
  // per-user data, so it must be fetched with the caller's own token.
  const requireAuth = ["1", "true", "yes"].includes(
    (process.env.SCRIBE_REQUIRE_AUTH || "").toLowerCase()
  );
  if (requireAuth && !userToken) {
    return NextResponse.json({ error: "Not authenticated" }, { status: 401 });
  }
  const apiKey = userToken || (requireAuth ? "" : process.env.SCRIBE_API_KEY || "");
  const { meetingId } = await params;

  try {
    const response = await fetch(
      `${SCRIBE_API_URL}/admin/webhooks/deliveries/${meetingId}`,
      {
        headers: {
          "Content-Type": "application/json",
          ...(apiKey ? { "X-API-Key": apiKey } : {}),
        },
      }
    );

    if (response.status === 404) {
      return NextResponse.json({ attempts: [] });
    }

    if (!response.ok) {
      return NextResponse.json(
        { error: "Failed to fetch meeting webhook deliveries" },
        { status: response.status }
      );
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch {
    return NextResponse.json({ attempts: [] });
  }
}
