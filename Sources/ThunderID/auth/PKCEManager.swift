/*
 * Copyright (c) 2026, WSO2 LLC. (https://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

import CryptoKit
import Foundation

/// Generates and manages PKCE parameters per RFC 7636 (spec §11.2).
/// S256 only. code_verifier held in memory, cleared after exchange.
final class PKCEManager {
    private(set) var codeVerifier: String?

    func generate() -> (verifier: String, challenge: String) {
        let verifier = generateVerifier()
        let challenge = deriveChallenge(from: verifier)
        codeVerifier = verifier
        return (verifier, challenge)
    }

    func clearVerifier() {
        codeVerifier = nil
    }

    private func generateVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 64)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64URLEncoded()
    }

    private func deriveChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let digest = SHA256.hash(data: data)
        return Data(digest).base64URLEncoded()
    }
}

private extension Data {
    func base64URLEncoded() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
