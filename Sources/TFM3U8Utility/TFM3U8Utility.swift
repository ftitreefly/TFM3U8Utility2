//
//  TFM3U8Utility.swift
//  TFM3U8Utility
//
//  Created by tree_fly on 2025/7/13.
//

import Foundation

// MARK: - Public API

/// The main public interface for TFM3U8Utility with modern error handling and dependency injection
/// 
/// This struct provides a high-level API for downloading and processing M3U8 video files.
/// It uses dependency injection for better testability and modularity.
/// 
/// ## Usage Example
/// ```swift
/// // Initialize the utility
/// await TFM3U8Utility.initialize()
/// 
/// // Download an M3U8 file
/// try await TFM3U8Utility.download(
///     .web,
///     url: URL(string: "https://example.com/video.m3u8")!,
///     savedDirectory: "/path/to/save",
///     name: "my-video"
/// ) { progress in
///     print("Download progress: \(progress)")
/// }
/// 
/// // Parse an M3U8 file
/// let result = try await TFM3U8Utility.parse(
///     url: URL(string: "https://example.com/video.m3u8")!
/// )
/// ```
public struct TFM3U8Utility {
    
    /// Initializes the dependency injection container with default services
    /// 
    /// This method must be called once at the start of your application to configure
    /// the dependency injection container with the appropriate services.
    /// 
    /// - Parameter configuration: Custom configuration for dependency injection. 
    ///   If not provided, uses performance-optimized configuration by default.
    /// - Note: Safe to call multiple times; subsequent calls reconfigure services.
    /// 
    /// ## Usage Example
    /// ```swift
    /// // Use default configuration
    /// await TFM3U8Utility.initialize()
    /// 
    /// // Use custom configuration
    /// let config = DIConfiguration()
    /// config.maxConcurrentDownloads = 10
    /// await TFM3U8Utility.initialize(with: config)
    /// ```
    @MainActor public static func initialize(with configuration: DIConfiguration = DIConfiguration.performanceOptimized()) async {
        await GlobalDependencies.shared.configure(with: configuration)
    }
    
    /// Downloads M3U8 content from a URL and processes it using dependency injection
    /// 
    /// This method downloads an M3U8 playlist file and all its associated video segments,
    /// saving them to the specified directory. It supports both web and local file sources.
    /// 
    /// - Parameters:
    ///   - method: The download method to use (`.web` for HTTP/HTTPS, `.local` for local files)
    ///   - url: The URL to download from (must be a valid M3U8 playlist URL)
    ///   - savedDirectory: Directory to save the downloaded content. Defaults to user's Downloads folder
    ///   - name: Optional name for the output file. If not provided, uses the original filename
    ///   - configuration: Configuration settings for the download operation
    ///   - verbose: Whether to output detailed information during the download process
    /// - Precondition: When `method == .web`, network connectivity is required.
    /// - Precondition: When `method == .local`, `url` must point to a readable local `.m3u8` file.
    /// 
    /// - Throws: 
    ///   - `FileSystemError.failedToCreateDirectory` if directory creation fails
    ///   - `NetworkError` if network requests fail
    ///   - `ParsingError` if M3U8 parsing fails
    ///   - `ProcessingError` if task creation fails
    /// 
    /// ## Usage Example
    /// ```swift
    /// try await TFM3U8Utility.download(
    ///     .web,
    ///     url: URL(string: "https://example.com/video.m3u8")!,
    ///     savedDirectory: "/Users/username/Downloads/videos/",
    ///     name: "my-video",
    ///     configuration: DIConfiguration.performanceOptimized(),
    ///     verbose: true
    /// )
    /// ```
    public static func download(
        _ method: Method = .web,
        url: URL,
        savedDirectory: URL?,
        name: String? = nil,
        configuration: DIConfiguration = DIConfiguration.performanceOptimized(),
        verbose: Bool = false
    ) async throws {
        await GlobalDependencies.shared.configure(with: configuration)
        
        Logger.configure(verbose ? .verbose() : .production())
        Logger.debug("Concurrent file downloads count: \(configuration.maxConcurrentDownloads), single file download timeout: \(configuration.downloadTimeout) seconds", category: .download)

        let finalSavedDirectory: URL
        if savedDirectory == nil {
            let paths = try await GlobalDependencies.shared.resolve(PathProviderProtocol.self)
            finalSavedDirectory = paths.downloadsDirectory()
        } else {
            finalSavedDirectory = savedDirectory!
        }
        
        let fileSystem = try await GlobalDependencies.shared.resolve(FileSystemServiceProtocol.self)
        if !fileSystem.fileExists(at: finalSavedDirectory) {
            do {
                try fileSystem.createDirectory(at: finalSavedDirectory, withIntermediateDirectories: true)
            } catch {
                throw FileSystemError.failedToCreateDirectory(finalSavedDirectory.path)
            }
        }
        
        let taskManager = try await GlobalDependencies.shared.resolve(TaskManagerProtocol.self)
        let baseUrl = method.baseURL ?? url.deletingLastPathComponent()
        
        let request = TaskRequest(
            url: url,
            baseUrl: baseUrl,
            savedDirectory: finalSavedDirectory,
            fileName: name,
            method: method,
            verbose: verbose
        )
        try await taskManager.createTask(request)
    }
    
