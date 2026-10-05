import { NextRequest, NextResponse } from "next/server";
import { getServerSession } from "next-auth/next";
import { authOptions } from "../[...nextauth]/route";

/**
 * OAuth callback endpoint - syncs user info after Google OAuth
 * Called by the frontend after successful OAuth to get user info
 */
export async function GET(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions);

    if (!session || !(session as any).scribeUser) {
      return NextResponse.json(
        { error: "Not authenticated via OAuth" },
        { status: 401 }
      );
    }

    const scribeUser = (session as any).scribeUser;
    const token = (session as any).scribeToken;

    // Return user info in the same format as the login endpoint
    return NextResponse.json({
      user: {
        id: scribeUser.id,
        email: scribeUser.email,
        name: scribeUser.name,
        max_concurrent_bots: scribeUser.max_concurrent_bots,
        created_at: scribeUser.created_at,
      },
      token,
      isNewUser: (session as any).isNewUser || false,
    });
  } catch (error) {
    console.error("OAuth callback error:", error);
    return NextResponse.json(
      { error: "Failed to sync OAuth session" },
      { status: 500 }
    );
  }
}

