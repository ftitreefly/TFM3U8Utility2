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
    
    /// Resource timeout in seconds for overall transfer operations
    public let resourceTimeout: TimeInterval
    
    /// Maximum automatic retry attempts for transient network failures
    public let retryAttempts: Int
    
    /// Base backoff (seconds) used for exponential retry delays
    public let retryBackoffBase: TimeInterval
    
    /// Minimum log level for the logger
    public let logLevel: LogLevel
    
    /// Initializes a new configuration instance
    /// 
    /// - Parameters:
    ///   - ffmpegPath: Path to FFmpeg executable (optional)
    ///   - curlPath: Path to curl executable (optional)
    ///   - defaultHeaders: Default HTTP headers (defaults to standard browser headers)
    ///   - maxConcurrentDownloads: Maximum concurrent downloads (default: 16)
    ///   - downloadTimeout: Per-request timeout in seconds (default: 300)
    ///   - resourceTimeout: Overall resource timeout in seconds (default: equals downloadTimeout)
    ///   - retryAttempts: Max automatic retry attempts for transient failures (default: 0)
    ///   - retryBackoffBase: Base seconds for exponential backoff (default: 0.5)
    ///   - logLevel: Minimum log level for logger (default: .info)
    public init(
        ffmpegPath: String? = nil,
        curlPath: String? = nil,
        defaultHeaders: [String: String] = ["User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"],
        maxConcurrentDownloads: Int = 16,
        downloadTimeout: TimeInterval = 300,
        resourceTimeout: TimeInterval? = nil,
        retryAttempts: Int = 0,
        retryBackoffBase: TimeInterval = 0.5,
        logLevel: LogLevel = .info
    ) {
        self.ffmpegPath = ffmpegPath
        self.curlPath = curlPath
        self.defaultHeaders = defaultHeaders
        self.maxConcurrentDownloads = maxConcurrentDownloads
        self.downloadTimeout = downloadTimeout
        self.resourceTimeout = resourceTimeout ?? downloadTimeout
        self.retryAttempts = max(0, retryAttempts)
        self.retryBackoffBase = max(0, retryBackoffBase)
        self.logLevel = logLevel
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
            downloadTimeout: 60,
            resourceTimeout: 120,
            retryAttempts: 2,
            retryBackoffBase: 0.4,
            logLevel: .error
        )
    }
}
