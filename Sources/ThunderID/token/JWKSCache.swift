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

/// Fetches and caches the server JWKS. Supports key rotation (spec §11.4).
final class JWKSCache {
    private let httpClient: HTTPClient
    private var cachedKeys: [JWK] = []
    private var cacheExpiry: Date = .distantPast
    private let minCacheTTL: TimeInterval = 300 // 5 minutes

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func getKeys(forceRefresh: Bool = false) async throws -> [JWK] {
        if !forceRefresh && Date() < cacheExpiry && !cachedKeys.isEmpty {
            return cachedKeys
        }
        let response: JWKSResponse = try await httpClient.get(path: "/oauth2/jwks", requiresAuth: false)
        cachedKeys = response.keys
        cacheExpiry = Date().addingTimeInterval(minCacheTTL)
        return cachedKeys
    }
}

struct JWKSResponse: Codable {
    let keys: [JWK]
}

struct JWK: Codable {
    let kty: String
    let kid: String?
    let use: String?
    let alg: String?
    let modulus: String?
    let exponent: String?

    enum CodingKeys: String, CodingKey {
        case kty, kid, use, alg
        case modulus = "n"
        case exponent = "e"
    }
}
