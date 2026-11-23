import Foundation
import Security
import SwiftUI

enum BridgeTokenVault {
    private static let service = "com.valentinebsaa.crispcompanion.bridge"

    static func load() -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "bridge-token",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else { return "" }
        return value
    }

    static func save(_ value: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "bridge-token"
        ]
        SecItemDelete(query as CFDictionary)
        guard !value.isEmpty, let data = value.data(using: .utf8) else { return }
        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(attributes as CFDictionary, nil)
    }
}

@MainActor
final class KitchenStore: ObservableObject {
    @Published var previewMode: Bool = UserDefaults.standard.object(forKey: "previewMode") as? Bool ?? true {
        didSet {
            UserDefaults.standard.set(previewMode, forKey: "previewMode")
            if previewMode { status = nil }
        }
    }
    @Published var bridgeURL: String = UserDefaults.standard.string(forKey: "bridgeURL") ?? "" {
        didSet { UserDefaults.standard.set(bridgeURL, forKey: "bridgeURL") }
    }
    @Published private(set) var recipes: [SavedRecipe] = []
    @Published private(set) var status: LiveFryerStatus?
    @Published private(set) var lastError: String?
    @Published private(set) var isRefreshing = false

    init() {
        if let data = UserDefaults.standard.data(forKey: "recipes"),
           let saved = try? JSONDecoder().decode([SavedRecipe].self, from: data) {
            recipes = saved.filter(\.isValid)
        }
    }

    func addRecipe(_ recipe: SavedRecipe) {
        guard recipe.isValid else { return }
        recipes.insert(recipe, at: 0)
        persistRecipes()
    }

    func removeRecipe(_ id: UUID) {
        recipes.removeAll { $0.id == id }
        persistRecipes()
    }

    private func persistRecipes() {
        guard let data = try? JSONEncoder().encode(recipes) else { return }
        UserDefaults.standard.set(data, forKey: "recipes")
    }

    func refresh() async {
        guard !previewMode else {
            status = nil
            lastError = "Preview mode does not contact an air fryer."
            return
        }
        guard let url = URL(string: bridgeURL.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme?.lowercased() == "https",
              url.host != nil else {
            status = nil
            lastError = "Use an HTTPS URL to your private NAS bridge."
            return
        }
        let token = BridgeTokenVault.load()
        guard !token.isEmpty else {
            status = nil
            lastError = "Save an access token in Settings first."
            return
        }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            var request = URLRequest(url: url.appendingPathComponent("v1/status"))
            request.httpMethod = "GET"
            request.timeoutInterval = 12
            request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
            request.cachePolicy = .reloadIgnoringLocalCacheData
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let result = try decoder.decode(LiveFryerStatus.self, from: data)
            status = result
            lastError = result.connected ? nil : (result.message ?? "No paired device found.")
        } catch {
            status = nil
            lastError = "Could not securely reach the NAS bridge. Check the URL, account setup, and server logs."
        }
    }
}
