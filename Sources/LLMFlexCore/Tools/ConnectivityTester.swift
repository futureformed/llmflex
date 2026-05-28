import Foundation

public struct ConnectivityResult: Sendable {
    public let ok: Bool
    public let statusCode: Int?
    public let message: String
}

/// How a provider expects its API key to be presented on the wire.
/// Different vendors picked different conventions:
///   - OpenAI / OpenRouter / OAI-compatible: `Authorization: Bearer <key>`
///   - Anthropic:                            `x-api-key` + `anthropic-version`
///   - Google Gemini:                        `?key=<key>` query parameter
public enum AuthScheme: Sendable {
    case bearer
    case anthropicHeaders
    case googleQueryParam
}

/// Sanity-checks a provider's base URL + API key by hitting `<baseURL>/models`.
/// Wrap this in a protocol at the UI layer to mock in tests — we don't unit-
/// test the live HTTP here.
public actor ConnectivityTester {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func test(
        baseURL: String,
        apiKey: String?,
        scheme: AuthScheme = .bearer
    ) async -> ConnectivityResult {
        guard var components = URLComponents(string: baseURL) else {
            return .init(ok: false, statusCode: nil, message: "Invalid base URL")
        }
        var path = components.path
        if !path.hasSuffix("/") { path += "/" }
        path += "models"
        components.path = path

        if scheme == .googleQueryParam, let key = apiKey, !key.isEmpty {
            var items = components.queryItems ?? []
            items.append(URLQueryItem(name: "key", value: key))
            components.queryItems = items
        }
        guard let url = components.url else {
            return .init(ok: false, statusCode: nil, message: "Invalid base URL")
        }

        var req = URLRequest(url: url, timeoutInterval: 8)
        if let key = apiKey, !key.isEmpty {
            switch scheme {
            case .bearer:
                req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            case .anthropicHeaders:
                req.setValue(key, forHTTPHeaderField: "x-api-key")
                req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            case .googleQueryParam:
                break // already encoded as a query param
            }
        }

        do {
            let (data, response) = try await session.data(for: req)
            let http = response as? HTTPURLResponse
            let code = http?.statusCode
            let ok = (200...299).contains(code ?? -1)
            if ok {
                return .init(ok: true, statusCode: code, message: "Connected")
            }
            // On error, surface the body so the user can see WHY it failed —
            // e.g. "invalid x-api-key" vs "model not found" vs "no credits".
            let bodyHint = extractMessage(from: data)
            let codeStr = code.map(String.init) ?? "?"
            let message = bodyHint.isEmpty ? "HTTP \(codeStr)" : "HTTP \(codeStr) — \(bodyHint)"
            return .init(ok: false, statusCode: code, message: message)
        } catch {
            return .init(ok: false, statusCode: nil, message: error.localizedDescription)
        }
    }

    /// Best-effort extraction of a human message from a provider's error body.
    /// Tries OpenAI, Anthropic, and Google shapes; falls back to raw text.
    private func extractMessage(from data: Data) -> String {
        guard !data.isEmpty,
              let any = try? JSONSerialization.jsonObject(with: data)
        else {
            return String(data: data.prefix(200), encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
        if let dict = any as? [String: Any] {
            // Anthropic: { "error": { "message": "..." } }
            // OpenAI:    { "error": { "message": "..." } }
            if let err = dict["error"] as? [String: Any],
               let msg = err["message"] as? String {
                return msg
            }
            // Google:    { "error": { "message": "..." } } — same shape
            if let msg = dict["message"] as? String {
                return msg
            }
        }
        return ""
    }
}
