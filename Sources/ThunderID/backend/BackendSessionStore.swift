// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Keeps the backend session handle in the platform's secure store, through the same
/// ``StorageAdapter`` the token store uses, so a caller-supplied adapter applies here too.
///
/// The handle is all the app holds in backend mode: it stands for a session whose tokens never
/// leave the backend, so it is written and read like a token and never logged.
final class BackendSessionStore {
    private let storage: StorageAdapter
    private let key: String

    init(storage: StorageAdapter, vendor: String, instanceId: Int?) {
        self.storage = storage
        let instance = instanceId.map { "instance_\($0)-" } ?? ""
        key = "\(vendor).\(instance)backend_session_handle"
    }

    func save(handle: String) throws {
        try storage.store(key: key, value: handle)
    }

    func handle() -> String? {
        storage.retrieve(key: key)
    }

    func clear() {
        storage.delete(key: key)
    }
}
