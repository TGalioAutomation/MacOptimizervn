import Foundation
import SwiftUI

public enum AIModelProvider: String, CaseIterable, Identifiable {
    case ollama = "Ollama"
    case lmStudio = "LM Studio"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .ollama: return "shippingbox.fill"
        case .lmStudio: return "cube.transparent.fill"
        }
    }

    public var tint: LinearGradient {
        switch self {
        case .ollama:
            return LinearGradient(
                colors: [
                    Color(red: 125 / 255, green: 249 / 255, blue: 170 / 255),
                    Color(red: 13 / 255, green: 170 / 255, blue: 121 / 255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .lmStudio:
            return LinearGradient(
                colors: [
                    Color(red: 99 / 255, green: 199 / 255, blue: 1),
                    Color(red: 109 / 255, green: 91 / 255, blue: 1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    public var subtitle: String {
        switch self {
        case .ollama:
            return "Model tải qua CLI và chạy local inference."
        case .lmStudio:
            return "Model GGUF hoặc bundle lưu trong thư mục của LM Studio."
        }
    }

    public var candidateRoots: [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        switch self {
        case .ollama:
            return [home.appendingPathComponent(".ollama/models")]
        case .lmStudio:
            return [
                home.appendingPathComponent(".lmstudio/models"),
                home.appendingPathComponent("Library/Application Support/LM Studio/models"),
                home.appendingPathComponent(".cache/lm-studio/models"),
                home.appendingPathComponent(".cache/lmstudio/models")
            ]
        }
    }
}

public enum AIModelDeleteStrategy {
    case ollama(name: String)
    case trash(url: URL)
    case none
}

public struct AIModelItem: Identifiable {
    public let id = UUID()
    public let provider: AIModelProvider
    public let name: String
    public let size: Int64
    public let modifiedDate: Date?
    public let url: URL?
    public let locationDescription: String
    public let details: String
    public let deleteStrategy: AIModelDeleteStrategy

    public init(
        provider: AIModelProvider,
        name: String,
        size: Int64,
        modifiedDate: Date?,
        url: URL?,
        locationDescription: String,
        details: String,
        deleteStrategy: AIModelDeleteStrategy
    ) {
        self.provider = provider
        self.name = name
        self.size = size
        self.modifiedDate = modifiedDate
        self.url = url
        self.locationDescription = locationDescription
        self.details = details
        self.deleteStrategy = deleteStrategy
    }

    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

public struct AIProviderState: Identifiable {
    public let provider: AIModelProvider
    public let items: [AIModelItem]
    public let totalSize: Int64
    public let roots: [URL]
    public let isDetected: Bool
    public let status: String
    public let canPull: Bool
    public let canDelete: Bool

    public var id: String { provider.id }
    public var itemCount: Int { items.count }
    public var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    public init(
        provider: AIModelProvider,
        items: [AIModelItem],
        totalSize: Int64,
        roots: [URL],
        isDetected: Bool,
        status: String,
        canPull: Bool,
        canDelete: Bool
    ) {
        self.provider = provider
        self.items = items
        self.totalSize = totalSize
        self.roots = roots
        self.isDetected = isDetected
        self.status = status
        self.canPull = canPull
        self.canDelete = canDelete
    }
}
