import Foundation

/// Pure parsing helpers for Ollama CLI output and human-readable byte strings.
public enum AIModelParsing {

    /// Parses a size token from `ollama list` (e.g. `4.7 GB`, `500 MiB`).
    public static func parseByteCount(_ rawValue: String) -> Int64 {
        let cleaned = rawValue.replacingOccurrences(of: " ", with: "").uppercased()

        let binaryUnits: [(suffix: String, multiplier: Int64)] = [
            ("PIB", 1_024 * 1_024 * 1_024 * 1_024 * 1_024),
            ("TIB", 1_024 * 1_024 * 1_024 * 1_024),
            ("GIB", 1_024 * 1_024 * 1_024),
            ("MIB", 1_024 * 1_024),
            ("KIB", 1_024)
        ]
        for unit in binaryUnits {
            if cleaned.hasSuffix(unit.suffix) {
                let value = cleaned.replacingOccurrences(of: unit.suffix, with: "")
                return Int64((Double(value) ?? 0) * Double(unit.multiplier))
            }
        }

        let decimalUnits: [(suffix: String, multiplier: Double)] = [
            ("TB", 1_000_000_000_000),
            ("GB", 1_000_000_000),
            ("MB", 1_000_000),
            ("KB", 1_000),
            ("B", 1)
        ]
        for unit in decimalUnits.sorted(by: { $0.suffix.count > $1.suffix.count }) {
            if cleaned.hasSuffix(unit.suffix) {
                let value = cleaned.replacingOccurrences(of: unit.suffix, with: "")
                return Int64((Double(value) ?? 0) * unit.multiplier)
            }
        }

        return 0
    }

    /// Parses `ollama list` stdout. Skips the first line (header). Empty or malformed lines are ignored.
    public static func parseOllamaList(_ output: String, root: URL?) -> [AIModelItem] {
        let sizePattern = #"[0-9]+(?:\.[0-9]+)?\s*(?:[KMGTPE](?:i)?)?B"#

        return output
            .split(whereSeparator: \.isNewline)
            .dropFirst()
            .compactMap { rawLine -> AIModelItem? in
                let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !line.isEmpty else { return nil }

                guard let sizeRange = line.range(of: sizePattern, options: .regularExpression) else {
                    return nil
                }

                let prefix = String(line[..<sizeRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let sizeString = String(line[sizeRange])
                let modifiedText = String(line[sizeRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                let name = prefix.components(separatedBy: .whitespaces).first ?? prefix
                guard !name.isEmpty else { return nil }

                return AIModelItem(
                    provider: .ollama,
                    name: name,
                    size: parseByteCount(sizeString),
                    modifiedDate: nil,
                    url: root,
                    locationDescription: root?.path ?? "~/.ollama/models",
                    details: modifiedText.isEmpty ? "Quản lý bằng Ollama CLI" : "Cập nhật: \(modifiedText)",
                    deleteStrategy: .ollama(name: name)
                )
            }
    }
}
