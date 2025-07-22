//
//  ServiceProtocols.swift
//  TFM3U8Utility
//
//  Created by tree_fly on 2025/7/9.
//

import Foundation

// MARK: - Service Protocols

/// Protocol for downloading M3U8 content from various sources
/// 
/// This protocol defines the interface for downloading M3U8 playlist files and
/// their associated video segments. Implementations should handle both HTTP/HTTPS
/// and local file access with proper error handling and retry logic.
/// 
/// ## Usage Example
/// ```swift
/// class MyDownloader: M3U8DownloaderProtocol {
///     func downloadContent(from url: URL) async throws -> String {
///         let data = try await downloadRawData(from: url)
///         return String(data: data, encoding: .utf8) ?? ""
///     }
///     
///     func downloadRawData(from url: URL) async throws -> Data {
///         // Implementation for downloading raw data
///     }
///     
///     func downloadSegments(at urls: [URL], to directory: URL, headers: [String: String]) async throws {
///         // Implementation for downloading segments
///     }
/// }
/// ```
public protocol M3U8DownloaderProtocol: Sendable {
    /// Downloads M3U8 content from a URL and returns it as a string
    /// 
    /// This method downloads the content of an M3U8 playlist file and returns
    /// it as a UTF-8 encoded string for further processing.
    /// 
    /// - Parameter url: The URL of the M3U8 file to download
    /// 
    /// - Returns: The M3U8 content as a string
    /// 
    /// - Throws: 
    ///   - `NetworkError` if the network request fails
    ///   - `ProcessingError` if the content cannot be decoded
    func downloadContent(from url: URL) async throws -> String
    
    /// Downloads raw data from a URL
    /// 
    /// This method downloads the raw bytes from a URL, useful for binary files
    /// or when you need to handle the data format yourself.
    /// 
    /// - Parameter url: The URL to download from
    /// 
    /// - Returns: The raw data bytes
    /// 
    /// - Throws: `NetworkError` if the network request fails
    func downloadRawData(from url: URL) async throws -> Data
    
    /// Downloads multiple video segments concurrently
    /// 
    /// This method downloads multiple video segment files concurrently and saves
    /// them to the specified directory. It should handle retry logic and progress
    /// tracking for large downloads.
    /// 
    /// - Parameters:
    ///   - urls: Array of URLs for the video segments to download
    ///   - directory: The directory where segments should be saved
    ///   - headers: HTTP headers to include in the requests
    /// 
    /// - Throws: 
    ///   - `NetworkError` if any segment download fails
    ///   - `FileSystemError` if files cannot be saved
    func downloadSegments(at urls: [URL], to directory: URL, headers: [String: String]) async throws
}

/// Protocol for parsing M3U8 playlist content
/// 
/// This protocol defines the interface for parsing M3U8 playlist files and
/// extracting structured data from them. Implementations should handle both
/// master playlists and media playlists with proper error handling.
/// 
/// ## Usage Example
/// ```swift
/// class MyParser: M3U8ParserServiceProtocol {
///     func parseContent(_ content: String, baseURL: URL, type: PlaylistType) throws -> M3U8Parser.ParserResult {
///         let parser = M3U8Parser()
///         let params = M3U8ParserParams(
///             playlist: content,
///             baseUrl: baseURL,
///             playlistType: type
///         )
///         return try parser.parse(params: params)
///     }
/// }
/// ```
public protocol M3U8ParserServiceProtocol: Sendable {
    /// Parses M3U8 content and returns the structured result
    /// 
    /// This method parses M3U8 playlist content and returns a structured
    /// representation that can be used for further processing.
    /// 
    /// - Parameters:
    ///   - content: The M3U8 content as a string
    ///   - baseURL: The base URL for resolving relative URLs in the playlist
    ///   - type: The expected type of playlist (master, media, etc.)
    /// 
    /// - Returns: A structured representation of the parsed playlist
    /// 
    /// - Throws: 
    ///   - `ParsingError` if the content cannot be parsed
    ///   - `ProcessingError` if the playlist type is not supported
    func parseContent(_ content: String, baseURL: URL, type: PlaylistType) throws -> M3U8Parser.ParserResult
}

