//
//  DefaultFileSystemService.swift
//  TFM3U8Utility
//
//  Created by tree_fly on 2025/7/13.
//

import Foundation

// MARK: - Default File System Service

public struct DefaultFileSystemService: FileSystemServiceProtocol {
    // Use FileManager.default directly instead of storing it
    public init() {}
    
    public func createDirectory(at path: String, withIntermediateDirectories: Bool) throws {
        let expandedPath = NSString(string: path).expandingTildeInPath
        try FileManager.default.createDirectory(
            atPath: expandedPath,
            withIntermediateDirectories: withIntermediateDirectories,
            attributes: nil
        )
    }
    
    public func fileExists(at path: String) -> Bool {
        let expandedPath = NSString(string: path).expandingTildeInPath
        return FileManager.default.fileExists(atPath: expandedPath)
    }
    
    public func removeItem(at path: String) throws {
        let expandedPath = NSString(string: path).expandingTildeInPath
        try FileManager.default.removeItem(atPath: expandedPath)
    }
    
    public func createTemporaryDirectory(_ saltString: String? = nil) throws -> URL {
        let suffixString = saltString.map { String($0.hash, radix: 16).uppercased() } ?? UUID().uuidString
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("TFM3U8Utility_".appending(suffixString))
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    public func content(atPath path: String) throws -> String {
        let expandedPath = NSString(string: path).expandingTildeInPath
        guard let data = FileManager.default.contents(atPath: expandedPath),
              let content = String(data: data, encoding: .utf8) else {
            throw ProcessingError(
                code: 4004,
                underlyingError: nil,
                message: "Failed to read file",
                operation: "file reading"
            )
        }
        return content
    }
    
    public func contentsOfDirectory(at url: URL) throws -> [URL] {
        return try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
    }
    
    public func copyItem(at sourceURL: URL, to destinationURL: URL) throws {
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
    }
}
