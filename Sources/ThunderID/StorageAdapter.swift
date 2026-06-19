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

import Foundation
import Security

/// Interface for custom token/session storage backends (spec §11.1).
public protocol StorageAdapter {
    func store(key: String, value: String) throws
    func retrieve(key: String) -> String?
    func delete(key: String)
    func clear()
}

/// Default storage using iOS Keychain Services (spec §11.1).
public final class KeychainStorageAdapter: StorageAdapter {
    private let service: String

    public init(service: String = "dev.thunderid.sdk") {
        self.service = service
    }

    public func store(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            throw ThunderIDError(code: .unknownError, message: "Keychain write failed: \(status)")
        }
    }

    public func retrieve(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    public func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)
    }
}

/// In-memory storage adapter for testing.
public final class InMemoryStorageAdapter: StorageAdapter {
    private var store: [String: String] = [:]

    public init() {}

    public func store(key: String, value: String) { store[key] = value }
    public func retrieve(key: String) -> String? { store[key] }
    public func delete(key: String) { store.removeValue(forKey: key) }
    public func clear() { store.removeAll() }
}
