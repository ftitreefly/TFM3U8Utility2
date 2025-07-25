//
//  DIConfiguration.swift
//  TFM3U8Utility
//
//  Created by tree_fly on 2025/7/13.
//

import Foundation

/// Configuration settings for dependency injection and service behavior
/// 
/// This struct contains all configurable parameters that affect the behavior
/// of the M3U8 utility services, including external tool paths, network settings,
/// and performance parameters.
/// 
/// ## Usage Example
/// ```swift
/// let config = DIConfiguration(
///     ffmpegPath: "/usr/local/bin/ffmpeg",
///     curlPath: "/usr/bin/curl",
///     defaultHeaders: ["Authorization": "Bearer token"],
///     maxConcurrentDownloads: 10,
///     downloadTimeout: 120
/// )
/// 
/// // Use performance-optimized configuration
/// let optimizedConfig = DIConfiguration.performanceOptimized()
/// ```
public struct DIConfiguration: Sendable {
    /// Path to the FFmpeg executable for video processing
    public let ffmpegPath: String?
    
    /// Path to the curl executable for HTTP requests
    public let curlPath: String?
    
    /// Default HTTP headers to include in all requests
    public let defaultHeaders: [String: String]
    
    /// Maximum number of concurrent downloads allowed
    public let maxConcurrentDownloads: Int
    
    /// Timeout in seconds for download operations
    public let downloadTimeout: TimeInterval
    
    /// Initializes a new configuration instance
    /// 
    /// - Parameters:
    ///   - ffmpegPath: Path to FFmpeg executable (optional)
    ///   - curlPath: Path to curl executable (optional)
    ///   - defaultHeaders: Default HTTP headers (defaults to standard browser headers)
    ///   - maxConcurrentDownloads: Maximum concurrent downloads (default: 16)
    ///   - downloadTimeout: Download timeout in seconds (default: 300)
    public init(
        ffmpegPath: String? = nil,
        curlPath: String? = nil,
        defaultHeaders: [String: String] = ["User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"],
        maxConcurrentDownloads: Int = 16,
        downloadTimeout: TimeInterval = 300
    ) {
        self.ffmpegPath = ffmpegPath
        self.curlPath = curlPath
        self.defaultHeaders = defaultHeaders
        self.maxConcurrentDownloads = maxConcurrentDownloads
        self.downloadTimeout = downloadTimeout
    }
}

// MARK: - Configuration Extensions

extension DIConfiguration {
    /// Creates a performance-optimized configuration
    /// 
    /// This method returns a pre-configured instance optimized for high-performance
    /// M3U8 processing with common tool paths and optimized network settings.
    /// 
    /// ## Configuration Details
    /// - **FFmpeg**: `/opt/homebrew/bin/ffmpeg` (Homebrew installation)
    /// - **curl**: `/usr/bin/curl` (System installation)
    /// - **Concurrent Downloads**: 20 (high concurrency)
    /// - **Timeout**: 60 seconds (balanced for performance)
    /// - **Headers**: Comprehensive browser-like headers
    /// 
    /// - Returns: A performance-optimized configuration instance
    /// 
    /// ## Usage Example
    /// ```swift
    /// // Use the performance-optimized configuration
    /// let config = DIConfiguration.performanceOptimized()
    /// 
    /// // Configure the dependency container
    /// let container = DependencyContainer()
    /// container.configurePerformanceOptimized(with: config)
    /// ```
    public static func performanceOptimized() -> DIConfiguration {
        return DIConfiguration(
            ffmpegPath: "/opt/homebrew/bin/ffmpeg",
            curlPath: "/usr/bin/curl",
            defaultHeaders: [
                "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
                "Accept": "*/*",
                "Accept-Language": "en-US,en;q=0.9",
                "Cache-Control": "no-cache",
                "Connection": "keep-alive"
            ],
            maxConcurrentDownloads: 20,
            downloadTimeout: 60
        )
    }
}
