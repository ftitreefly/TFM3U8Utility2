//
//  Types.swift
//  TFM3U8Utility
//
//  Created by tree_fly on 2025/7/13.
//

import Foundation

// MARK: - Download Method

/// Represents different methods for downloading M3U8 content
/// 
/// This enum defines the available methods for accessing M3U8 content,
/// whether from web URLs or local files.
public enum Method: Sendable, Equatable {
  /// Download from web URL (HTTP/HTTPS)
  case web
  /// Load from local file system
  case local
}

// MARK: - Download Quality

/// Represents different quality options for downloads
/// 
/// This enum defines quality selection strategies when multiple
/// quality variants are available in a master playlist.
public enum DownloadQuality: String, CaseIterable, Sendable {
  /// Automatically select the best quality based on network conditions
  case auto
  /// Always select the highest available quality
  case highest
  /// Always select the lowest available quality
  case lowest
  /// Use custom quality selection criteria
  case custom
}

// MARK: - Download State

/// Represents the state of a download task
/// 
/// This enum tracks the current state of a download operation
/// from initialization through completion or failure.
public enum DownloadState: String, CaseIterable, Sendable {
  /// Task is queued but not yet started
  case pending
  /// Task is actively downloading content
  case downloading
  /// Task is processing downloaded content
  case processing
  /// Task completed successfully
  case completed
  /// Task failed with an error
  case failed
  /// Task was cancelled by user or system
  case cancelled
}

// MARK: - Configuration

/// Configuration options for M3U8 downloads
/// 
/// This struct contains all configurable parameters for M3U8 download operations,
/// including concurrency limits, timeouts, and quality preferences.
/// 
/// ## Usage Example
/// ```swift
/// let config = DownloadConfiguration(
///     maxConcurrentDownloads: 5,
///     connectionTimeout: 60.0,
///     retryAttempts: 5,
///     qualityPreference: .highest,
///     cleanupTempFiles: true,
///     httpHeaders: ["Authorization": "Bearer token"]
/// )
/// ```
public struct DownloadConfiguration: Sendable {
  /// Maximum number of concurrent downloads allowed
  public let maxConcurrentDownloads: Int
  
  /// Connection timeout in seconds for network requests
  public let connectionTimeout: TimeInterval
  
  /// Number of retry attempts for failed downloads
  public let retryAttempts: Int
  
  /// Quality selection preference for multi-quality playlists
  public let qualityPreference: DownloadQuality
  
  /// Whether to clean up temporary files after completion
  public let cleanupTempFiles: Bool
  
  /// Custom headers to include in HTTP requests
  public let httpHeaders: [String: String]
  
  /// Default configuration with sensible defaults
  /// 
  /// Provides a balanced configuration suitable for most use cases:
  /// - 3 concurrent downloads
  /// - 30 second timeout
  /// - 3 retry attempts
  /// - Auto quality selection
  /// - Cleanup enabled
  /// - Standard browser User-Agent
  public static let `default` = DownloadConfiguration(
    maxConcurrentDownloads: 3,
    connectionTimeout: 30.0,
    retryAttempts: 3,
    qualityPreference: .auto,
    cleanupTempFiles: true,
    httpHeaders: [
      "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    ]
  )
  
  /// Initializes a new download configuration
  /// 
  /// - Parameters:
  ///   - maxConcurrentDownloads: Maximum concurrent downloads (default: 3)
  ///   - connectionTimeout: Connection timeout in seconds (default: 30.0)
  ///   - retryAttempts: Number of retry attempts (default: 3)
  ///   - qualityPreference: Quality selection preference (default: .auto)
  ///   - cleanupTempFiles: Whether to cleanup temp files (default: true)
  ///   - httpHeaders: Custom HTTP headers (default: empty, uses default User-Agent)
  public init(
    maxConcurrentDownloads: Int = 3,
    connectionTimeout: TimeInterval = 30.0,
    retryAttempts: Int = 3,
    qualityPreference: DownloadQuality = .auto,
    cleanupTempFiles: Bool = true,
    httpHeaders: [String: String] = [:]
  ) {
    self.maxConcurrentDownloads = maxConcurrentDownloads
    self.connectionTimeout = connectionTimeout
    self.retryAttempts = retryAttempts
    self.qualityPreference = qualityPreference
    self.cleanupTempFiles = cleanupTempFiles
    self.httpHeaders = httpHeaders.isEmpty ? DownloadConfiguration.default.httpHeaders : httpHeaders
  }
}

// MARK: - Progress Tracking

/// Represents download progress information
/// 
/// This struct provides comprehensive progress tracking for download operations,
/// including segment counts, byte counts, and timing information.
/// 
/// ## Usage Example
/// ```swift
/// let progress = DownloadProgress(
///     totalSegments: 100,
///     completedSegments: 45,
///     totalBytes: 1024 * 1024 * 100,
///     downloadedBytes: 1024 * 1024 * 45,
///     state: .downloading,
///     estimatedTimeRemaining: 120.0,
///     downloadSpeed: 1024 * 1024 // 1 MB/s
/// )
/// 
/// print("Progress: \(progress.progress * 100)%")
/// ```
public struct DownloadProgress: Sendable {
  /// Total number of segments to download
  public let totalSegments: Int
  
