// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

import Foundation
import Security

final class LocalhostPinnedURLSession: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    private let host: String
    private let pinnedCertificateData: Data?

    private init(host: String, pinnedCertificateData: Data?) {
        self.host = host
        self.pinnedCertificateData = pinnedCertificateData
    }

    static func make(for baseUrl: String) -> URLSession {
        guard let url = URL(string: baseUrl), let host = url.host else {
            return .shared
        }

        let certData = Bundle.main.url(forResource: "server", withExtension: "cert")
            .flatMap { loadCertificateData(from: $0) }
        let delegate = LocalhostPinnedURLSession(host: host, pinnedCertificateData: certData)
        return URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard
            challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            challenge.protectionSpace.host == host,
            let serverTrust = challenge.protectionSpace.serverTrust
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Anything other than loopback goes through the system's own evaluation. Accepting a
        // trust object without evaluating it *replaces* that evaluation rather than adding to
        // it, so doing so for an arbitrary host would silently accept a forged certificate on
        // the channel carrying credentials, assertions and refresh tokens.
        guard Self.isLoopbackHost(host) else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // A pinned certificate is the strongest answer when one is bundled: match it exactly.
        if let pinned = pinnedCertificateData {
            guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0),
                  (SecCertificateCopyData(certificate) as Data) == pinned else {
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
            return
        }

        // No pin, but the host is loopback, which no network attacker can occupy. This is what
        // lets a development build reach a local server through its self-signed certificate.
        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    }

    /// Whether `host` is a loopback address, and therefore unreachable by a network attacker.
    static func isLoopbackHost(_ host: String) -> Bool {
        ["localhost", "127.0.0.1", "::1", "[::1]"].contains(host)
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        urlSession(session, didReceive: challenge, completionHandler: completionHandler)
    }

    private static func loadCertificateData(from url: URL) -> Data? {
        guard let fileData = try? Data(contentsOf: url) else {
            return nil
        }

        if let certificate = SecCertificateCreateWithData(nil, fileData as CFData) {
            return SecCertificateCopyData(certificate) as Data
        }

        guard let pemString = String(data: fileData, encoding: .utf8) else {
            return nil
        }

        let base64Lines = pemString
            .components(separatedBy: .newlines)
            .filter { !$0.hasPrefix("-----BEGIN") && !$0.hasPrefix("-----END") && !$0.isEmpty }
            .joined()

        guard
            let derData = Data(base64Encoded: base64Lines),
            let certificate = SecCertificateCreateWithData(nil, derData as CFData)
        else {
            return nil
        }

        return SecCertificateCopyData(certificate) as Data
    }
}
