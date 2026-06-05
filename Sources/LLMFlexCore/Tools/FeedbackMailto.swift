import Foundation

/// Builds the `mailto:` URL behind the in-app "Send feedback" form. The
/// query-string percent-encoding is the easy thing to get wrong, so it lives
/// here in Core (pure logic) and is unit-tested rather than buried in a view.
public enum FeedbackMailto {
    /// Where feedback goes. Plumbed through `build(to:)` so tests don't depend
    /// on the live address.
    public static let recipient = "llmflex@holdtight.cc"

    /// Allowed characters for a mailto query VALUE. We start from
    /// `.urlQueryAllowed` and strip the sub-delimiters that carry meaning in a
    /// query string: `&` separates fields and `=` separates key/value, so an
    /// unescaped one in the body would truncate or corrupt the message; `?`
    /// and `+` are likewise risky (`+` is decoded back to a space by many mail
    /// clients). Newlines aren't in `.urlQueryAllowed` to begin with, so they
    /// percent-encode to `%0A` automatically.
    private static let queryValueAllowed: CharacterSet = {
        var set = CharacterSet.urlQueryAllowed
        set.remove(charactersIn: "&=?+")
        return set
    }()

    /// Percent-encode a single subject/body value for use in the mailto query.
    public static func encode(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: queryValueAllowed) ?? ""
    }

    /// Build a `mailto:` URL with the subject and body pre-filled. Returns nil
    /// only if the address itself can't form a valid URL.
    public static func build(
        subject: String,
        body: String,
        to recipient: String = FeedbackMailto.recipient
    ) -> URL? {
        let encodedSubject = encode(subject)
        let encodedBody = encode(body)
        return URL(string: "mailto:\(recipient)?subject=\(encodedSubject)&body=\(encodedBody)")
    }
}