    /// Parses an M3U8 file and returns the parsed result using dependency injection
    /// 
    /// This method downloads and parses an M3U8 playlist file, returning a structured
    /// representation of the playlist content. It supports both web URLs and local files.
    /// 
    /// - Parameters:
    ///   - url: The URL of the M3U8 file to parse
    ///   - method: The parsing method to use (`.web` for HTTP/HTTPS, `.local` for local files)
    ///   - configuration: Configuration settings for the parsing operation
    /// 
    /// - Returns: A `M3U8Parser.ParserResult` containing the parsed playlist data
    /// 
    /// - Throws: 
    ///   - `ParsingError` if the M3U8 content cannot be parsed
    ///   - `NetworkError` if network requests fail
    ///   - `FileSystemError.failedToReadFromFile` if local file reading fails
    /// - Precondition: When `method == .local`, `url` must be a readable file URL.
    /// 
    /// ## Usage Example
    /// ```swift
    /// // Parse from web URL
    /// let result = try await TFM3U8Utility.parse(
    ///     url: URL(string: "https://example.com/video.m3u8")!,
    ///     configuration: DIConfiguration.performanceOptimized()
    /// )
    /// 
    /// switch result {
    /// case .master(let masterPlaylist):
    ///     print("Master playlist with \(masterPlaylist.tags.streamTags.count) streams")
    /// case .media(let mediaPlaylist):
    ///     print("Media playlist with \(mediaPlaylist.tags.mediaSegments.count) segments")
    /// case .cancelled:
    ///     print("Parsing was cancelled")
    /// }
    /// 
    /// // Parse local file
    /// let localResult = try await TFM3U8Utility.parse(
    ///     url: URL(fileURLWithPath: "/path/to/local/playlist.m3u8"),
    ///     method: .local,
    ///     configuration: DIConfiguration.performanceOptimized()
    /// )
    /// ```
    public static func parse(
        url: URL,
        method: Method = .web,
        configuration: DIConfiguration = DIConfiguration.performanceOptimized()
    ) async throws -> M3U8Parser.ParserResult {
        await GlobalDependencies.shared.configure(with: configuration)
        let downloader = try await GlobalDependencies.shared.resolve(M3U8DownloaderProtocol.self)
        let parser = try await GlobalDependencies.shared.resolve(M3U8ParserServiceProtocol.self)
        
        do {
            let baseURL: URL
            
            if case .local = method {
                guard let localFileData = FileManager.default.contents(atPath: url.path),
                        let localFileContent = String(data: localFileData, encoding: .utf8) else {
                    throw FileSystemError.failedToReadFromFile(url.path)
                }
                baseURL = url.deletingLastPathComponent()
                return try parser.parseContent(localFileContent, baseURL: baseURL, type: .media)
            } else {
                let content = try await downloader.downloadContent(from: url)
                baseURL = method.baseURL ?? url.deletingLastPathComponent()
                return try parser.parseContent(content, baseURL: baseURL, type: .media)
            }
        } catch let error as ParsingError {
            throw error
        } catch {
            throw ParsingError(
                code: 2999,
                underlyingError: error,
                message: "Failed to parse M3U8 file",
                context: "URL: \(url.absoluteString)"
            )
        }
    }
}
