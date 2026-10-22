// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// The app backend's auth endpoints, set as `ThunderIDEndpoints.backend`.
///
/// Setting them hands sign-in to a backend the application owns: the backend runs the OAuth flow
/// and keeps the tokens, so the app holds no token at all, only an opaque session handle in the
/// platform's secure store. API calls go through the backend's proxy, which attaches the access
/// token. This is the Backend for Frontend pattern of RFC 10017.
///
/// Each path is resolved against ``baseUrl``, and any path left unset defaults under `/api/auth`.
public struct ThunderIDBackendEndpoints {
    /// Base URL of the backend. Must use HTTPS. Every request the SDK makes in this mode goes to it.
    public let baseUrl: String
    /// Starts sign-in, opened in a browser session. Defaults to `/api/auth/signin`.
    public var signIn: String
    /// Exchanges the one-time code for a session handle, and reports the signed-in user.
    /// Defaults to `/api/auth/session`.
    public var session: String
    /// Reports only whether the session is still live, without refreshing it or counting as
    /// activity, so the SDK can poll it. Defaults to `/api/auth/checksession`.
    public var checkSession: String
    /// Refreshes the session. Defaults to `/api/auth/refresh`.
    public var refresh: String
    /// Ends the session. Defaults to `/api/auth/signout`.
    public var signOut: String
    /// Prefix the application's API calls are sent through. Defaults to `/api/auth/proxy`.
    public var proxy: String

    public init(
        baseUrl: String,
        signIn: String = "/api/auth/signin",
        session: String = "/api/auth/session",
        checkSession: String = "/api/auth/checksession",
        refresh: String = "/api/auth/refresh",
        signOut: String = "/api/auth/signout",
        proxy: String = "/api/auth/proxy"
    ) {
        self.baseUrl = baseUrl.hasSuffix("/") ? String(baseUrl.dropLast()) : baseUrl
        self.signIn = signIn
        self.session = session
        self.checkSession = checkSession
        self.refresh = refresh
        self.signOut = signOut
        self.proxy = proxy.hasSuffix("/") ? String(proxy.dropLast()) : proxy
    }

    /// The absolute URL of one endpoint.
    func url(_ path: String) -> URL? {
        URL(string: baseUrl + path)
    }

    /// The proxy prefix as an absolute URL string, which the API calls are resolved against.
    var proxyBaseUrl: String {
        baseUrl + proxy
    }
}

/// What the backend's session endpoint reports.
struct BackendSession: Decodable {
    let isSignedIn: Bool
    /// The session handle, returned when a one-time code is exchanged.
    let handle: String?
    /// The ID token's user claims, without the protocol claims.
    let user: [String: AnyCodable]?
    /// When the access token expires, in seconds since the epoch.
    let expiresAt: Double?

    static let signedOut = BackendSession(isSignedIn: false, handle: nil, user: nil, expiresAt: nil)
}

/// What the backend's sign-out endpoint reports.
struct BackendSignOut: Decodable {
    let redirectUrl: String?
}

/// Whether the session is still live, as the check endpoint reports it.
struct BackendCheck: Decodable {
    let isSignedIn: Bool
}
