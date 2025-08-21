//
//  DefaultFileSystemService.swift
//  TFM3U8Utility
//
//  Created by tree_fly on 2025/7/13.
//

import Foundation

// MARK: - Default File System Service

public struct DefaultFileSystemService: FileSystemServiceProtocol, PathProviderProtocol {
    // Use FileManager.default directly instead of storing it
    public init() {}
    
    public func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws {
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: withIntermediateDirectories
        )
    }
    
    public func fileExists(at url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    public func removeItem(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
    
    public func createTemporaryDirectory(_ saltString: String? = nil) throws -> URL {
        let suffixString = saltString.map { String($0.hash, radix: 16).uppercased() } ?? UUID().uuidString
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("TFM3U8Utility_".appending(suffixString))
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    public func content(at url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw FileSystemError.failedToReadFromFile(url.path)
        }
        return content
    }
    
    public func contentsOfDirectory(at url: URL) throws -> [URL] {
        return try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
    }
    
    public func copyItem(at sourceURL: URL, to destinationURL: URL) throws {
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
    }
    
    // MARK: - PathProviderProtocol
    public func downloadsDirectory() -> URL {
        let urls = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)
        return (urls.first ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads"))
    }
    
    public func temporaryDirectory() -> URL {
        return FileManager.default.temporaryDirectory
    }
}
