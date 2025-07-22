//
//  OptimizedTaskManager.swift
//  TFM3U8Utility
//
//  Created by tree_fly on 2025/7/11.
//

import Foundation

// MARK: - Optimized Task Manager

/// Information about a download task including status and metrics
/// 
/// This struct contains all the information needed to track and manage
/// a single M3U8 download task, including its current status, progress,
/// and performance metrics.
public struct TaskInfo: Sendable {
    /// Unique identifier for the task
    let id: String
    
    /// The URL of the M3U8 file to download
    let url: URL
    
    /// Base URL for resolving relative segment URLs
    let baseUrl: URL?
    
    /// Directory where the final video file will be saved
    let savedDirectory: String
    
    /// Optional custom filename for the output video
    let fileName: String?
    
    /// The download method (web or local)
    let method: Method
    
    /// Current status of the task
    var status: TaskStatus
    
    /// When the task was started
    var startTime: Date
    
    /// Performance metrics for the task
    var metrics: TaskMetrics
    
    /// Optional callback for progress updates
    var progressCallback: ProgressCallback?
}

/// Performance metrics for a download task
/// 
/// Tracks various performance indicators during task execution,
/// including timing information and resource usage.
public struct TaskMetrics: Sendable {
    /// Time spent downloading the playlist and segments
    var downloadDuration: TimeInterval = 0
    
    /// Time spent processing and combining segments
    var processingDuration: TimeInterval = 0
    
    /// Number of video segments in the playlist
    var segmentCount: Int = 0
    
    /// Total bytes downloaded across all segments
    var totalBytes: Int64 = 0
}

/// Represents the status of a download task
/// 
/// Tracks the current state of a task from initialization through completion,
/// including progress information for active downloads.
public enum TaskStatus: Sendable {
    /// Task is queued but not yet started
    case pending
    
    /// Task is currently downloading with progress percentage
    case downloading(progress: Double)
    
    /// Task is processing downloaded segments
    case processing
    
    /// Task completed successfully
    case completed
    
    /// Task failed with an error
    case failed(Error)
    
    /// Task was cancelled by user or system
    case cancelled
}

