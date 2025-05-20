import Foundation

public extension String {
    /// Returns a prefix of the string with the specified length.
    /// - Parameter length: The maximum length of the prefix.
    /// - Returns: A substring containing the first `length` characters of the string,
    ///            or the entire string if it's shorter than `length`.
    func limitedPrefix(_ length: Int) -> String {
        return String(self.prefix(length))
    }
}
