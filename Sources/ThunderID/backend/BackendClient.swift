// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Header every backend call carries the session handle in. The backend holds the tokens; the app
/// holds only this handle, and keeps it in the platform's secure store.
let backendSessionHeader = "X-Session-Handle"

/// Talks to the backend that signs the application in: exchanges the one-time code the browser
/// session returns, reads the session, refreshes it, and ends it. The app never holds a token.
final class BackendClient {
    private let endpoints: ThunderIDBackendEndpoints
    private let store: BackendSessionStore
    private let session: URLSession
    private var cached: BackendSession?
    private var wasSignedIn = false
    private var onSignedOut: (() -> Void)?

    init(endpoints: ThunderIDBackendEndpoints, store: BackendSessionStore, session: URLSession? = nil) {
        self.endpoints = endpoints
        self.store = store
        self.session = session ?? LocalhostPinnedURLSession.make(for: endpoints.baseUrl)
    }

    /// Called when a session that was signed in turns out to have ended without this client
    /// signing out: another app signed the user out, an administrator ended it, or it timed out.
    func setSignedOutHandler(_ handler: @escaping () -> Void) {
        onSignedOut = handler
    }

    /// The URL that starts sign-in in a browser session, bound to this client by `challenge`.
    func signInURL(redirectUri: String, challenge: String) throws -> URL {
        guard var components = URLComponents(string: endpoints.baseUrl + endpoints.signIn) else {
            throw ThunderIDError(code: .invalidConfiguration, message: "Invalid backend sign-in URL")
        }
        var items = components.queryItems ?? []
        items.append(.init(name: "redirect_uri", value: redirectUri))
        items.append(.init(name: "code_challenge", value: challenge))
        items.append(.init(name: "code_challenge_method", value: "S256"))
        components.queryItems = items
        guard let url = components.url else {
            throw ThunderIDError(code: .invalidConfiguration, message: "Could not build the backend sign-in URL")
        }
        return url
    }

    /// Exchanges the one-time code the browser session returned for a session handle, which the
    /// secure store keeps.
    @discardableResult
    func exchange(code: String, verifier: String) async throws -> BackendSession {
        let body = try JSONSerialization.data(withJSONObject: ["code": code, "code_verifier": verifier])
        let (data, http) = try await send(path: endpoints.session, method: "POST", body: body)
        guard http.statusCode == 200 else {
            throw ThunderIDError(
                code: .authenticationFailed,
                message: "The backend refused the sign-in code (\(http.statusCode))"
            )
        }
        let session = try decode(data)
        guard session.isSignedIn, let handle = session.handle, !handle.isEmpty else {
            throw ThunderIDError(code: .authenticationFailed, message: "The backend returned no session")
        }
        try store.save(handle: handle)
        wasSignedIn = true
        cached = session
        return session
    }

    /// Reads the session, from the cache unless `reload` is set. A read with no handle is signed out.
    @discardableResult
    func getSession(reload: Bool = false) async throws -> BackendSession {
        if !reload, let cached { return cached }
        guard store.handle() != nil else {
            cached = .signedOut
            return .signedOut
        }
        var (data, http) = try await send(path: endpoints.session, method: "GET", body: nil)
        if http.statusCode == 401, isSessionExpired(data), try await refresh() {
            (data, http) = try await send(path: endpoints.session, method: "GET", body: nil)
        }
        if http.statusCode == 401 {
            markSignedOut()
            return .signedOut
        }
        guard http.statusCode == 200 else {
            throw ThunderIDError(
                code: .serverError,
                message: "The backend session endpoint returned \(http.statusCode)"
            )
        }
        let session = try decode(data)
        if !session.isSignedIn {
            markSignedOut()
            return .signedOut
        }
        wasSignedIn = true
        cached = session
        return session
    }

    /// Asks the backend whether the session is still live. The check neither refreshes it nor
    /// counts as activity, so it can be polled. A failed check reports the last known state.
    @discardableResult
    func checkSession() async -> Bool {
        guard store.handle() != nil else { return false }
        do {
            let (data, http) = try await send(path: endpoints.checkSession, method: "GET", body: nil)
            guard http.statusCode == 200 else { return wasSignedIn }
            let check: BackendCheck = try decode(data)
            if !check.isSignedIn { markSignedOut() }
            return check.isSignedIn
        } catch {
            return wasSignedIn
        }
    }

    /// Refreshes the session once.
    /// - Returns: whether it was refreshed. When it was not, the session is now signed out.
    @discardableResult
    func refresh() async throws -> Bool {
        guard store.handle() != nil else { return false }
        let (_, http) = try await send(path: endpoints.refresh, method: "POST", body: nil)
        if http.statusCode == 200 || http.statusCode == 204 {
            cached = nil
            return true
        }
        markSignedOut()
        return false
    }

    /// Ends the backend session.
    /// - Returns: the URL that ends it at the authorization server, when the backend returns one.
    @discardableResult
    func signOut() async throws -> String? {
        defer { clear() }
        guard store.handle() != nil else { return nil }
        let (data, http) = try await send(path: endpoints.signOut, method: "POST", body: nil)
        guard http.statusCode == 200 else { return nil }
        let result: BackendSignOut = try decode(data)
        return result.redirectUrl
    }

    /// Forgets the session without telling the listener: the caller already knows.
    func clear() {
        cached = .signedOut
        wasSignedIn = false
        store.clear()
    }

    /// The headers every call through the proxy carries.
    func proxyHeaders() -> [String: String] {
        guard let handle = store.handle() else { return [:] }
        return [backendSessionHeader: handle]
    }

    /// Reads a backend `401` and reacts to it.
    /// - Returns: whether the caller should send its request again.
    func handleUnauthorized(body: Data) async -> Bool {
        if isLoginRequired(body) {
            markSignedOut()
            return false
        }
        guard isSessionExpired(body) else { return false }
        return (try? await refresh()) ?? false
    }

    // MARK: - Private

    private func markSignedOut() {
        cached = .signedOut
        store.clear()
        if wasSignedIn {
            wasSignedIn = false
            onSignedOut?()
        }
    }

    private func send(path: String, method: String, body: Data?) async throws -> (Data, HTTPURLResponse) {
        guard let url = endpoints.url(path) else {
            throw ThunderIDError(code: .invalidConfiguration, message: "Invalid backend URL for \(path)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.assumesHTTP3Capable = false
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        request.httpBody = body
        for (name, value) in proxyHeaders() {
            request.setValue(value, forHTTPHeaderField: name)
        }
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw ThunderIDError(code: .networkError, message: "Invalid response from the backend")
            }
            return (data, http)
        } catch let error as ThunderIDError {
            throw error
        } catch {
            throw ThunderIDError(
                code: .networkError,
                message: "The backend could not be reached",
                underlyingError: error
            )
        }
    }

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw ThunderIDError(
                code: .unknownError,
                message: "Could not read the backend's response",
                underlyingError: error
            )
        }
    }

    private func errorCode(_ data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return json["error"] as? String
    }

    private func isSessionExpired(_ data: Data) -> Bool { errorCode(data) == "session_expired" }

    private func isLoginRequired(_ data: Data) -> Bool { errorCode(data) == "login_required" }
}