/// High-performance task manager using Swift 6 actor features for M3U8 download management
/// 
/// This actor provides a thread-safe, high-performance task management system for
/// downloading and processing M3U8 video files. It uses Swift 6 concurrency features
/// for optimal performance and memory efficiency.
/// 
/// ## Features
/// - Thread-safe task management using Swift actors
/// - Concurrent task execution with configurable limits
/// - Comprehensive progress tracking and callbacks
/// - Performance metrics collection
/// - Automatic error handling and retry logic
/// - Memory-efficient processing of large video files
/// 
/// ## Usage Example
/// ```swift
/// let taskManager = OptimizedTaskManager(
///     downloader: downloader,
///     parser: parser,
///     processor: processor,
///     fileSystem: fileSystem,
///     configuration: configuration,
///     maxConcurrentTasks: 3
/// )
/// 
/// // Create and execute a download task
/// try await taskManager.createTask(
///     url: m3u8URL,
///     baseUrl: nil,
///     savedDirectory: "/path/to/save",
///     fileName: "my-video",
///     method: .web,
///     progressCallback: { progress in
///         print("Phase: \(progress.phase)")
///         print("Progress: \(progress.overallProgress * 100)%")
///         print("Status: \(progress.statusMessage)")
///     }
/// )
/// 
/// // Check task status
/// let status = await taskManager.getTaskStatus(for: taskId)
/// 
/// // Get performance metrics
/// let metrics = await taskManager.getPerformanceMetrics()
/// ```
public actor OptimizedTaskManager: TaskManagerProtocol {
    /// The downloader service for fetching M3U8 content
    private let downloader: M3U8DownloaderProtocol
    
    /// The parser service for processing M3U8 playlists
    private let parser: M3U8ParserServiceProtocol
    
    /// The video processor for combining segments
    private let processor: VideoProcessorProtocol
    
    /// The file system service for file operations
    private let fileSystem: FileSystemServiceProtocol
    
    /// Configuration settings for task execution
    private let configuration: DIConfiguration
    
    /// Temporary directory for processing files
    private var tempDir: URL = FileManager.default.temporaryDirectory
    
    /// Active tasks indexed by task ID
    private var tasks: [String: TaskInfo] = [:]
    
    /// Number of currently active tasks
    private var activeTasksCount = 0
    
    /// Maximum number of concurrent tasks allowed
    private let maxConcurrentTasks: Int
    
    // Performance metrics
    /// Total time spent downloading across all completed tasks
    private var totalDownloadTime: TimeInterval = 0
    
    /// Total time spent processing across all completed tasks
    private var totalProcessingTime: TimeInterval = 0
    
    /// Number of tasks that have completed successfully
    private var completedTasks: Int = 0
    
    /// Initializes a new optimized task manager
    /// 
    /// - Parameters:
    ///   - downloader: Service for downloading M3U8 content
    ///   - parser: Service for parsing M3U8 playlists
    ///   - processor: Service for video processing operations
    ///   - fileSystem: Service for file system operations
    ///   - configuration: Configuration settings (defaults to performance-optimized)
    ///   - maxConcurrentTasks: Maximum number of concurrent tasks (defaults to 3)
    public init(
        downloader: M3U8DownloaderProtocol,
        parser: M3U8ParserServiceProtocol,
        processor: VideoProcessorProtocol,
        fileSystem: FileSystemServiceProtocol,
        configuration: DIConfiguration = .performanceOptimized(),
        maxConcurrentTasks: Int = 3
    ) {
        self.downloader = downloader
        self.parser = parser
        self.processor = processor
        self.fileSystem = fileSystem
        self.configuration = configuration
        self.maxConcurrentTasks = maxConcurrentTasks
    }
    
    /// Creates and executes a new download task
    /// 
    /// This method creates a new task for downloading and processing an M3U8 video file.
    /// The task will download the playlist, parse it, download all segments, and combine
    /// them into a single video file.
    /// 
    /// - Parameter request: The task request containing all necessary parameters
    /// 
    /// - Throws: 
    ///   - `ProcessingError.operationCancelled` if maximum concurrent tasks reached
    ///   - `ProcessingError` with various codes for different failure scenarios
    ///   - `NetworkError` if network requests fail
    ///   - `FileSystemError` if file operations fail
    /// 
    /// ## Usage Example
    /// ```swift
    /// let request = TaskRequest(
    ///     url: URL(string: "https://example.com/video.m3u8")!,
    ///     baseUrl: nil,
    ///     savedDirectory: "/Users/username/Downloads/",
    ///     fileName: "my-video",
    ///     method: .web,
    ///     verbose: true
    /// )
    /// try await taskManager.createTask(request)
    /// ```
    public func createTask(_ request: TaskRequest) async throws {
        guard activeTasksCount < maxConcurrentTasks else {
            throw ProcessingError.operationCancelled("Maximum concurrent tasks reached")
        }
        
        let taskId = generateTaskId(for: request.url)
        activeTasksCount += 1
        
        vprintf(request.verbose, "Current active tasks: \(activeTasksCount)/\(maxConcurrentTasks)")
        defer {
            activeTasksCount -= 1
            vprintf(request.verbose, "Task completed, current active tasks: \(activeTasksCount)/\(maxConcurrentTasks)")
        }
        
        var taskInfo = TaskInfo(
            id: taskId,
            url: request.url,
            baseUrl: request.baseUrl,
            savedDirectory: request.savedDirectory,
            fileName: request.fileName,
            method: request.method,
            status: TaskStatus.pending,
            startTime: Date(),
            metrics: TaskMetrics()
        )
        
        tasks[taskId] = taskInfo
        
        do {
            try await executeTaskWithMetrics(taskInfo: &taskInfo, verbose: request.verbose)
            taskInfo.status = TaskStatus.completed
            tasks[taskId] = taskInfo
            
            completedTasks += 1
            totalDownloadTime += taskInfo.metrics.downloadDuration
            totalProcessingTime += taskInfo.metrics.processingDuration
            
        } catch {
            taskInfo.status = TaskStatus.failed(error)
            tasks[taskId] = taskInfo
            
            if let processingError = error as? ProcessingError {
                throw processingError
            } else {
                throw ProcessingError(
                    code: 4999,
                    underlyingError: error,
                    message: "Optimized task execution failed",
                    operation: "task execution"
                )
            }
        }
    }
    
    /// Gets the current status of a task
    /// 
    /// - Parameter taskId: The unique identifier of the task
    /// 
    /// - Returns: The current status of the task, or `nil` if the task doesn't exist
    public func getTaskStatus(for taskId: String) async -> TaskStatus? {
        return tasks[taskId]?.status
    }
    
    /// Cancels a running task
    /// 
    /// - Parameter taskId: The unique identifier of the task to cancel
    /// 
    /// - Throws: `ProcessingError` with code 4005 if the task is not found
    public func cancelTask(taskId: String) async throws {
        guard tasks[taskId] != nil else {
            throw ProcessingError(
                code: 4005,
                underlyingError: nil,
                message: "Task not found",
                operation: "cancel"
            )
        }
        
        tasks[taskId]?.status = TaskStatus.cancelled
        activeTasksCount = max(0, activeTasksCount - 1)
    }
    
    /// Gets performance metrics for monitoring and optimization
    /// 
    /// Returns aggregated performance metrics across all completed tasks,
    /// useful for monitoring system performance and identifying bottlenecks.
    /// 
    /// - Returns: Performance metrics including average times and task counts
    public func getPerformanceMetrics() async -> PerformanceMetrics {
        let avgDownloadTime = completedTasks > 0 ? totalDownloadTime / Double(completedTasks) : 0
        let avgProcessingTime = completedTasks > 0 ? totalProcessingTime / Double(completedTasks) : 0
        
        return PerformanceMetrics(
            completedTasks: completedTasks,
            activeTasks: activeTasksCount,
            averageDownloadTime: avgDownloadTime,
            averageProcessingTime: avgProcessingTime,
            totalExecutionTime: totalDownloadTime + totalProcessingTime
        )
    }
    
    // MARK: - Helper Methods
    
    /// Helper to get output file name
    private func getOutputFileName(from url: URL, customName: String?) -> String {
        let originalName = url.lastPathComponent.replacingOccurrences(of: ".m3u8", with: ".mp4")
        var fileName = customName ?? originalName
        if !fileName.hasSuffix(".mp4") { fileName += ".mp4" }
        return fileName
    }
    
    /// Helper to format download progress display
    private func displayProgress(completed: Int, total: Int, speed: Double, startTime: Date) {
        let percentage = Double(completed) / Double(total) * 100
        let speedFormatted = formatBytes(Int64(speed))
        print("\r📊 Completed \(completed)/\(total) segments (\(String(format: "%.1f", percentage))%) | Speed: \(speedFormatted)/s", terminator: "")
        fflush(stdout)
        if completed == total { print("") }
    }
    
    // MARK: - Private Methods

    /// Execute a task with metrics tracking
    /// 
    /// This method executes a task and tracks its performance metrics,
    /// including download and processing times. It also handles the
    /// download and parsing of the M3U8 content.
    /// 
    /// - Parameters:
    ///   - taskInfo: The task information to execute
    ///   - verbose: Whether to output detailed information
    private func executeTaskWithMetrics(taskInfo: inout TaskInfo, verbose: Bool = false) async throws {
        _ = Date() // Mark start time for potential future metrics
        self.tempDir = try fileSystem.createTemporaryDirectory(taskInfo.url.absoluteString)
        
        vprintf(verbose, "Creating temporary directory: \(tempDir.path)")

        // Step 1: Download and parse M3U8
        taskInfo.status = TaskStatus.downloading(progress: 0.1)
        
        let downloadStartTime = Date()
        let (content, effectiveBaseUrl) = try await downloadAndParseContent(taskInfo: taskInfo, verbose: verbose)
        
        // Step 2: Parse playlist
        taskInfo.status = TaskStatus.downloading(progress: 0.2)
        
        let parseResult = try parser.parseContent(content, baseURL: effectiveBaseUrl, type: .media)
        
        taskInfo.metrics.downloadDuration = Date().timeIntervalSince(downloadStartTime)
        
        // Step 3: Process segments
        let processingStartTime = Date()
        
        switch parseResult {
        case .media(let mediaPlaylist):
            try await processMediaPlaylistOptimized(mediaPlaylist, taskInfo: &taskInfo, verbose: verbose)
        case .master:
            throw ProcessingError(
                code: 4006,
                underlyingError: nil,
                message: "Master playlists not supported yet",
                operation: "download"
            )
        case .cancelled:
            throw ProcessingError.operationCancelled("parsing")
        }
        
        taskInfo.metrics.processingDuration = Date().timeIntervalSince(processingStartTime)
        
        // Step 4: Copy file
        try processCopyFile(taskInfo)

        // Step 5: Clean up
        try fileSystem.removeItem(at: tempDir.path)
    }
    
    /// Download and parse content from the task
    /// 
    /// This method downloads the content from the task's URL and parses it,
    /// returning the content and the base URL.
    /// 
    /// - Parameters:
    ///   - taskInfo: The task information to download and parse
    ///   - verbose: Whether to output detailed information
    private func downloadAndParseContent(taskInfo: TaskInfo, verbose: Bool = false) async throws -> (String, URL) {
        if case .local = taskInfo.method {
            vprintf(verbose, "Reading from local file: \(taskInfo.url.path)")
            let content = try fileSystem.content(atPath: taskInfo.url.path)
            let baseUrl = taskInfo.baseUrl ?? taskInfo.url.deletingLastPathComponent()
            return (content, baseUrl)
        } else {
            vprintf(verbose, "Downloading from network: \(taskInfo.url.absoluteString)")
            let content = try await downloader.downloadContent(from: taskInfo.url)
            let baseUrl = taskInfo.baseUrl ?? taskInfo.url.deletingLastPathComponent()
            return (content, baseUrl)
        }
    }
    
    /// Process a media playlist
    /// 
    /// This method processes a media playlist by extracting and validating
    /// segment URLs, downloading segments with progress tracking, and
    /// calculating total bytes processed.
    /// 
    /// - Parameters:
    ///   - playlist: The media playlist to process
    ///   - taskInfo: The task information to update
    ///   - verbose: Whether to output detailed information
    private func processMediaPlaylistOptimized(_ playlist: MediaPlaylist, taskInfo: inout TaskInfo, verbose: Bool = false) async throws { 
        // Extract and validate segment URLs
        let segmentURLs = playlist.tags.mediaSegments.compactMap { segment in
            URL(string: segment.uri, relativeTo: playlist.baseUrl)
        }
        
        guard !segmentURLs.isEmpty else {
            throw ProcessingError(
                code: 4008,
                underlyingError: nil,
                message: "No valid segments found",
                operation: "segment extraction"
            )
        }
        
        taskInfo.metrics.segmentCount = segmentURLs.count
        
        // Download segments with progress tracking
        taskInfo.status = TaskStatus.downloading(progress: 0.3)
        print("⬇️  Starting .ts file download...")
        try await downloadSegmentsWithProgress(segmentURLs, to: tempDir, taskInfo: &taskInfo, verbose: verbose)
        
        // Calculate and display total bytes processed
        taskInfo.metrics.totalBytes = try await calculateTotalBytes(in: tempDir)
        print("📊 Total processed: \(formatBytes(taskInfo.metrics.totalBytes)) data")

        // Combine segments
        taskInfo.status = TaskStatus.processing
        
        print("🔗 Combining video segments...")
        let outputPath = tempDir.appendingPathComponent(getOutputFileName(from: taskInfo.url, customName: nil))
        try await processor.combineSegments(in: tempDir, outputFile: outputPath)
    }
    
    /// Process the final copy of the file
    /// 
    /// This method copies the processed file to the specified output directory,
    /// handling the case where the file already exists by appending a number.
    /// 
    /// - Parameters:
    ///   - taskInfo: The task information to process
    ///   - verbose: Whether to output detailed information
    private func processCopyFile(_ taskInfo: TaskInfo) throws {
        let outputFileName = getOutputFileName(from: taskInfo.url, customName: taskInfo.fileName)
        let outputPath = URL(fileURLWithPath: taskInfo.savedDirectory).appendingPathComponent(outputFileName)   
        
        let originalName = getOutputFileName(from: taskInfo.url, customName: nil)
        if FileManager.default.fileExists(atPath: outputPath.path) {
            let newFileName = outputFileName.replacingOccurrences(of: ".mp4", with: "_1.mp4")
            let newOutputPath = URL(fileURLWithPath: taskInfo.savedDirectory).appendingPathComponent(newFileName)
            try? fileSystem.copyItem(at: tempDir.appendingPathComponent(originalName), to: newOutputPath)
            print("📁 File already exists, renamed and saved as \(newOutputPath.path)")
        } else {
            try fileSystem.copyItem(at: tempDir.appendingPathComponent(originalName), to: outputPath)
            print("📁 File saved as \(outputPath.path)")
        }
    }

    /// Calculate the total bytes of all files in a directory
    /// 
    /// This method calculates the total size of all files in a given directory,
    /// including hidden files.
    /// 
    /// - Parameter directory: The directory to calculate the total bytes of
    private func calculateTotalBytes(in directory: URL) async throws -> Int64 {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                do {
                    let contents = try FileManager.default.contentsOfDirectory(
                        at: directory,
                        includingPropertiesForKeys: [.fileSizeKey],
                        options: .skipsHiddenFiles
                    )
                    
                    let totalBytes = contents.reduce(Int64(0)) { total, url in
                        let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                        return total + Int64(fileSize)
                    }
                    
                    continuation.resume(returning: totalBytes)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func generateTaskId(for url: URL) -> String {
        String(url.absoluteString.hash, radix: 16)
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
    
    /// Download segments with progress tracking
    /// 
    /// This method downloads segments from a list of URLs with progress tracking,
    /// calculating the total bytes downloaded and displaying real-time progress.
    /// 
    /// - Parameters:
    ///   - urls: 
    ///   - directory: 
    ///   - taskInfo: 
    /// - Throws: 
    private func downloadSegmentsWithProgress(_ urls: [URL], to directory: URL, taskInfo: inout TaskInfo, verbose: Bool = false) async throws {
        let (totalSegments, downloadStartTime) = (urls.count, Date())
        var (completedSegments, totalDownloadedBytes) = (0, Int64(0))
        
        // Get configuration once
        let maxConcurrency = min(configuration.maxConcurrentDownloads, totalSegments)
        
        try await withThrowingTaskGroup(of: (Int, Int64).self) { group in
            var activeDownloads = 0
            var urlIndex = 0
            
            // Start initial batch of downloads
            while activeDownloads < maxConcurrency && urlIndex < urls.count {
                let url = urls[urlIndex]
                let index = urlIndex
                group.addTask {
                    let downloadedBytes = try await self.downloadSingleSegmentWithProgress(url: url, to: directory, config: self.configuration)
                    return (index, downloadedBytes)
                }
                activeDownloads += 1
                urlIndex += 1
            }
            
            // Process completed downloads and start new ones
            while activeDownloads > 0 {
                guard let (_, downloadedBytes) = try await group.next() else {
                    break
                }
                activeDownloads -= 1
                completedSegments += 1
                totalDownloadedBytes += downloadedBytes
                // Calculate progress metrics
                let elapsedTime = Date().timeIntervalSince(downloadStartTime)
                let downloadSpeed = elapsedTime > 0 ? Double(totalDownloadedBytes) / elapsedTime : 0

                // Display real-time progress
                displayProgress(
                    completed: completedSegments,
                    total: totalSegments,
                    speed: downloadSpeed,
                    startTime: downloadStartTime
                )
                
                // Start next download if available
                if urlIndex < urls.count {
                    let url = urls[urlIndex]
                    let index = urlIndex
                    group.addTask {
                        let downloadedBytes = try await self.downloadSingleSegmentWithProgress(url: url, to: directory, config: self.configuration)
                        return (index, downloadedBytes)
                    }
                    activeDownloads += 1
                    urlIndex += 1
                }
            }
        }
    }
    
    /// Download a single segment with progress tracking
    /// 
    /// This method downloads a single segment from a given URL, writes it to
    /// a specified directory, and returns the number of bytes downloaded.
    /// 
    /// - Parameters:
    ///   - url: The URL of the segment to download
    ///   - directory: The directory to write the downloaded segment to
    ///   - config: The configuration to use for the download
    /// - Returns: The number of bytes downloaded
    /// - Throws: 
    private func downloadSingleSegmentWithProgress(url: URL, to directory: URL, config: DIConfiguration) async throws -> Int64 {
        var request = URLRequest(url: url, timeoutInterval: config.downloadTimeout)
        
        // Add default headers
        for (key, value) in config.defaultHeaders {
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
        
        return Int64(data.count)
    }
}

// MARK: - Performance Metrics

public struct PerformanceMetrics: Sendable {
    public let completedTasks: Int
    public let activeTasks: Int
    public let averageDownloadTime: TimeInterval
    public let averageProcessingTime: TimeInterval
    public let totalExecutionTime: TimeInterval
    
    public var throughput: Double {
        totalExecutionTime > 0 ? Double(completedTasks) / totalExecutionTime : 0
    }
}

// MARK: - Performance Metrics Extensions

public extension PerformanceMetrics {
    /// Human-readable performance summary
    var summary: String {
        return """
        Performance Summary:
        - Completed Tasks: \(completedTasks)
        - Active Tasks: \(activeTasks)
        - Average Download: \(String(format: "%.2f", averageDownloadTime))s
        - Average Processing: \(String(format: "%.2f", averageProcessingTime))s
        - Throughput: \(String(format: "%.2f", throughput)) tasks/sec
        - Total Time: \(String(format: "%.2f", totalExecutionTime))s
        """
    }
    
    /// Performance rating based on throughput
    var rating: String {
        switch throughput {
        case 0..<0.1: return "Poor"
        case 0.1..<0.5: return "Fair"
        case 0.5..<1.0: return "Good"
        case 1.0..<2.0: return "Very Good"
        default: return "Excellent"
        }
    }
}
