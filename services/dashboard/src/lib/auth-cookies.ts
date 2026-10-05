export function getAuthCookieName(): string {
  return process.env.SCRIBE_AUTH_COOKIE_NAME || "scribe-token";
}

export function getUserInfoCookieName(): string {
  return process.env.SCRIBE_USER_INFO_COOKIE_NAME || "scribe-user-info";
}
