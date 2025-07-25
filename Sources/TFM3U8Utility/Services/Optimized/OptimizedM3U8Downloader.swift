//
//  OptimizedM3U8Downloader.swift
//  TFM3U8Utility
//
//  Created by tree_fly on 2025/7/13.
//

import Foundation

// MARK: - Performance-Optimized M3U8 Downloader

/// High-performance M3U8 downloader using Swift 6 features
public struct OptimizedM3U8Downloader: M3U8DownloaderProtocol {
    private let commandExecutor: CommandExecutorProtocol
    private let configuration: DIConfiguration
    
    public init(commandExecutor: CommandExecutorProtocol, configuration: DIConfiguration) {
        self.commandExecutor = commandExecutor
        self.configuration = configuration
    }
    
    public func downloadContent(from url: URL) async throws -> String {
        let data = try await downloadRawData(from: url)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    public func downloadRawData(from url: URL) async throws -> Data {
        var request = URLRequest(url: url, timeoutInterval: configuration.downloadTimeout)
        for (key, value) in configuration.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.serverError(url, statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        return data
    }
    
    public func downloadSegments(at urls: [URL], to directory: URL, headers: [String: String]) async throws {
        // Use TaskGroup for concurrent downloads with controlled concurrency
        let maxConcurrency = min(configuration.maxConcurrentDownloads, urls.count)
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            var activeDownloads = 0
            var urlIndex = 0
            
            // Start initial batch of downloads
            while activeDownloads < maxConcurrency && urlIndex < urls.count {
                let url = urls[urlIndex]
                group.addTask {
                    try await self.downloadSingleSegment(url: url, to: directory, headers: headers)
                }
                activeDownloads += 1
                urlIndex += 1
            }
            
            // Process completed downloads and start new ones
            while activeDownloads > 0 {
                try await group.next()
                activeDownloads -= 1
                
                // Start next download if available
                if urlIndex < urls.count {
                    let url = urls[urlIndex]
                    group.addTask {
                        try await self.downloadSingleSegment(url: url, to: directory, headers: headers)
                    }
                    activeDownloads += 1
                    urlIndex += 1
                }
            }
        }
    }
    
    private func downloadSingleSegment(url: URL, to directory: URL, headers: [String: String]) async throws {
        var request = URLRequest(url: url, timeoutInterval: configuration.downloadTimeout)
        
        // Add custom headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add default headers
        for (key, value) in configuration.defaultHeaders where !headers.keys.contains(key) {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.serverError(url, statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        let filename = url.lastPathComponent
        let fileURL = directory.appendingPathComponent(filename)
        
        try data.write(to: fileURL)
    }
} 