  /// Number of segments that have been completed
  public let completedSegments: Int
  
  /// Total bytes to download across all segments
  public let totalBytes: Int64
  
  /// Number of bytes that have been downloaded
  public let downloadedBytes: Int64
  
  /// Current state of the download operation
  public let state: DownloadState
  
  /// Estimated time remaining in seconds (optional)
  public let estimatedTimeRemaining: TimeInterval?
  
  /// Download speed in bytes per second (optional)
  public let downloadSpeed: Double?
  
  /// Progress as a percentage (0.0 to 1.0)
  /// 
  /// Calculated as the ratio of completed segments to total segments.
  /// Returns 0.0 if there are no segments to download.
  public var progress: Double {
    guard totalSegments > 0 else { return 0.0 }
    return Double(completedSegments) / Double(totalSegments)
  }
  
  /// Initializes a new download progress instance
  /// 
  /// - Parameters:
  ///   - totalSegments: Total number of segments to download
  ///   - completedSegments: Number of completed segments
  ///   - totalBytes: Total bytes to download
  ///   - downloadedBytes: Downloaded bytes
  ///   - state: Current download state
  ///   - estimatedTimeRemaining: Optional estimated time remaining
  ///   - downloadSpeed: Optional download speed in bytes per second
  public init(
    totalSegments: Int,
    completedSegments: Int,
    totalBytes: Int64,
    downloadedBytes: Int64,
    state: DownloadState,
    estimatedTimeRemaining: TimeInterval? = nil,
    downloadSpeed: Double? = nil
  ) {
    self.totalSegments = totalSegments
    self.completedSegments = completedSegments
    self.totalBytes = totalBytes
    self.downloadedBytes = downloadedBytes
    self.state = state
    self.estimatedTimeRemaining = estimatedTimeRemaining
    self.downloadSpeed = downloadSpeed
  }
}

// MARK: - Utility Extensions

extension Method {
  /// Human-readable description of the method
  /// 
  /// Returns a user-friendly string describing the download method.
  public var description: String {
    switch self {
    case .web:
      return "Web Download"
    case .local:
      return "Local File"
    }
  }
    
  /// Base URL for resolving relative URLs
  /// 
  /// Returns the base URL that should be used for resolving relative URLs
  /// in the M3U8 playlist. Currently returns nil for all methods.
  public var baseURL: URL? {
    return nil
  }
}

extension DownloadState {
  /// Whether the download is in a terminal state
  /// 
  /// Returns `true` if the download has reached a final state (completed,
  /// failed, or cancelled) and will not change further.
  public var isTerminal: Bool {
    switch self {
    case .completed, .failed, .cancelled:
      return true
    case .pending, .downloading, .processing:
      return false
    }
  }
  
  /// Whether the download is active
  /// 
  /// Returns `true` if the download is currently in progress (downloading
  /// or processing) and actively consuming resources.
  public var isActive: Bool {
    switch self {
    case .downloading, .processing:
      return true
    case .pending, .completed, .failed, .cancelled:
      return false
    }
  }
} 

// MARK: - Progress Callbacks

/// Detailed progress information for download tasks
/// 
/// This struct provides comprehensive progress information including
/// phase-specific details, timing information, and performance metrics.
/// 
/// ## Usage Example
/// ```swift
/// let progress = DetailedProgress(
///     phase: .downloadingSegments,
///     overallProgress: 0.75,
///     phaseProgress: 0.5,
///     statusMessage: "Downloading segment 45 of 90...",
///     downloadSpeed: 1024 * 1024,
///     estimatedTimeRemaining: 60.0,
///     metrics: progressMetrics
/// )
/// ```
public struct DetailedProgress: Sendable {
  /// Current phase of the download process
  public let phase: DownloadPhase
  
  /// Overall progress as a percentage (0.0 to 1.0)
  public let overallProgress: Double
  
  /// Phase-specific progress as a percentage (0.0 to 1.0)
  public let phaseProgress: Double
  
  /// Current status message for user display
  public let statusMessage: String
  
  /// Download speed in bytes per second (optional)
  public let downloadSpeed: Double?
  
  /// Estimated time remaining in seconds (optional)
  public let estimatedTimeRemaining: TimeInterval?
  
  /// Additional performance metrics (optional)
  public let metrics: ProgressMetrics?
  