/// Protocol for video processing operations
/// 
/// This protocol defines the interface for video processing operations such as
/// combining video segments and decrypting encrypted content. Implementations
/// typically use external tools like FFmpeg for these operations.
/// 
/// ## Usage Example
/// ```swift
/// class MyProcessor: VideoProcessorProtocol {
///     func combineSegments(in directory: URL, outputFile: URL) async throws {
///         // Implementation using FFmpeg to combine segments
///     }
///     
///     func decryptSegment(at url: URL, to outputURL: URL, keyURL: URL?) async throws {
///         // Implementation for decrypting segments
///     }
/// }
/// ```
public protocol VideoProcessorProtocol: Sendable {
    /// Combines multiple video segments into a single output file
    /// 
    /// This method finds all video segment files in the specified directory
    /// and combines them into a single video file using external tools.
    /// 
    /// - Parameters:
    ///   - directory: The directory containing the video segments
    ///   - outputFile: The URL where the combined video file will be saved
    /// 
    /// - Throws: 
    ///   - `ProcessingError` if no segments are found or combination fails
    ///   - `CommandExecutionError` if the external tool fails
    ///   - `FileSystemError` if file operations fail
    func combineSegments(in directory: URL, outputFile: URL) async throws
    
    /// Decrypts an encrypted video segment
    /// 
    /// This method decrypts an encrypted video segment using the provided
    /// decryption key and saves the decrypted content to the output location.
    /// 
    /// - Parameters:
    ///   - url: The URL of the encrypted segment file
    ///   - outputURL: The URL where the decrypted segment will be saved
    ///   - keyURL: Optional URL to the decryption key file
    /// 
    /// - Throws: 
    ///   - `ProcessingError` if decryption fails
    ///   - `CommandExecutionError` if the external tool fails
    ///   - `FileSystemError` if file operations fail
    func decryptSegment(at url: URL, to outputURL: URL, keyURL: URL?) async throws
}

/// Protocol for file system operations
/// 
/// This protocol defines the interface for file system operations such as
/// creating directories, checking file existence, and copying files. It provides
/// an abstraction layer for file system access.
/// 
/// ## Usage Example
/// ```swift
/// class MyFileSystem: FileSystemServiceProtocol {
///     func createDirectory(at path: String, withIntermediateDirectories: Bool) throws {
///         try FileManager.default.createDirectory(
///             atPath: path,
///             withIntermediateDirectories: withIntermediateDirectories
///         )
///     }
///     
///     func fileExists(at path: String) -> Bool {
///         return FileManager.default.fileExists(atPath: path)
///     }
///     
///     // ... other method implementations
/// }
/// ```
public protocol FileSystemServiceProtocol: Sendable {
    /// Creates a directory at the specified path
    /// 
    /// - Parameters:
    ///   - path: The path where the directory should be created
    ///   - withIntermediateDirectories: Whether to create intermediate directories
    /// 
    /// - Throws: `FileSystemError` if directory creation fails
    func createDirectory(at path: String, withIntermediateDirectories: Bool) throws
    
    /// Checks if a file exists at the given path
    /// 
    /// - Parameter path: The path to check
    /// 
    /// - Returns: `true` if the file exists, `false` otherwise
    func fileExists(at path: String) -> Bool
    
    /// Removes a file or directory from the file system
    /// 
    /// - Parameter path: The path of the file or directory to remove
    /// 
    /// - Throws: `FileSystemError` if removal fails
    func removeItem(at path: String) throws
    
    /// Creates a temporary directory and returns its URL
    /// 
    /// - Parameter saltString: Optional string to make the directory name unique
    /// 
    /// - Returns: The URL of the created temporary directory
    /// 
    /// - Throws: `FileSystemError` if directory creation fails
    func createTemporaryDirectory(_ saltString: String?) throws -> URL
  
    /// Returns the content of a file as a string
    /// 
    /// - Parameter path: The path of the file to read
    /// 
    /// - Returns: The file content as a string
    /// 
    /// - Throws: `FileSystemError` if the file cannot be read
    func content(atPath path: String) throws -> String

    /// Returns the contents of a directory
    /// 
    /// - Parameter url: The URL of the directory to list
    /// 
    /// - Returns: Array of URLs for items in the directory
    /// 
    /// - Throws: `FileSystemError` if the directory cannot be accessed
    func contentsOfDirectory(at url: URL) throws -> [URL]

    /// Copies a file from one location to another
    /// 
    /// - Parameters:
    ///   - sourceURL: The URL of the source file
    ///   - destinationURL: The URL where the file should be copied
    /// 
    /// - Throws: `FileSystemError` if the copy operation fails
    func copyItem(at sourceURL: URL, to destinationURL: URL) throws
}