  /// Initializes a new detailed progress instance
  /// 
  /// - Parameters:
  ///   - phase: Current download phase
  ///   - overallProgress: Overall progress (0.0 to 1.0)
  ///   - phaseProgress: Phase-specific progress (0.0 to 1.0)
  ///   - statusMessage: Status message for display
  ///   - downloadSpeed: Optional download speed in bytes per second
  ///   - estimatedTimeRemaining: Optional estimated time remaining
  ///   - metrics: Optional additional metrics
  public init(
    phase: DownloadPhase,
    overallProgress: Double,
    phaseProgress: Double,
    statusMessage: String,
    downloadSpeed: Double? = nil,
    estimatedTimeRemaining: TimeInterval? = nil,
    metrics: ProgressMetrics? = nil
  ) {
    self.phase = phase
    self.overallProgress = overallProgress
    self.phaseProgress = phaseProgress
    self.statusMessage = statusMessage
    self.downloadSpeed = downloadSpeed
    self.estimatedTimeRemaining = estimatedTimeRemaining
    self.metrics = metrics
  }
}

/// Represents different phases of the download process
/// 
/// This enum defines the various phases that a download operation goes through,
/// from initialization to completion. Each phase has a human-readable description
/// suitable for user interface display.
public enum DownloadPhase: String, CaseIterable, Sendable {
  /// Initializing the download task
  case initializing
  /// Downloading the M3U8 playlist file
  case downloadingPlaylist = "downloading_playlist"
  /// Parsing the M3U8 playlist content
  case parsingPlaylist = "parsing_playlist"
  /// Downloading video segments
  case downloadingSegments = "downloading_segments"
  /// Combining downloaded segments
  case combiningSegments = "combining_segments"
  /// Finalizing the download (cleanup, etc.)
  case finalizing
  /// Download completed successfully
  case completed
  /// Download failed with an error
  case failed
  
  /// Human-readable description for user interface display
  /// 
  /// Returns a localized string describing the current phase
  /// that can be displayed to users.
  public var description: String {
    switch self {
    case .initializing:
      return "Initializing..."
    case .downloadingPlaylist:
      return "Downloading playlist..."
    case .parsingPlaylist:
      return "Parsing playlist..."
    case .downloadingSegments:
      return "Downloading video segments..."
    case .combiningSegments:
      return "Combining video segments..."
    case .finalizing:
      return "Finalizing..."
    case .completed:
      return "Download completed"
    case .failed:
      return "Download failed"
    }
  }
}

/// Additional metrics for progress tracking
/// 
/// This struct provides detailed metrics for monitoring download performance
/// and progress, including timing information and retry counts.
/// 
/// ## Usage Example
/// ```swift
/// let metrics = ProgressMetrics(
///     totalSegments: 100,
///     completedSegments: 75,
///     totalBytes: 1024 * 1024 * 100,
///     downloadedBytes: 1024 * 1024 * 75,
///     retryCount: 2,
///     startTime: Date()
/// )
/// ```
public struct ProgressMetrics: Sendable {
  /// Total number of segments to download
  public let totalSegments: Int
  
  /// Number of segments that have been completed
  public let completedSegments: Int
  
  /// Total bytes to download across all segments
  public let totalBytes: Int64
  
  /// Number of bytes that have been downloaded
  public let downloadedBytes: Int64
  
  /// Number of retry attempts made
  public let retryCount: Int
  
  /// Start time of the download operation
  public let startTime: Date
  
  /// Initializes a new progress metrics instance
  /// 
  /// - Parameters:
  ///   - totalSegments: Total number of segments
  ///   - completedSegments: Number of completed segments
  ///   - totalBytes: Total bytes to download
  ///   - downloadedBytes: Downloaded bytes
  ///   - retryCount: Number of retry attempts
  ///   - startTime: Start time of the operation
  public init(
    totalSegments: Int,
    completedSegments: Int,
    totalBytes: Int64,
    downloadedBytes: Int64,
    retryCount: Int,
    startTime: Date
  ) {
    self.totalSegments = totalSegments
    self.completedSegments = completedSegments
    self.totalBytes = totalBytes
    self.downloadedBytes = downloadedBytes
    self.retryCount = retryCount
    self.startTime = startTime
  }

  /// Initializes metrics from a task info instance
  /// 
  /// Creates metrics from an existing task info, assuming the task
  /// is completed (completed segments equals total segments).
  /// 
  /// - Parameter taskInfo: The task info to extract metrics from
  public init(taskInfo: TaskInfo) {
    self.totalSegments = taskInfo.metrics.segmentCount
    self.completedSegments = taskInfo.metrics.segmentCount
    self.totalBytes = taskInfo.metrics.totalBytes
    self.downloadedBytes = taskInfo.metrics.totalBytes
    self.retryCount = 0
    self.startTime = taskInfo.startTime
  }
}

/// Progress callback function type
/// 
/// A closure that receives detailed progress updates during download operations.
/// This callback is called periodically to provide real-time progress information.
public typealias ProgressCallback = @Sendable (DetailedProgress) -> Void

/// Error callback function type
/// 
/// A closure that receives error notifications during download operations.
/// This callback is called when errors occur during the download process.
public typealias ErrorCallback = @Sendable (Error) -> Void

/// Completion callback function type
/// 
/// A closure that receives completion notifications for download operations.
/// This callback is called when a download operation completes (success or failure).
public typealias CompletionCallback = @Sendable (Result<URL, Error>) -> Void 