/// Request parameters for creating a download task
/// 
/// This struct encapsulates all the parameters needed to create a download task,
/// providing a clean interface that avoids function parameter count violations.
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
/// 
/// try await taskManager.createTask(request)
/// ```
public struct TaskRequest: Sendable {
    /// The URL of the M3U8 file to download
    public let url: URL
    
    /// Optional base URL for resolving relative URLs
    public let baseUrl: URL?
    
    /// Directory where the final video file will be saved
    public let savedDirectory: String
    
    /// Optional custom filename for the output video
    public let fileName: String?
    
    /// The download method (web or local)
    public let method: Method
    
    /// Whether to output detailed information during the download process
    public let verbose: Bool
    
    /// Initializes a new task request
    /// 
    /// - Parameters:
    ///   - url: The URL of the M3U8 file to download
    ///   - baseUrl: Optional base URL for resolving relative URLs
    ///   - savedDirectory: Directory where the final video file will be saved
    ///   - fileName: Optional custom filename for the output video
    ///   - method: The download method (web or local)
    ///   - verbose: Whether to output detailed information during the download process
    public init(
        url: URL,
        baseUrl: URL? = nil,
        savedDirectory: String,
        fileName: String? = nil,
        method: Method,
        verbose: Bool = false
    ) {
        self.url = url
        self.baseUrl = baseUrl
        self.savedDirectory = savedDirectory
        self.fileName = fileName
        self.method = method
        self.verbose = verbose
    }
}

/// Protocol for task management operations
/// 
/// This protocol defines the interface for managing download tasks, including
/// creating, monitoring, and cancelling tasks. It provides a high-level API
/// for coordinating complex download operations.
/// 
/// ## Usage Example
/// ```swift
/// class MyTaskManager: TaskManagerProtocol {
///     func createTask(_ request: TaskRequest) async throws {
///         // Implementation for creating and executing tasks
///     }
///     
///     func getTaskStatus(for taskId: String) async -> TaskStatus? {
///         // Implementation for getting task status
///     }
///     
///     func cancelTask(taskId: String) async throws {
///         // Implementation for cancelling tasks
///     }
/// }
/// ```
public protocol TaskManagerProtocol: Sendable {
    /// Creates and executes a download task
    /// 
    /// This method creates a new download task and executes it using the provided
    /// request parameters.
    /// 
    /// - Parameter request: The task request containing all necessary parameters
    /// 
    /// - Throws: Various errors depending on the failure scenario
    func createTask(_ request: TaskRequest) async throws
    
    /// Gets the current status of a task
    /// 
    /// - Parameter taskId: The unique identifier of the task
    /// 
    /// - Returns: The current status of the task, or `nil` if not found
    func getTaskStatus(for taskId: String) async -> TaskStatus?
    
    /// Cancels a running task
    /// 
    /// - Parameter taskId: The unique identifier of the task to cancel
    /// 
    /// - Throws: `ProcessingError` if the task is not found or cannot be cancelled
    func cancelTask(taskId: String) async throws
}

/// Protocol for external command execution
/// 
/// This protocol defines the interface for executing external shell commands,
/// typically used for running tools like FFmpeg for video processing.
/// 
/// ## Usage Example
/// ```swift
/// class MyCommandExecutor: CommandExecutorProtocol {
///     func execute(command: String, arguments: [String], workingDirectory: String?) async throws -> String {
///         let process = Process()
///         process.executableURL = URL(fileURLWithPath: command)
///         process.arguments = arguments
///         if let workingDirectory = workingDirectory {
///             process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
///         }
///         
///         let output = Pipe()
///         process.standardOutput = output
///         
///         try process.run()
///         process.waitUntilExit()
///         
///         let data = output.fileHandleForReading.readDataToEndOfFile()
///         return String(data: data, encoding: .utf8) ?? ""
///     }
/// }
/// ```
public protocol CommandExecutorProtocol: Sendable {
    /// Executes a shell command with arguments
    /// 
    /// This method executes an external command and returns its output as a string.
    /// 
    /// - Parameters:
    ///   - command: The command to execute (full path)
    ///   - arguments: Array of command-line arguments
    ///   - workingDirectory: Optional working directory for the command
    /// 
    /// - Returns: The command output as a string
    /// 
    /// - Throws: `CommandExecutionError` if the command fails to execute
    func execute(command: String, arguments: [String], workingDirectory: String?) async throws -> String
}
