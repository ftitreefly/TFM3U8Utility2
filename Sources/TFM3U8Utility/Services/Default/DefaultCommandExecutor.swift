//
//  DefaultCommandExecutor.swift
//  TFM3U8Utility
//
//  Created by tree_fly on 2025/7/13.
//

import Foundation

// MARK: - Default Command Executor

/// Default implementation of command execution for external tools
/// 
/// This executor provides a robust implementation for running external commands
/// like FFmpeg and curl. It includes special handling for curl commands
/// using URLSession for better performance and error handling.
/// 
/// ## Features
/// - Process-based command execution with proper error handling
/// - Special URLSession-based curl implementation
/// - Thread-safe output collection
/// - Working directory support
/// - Comprehensive error reporting
/// 
/// ## Usage Example
/// ```swift
/// let executor = DefaultCommandExecutor()
/// 
/// // Execute FFmpeg command
/// let output = try await executor.execute(
///     command: "/usr/local/bin/ffmpeg",
///     arguments: ["-i", "input.mp4", "-c", "copy", "output.mp4"],
///     workingDirectory: "/path/to/working/dir"
/// )
/// 
/// // Execute curl command (uses URLSession internally)
/// let content = try await executor.execute(
///     command: "/usr/bin/curl",
///     arguments: ["-H", "Authorization: Bearer token", "https://api.example.com/data"],
///     workingDirectory: nil
/// )
/// ```
public struct DefaultCommandExecutor: CommandExecutorProtocol {
  
  /// Initializes a new command executor
  public init() {}
  
  /// Executes a shell command with arguments
  /// 
  /// This method executes external commands, with special handling for curl
  /// commands that use URLSession for better performance and reliability.
  /// 
  /// - Parameters:
  ///   - command: The full path to the executable
  ///   - arguments: Array of command-line arguments
  ///   - workingDirectory: Optional working directory for the command
  /// 
  /// - Returns: The command output as a string
  /// 
  /// - Throws: 
  ///   - `CommandExecutionError.processError` if the process fails
  ///   - `CommandExecutionError.httpError` for curl HTTP errors
  ///   - `CommandExecutionError.encodingError` if output cannot be decoded
  ///   - `CommandExecutionError.invalidURL` for invalid curl URLs
  /// 
  /// ## Usage Example
  /// ```swift
  /// let output = try await executor.execute(
  ///     command: "/usr/local/bin/ffmpeg",
  ///     arguments: ["-version"],
  ///     workingDirectory: nil
  /// )
  /// print("FFmpeg version: \(output)")
  /// ```
  public func execute(command: String, arguments: [String], workingDirectory: String?) async throws -> String {
    // If it's a curl command, use URLSession as alternative
    if command.contains("curl") {
      return try await executeCurlWithURLSession(arguments: arguments)
    }
    
    return try await executeWithProcess(command: command, arguments: arguments, workingDirectory: workingDirectory)
  }
  
  /// Executes a command using Process for non-curl commands
  /// 
  /// This method uses Foundation's `Process` to execute external commands
  /// with proper output capture and error reporting. Standard input is closed
  /// to prevent interactive blocking in test/CI environments.
  /// 
  /// - Parameters:
  ///   - command: The full path to the executable
  ///   - arguments: Array of command-line arguments
  ///   - workingDirectory: Optional working directory for the command
  /// 
  /// - Returns: The command output as a string
  /// 
  /// - Throws: `CommandExecutionError.processError` if the process fails
  private func executeWithProcess(command: String, arguments: [String], workingDirectory: String?) async throws -> String {
    return try await withCheckedThrowingContinuation { continuation in
      let process = Process()
      process.executableURL = URL(fileURLWithPath: command)
      process.arguments = arguments
      
      if let workingDir = workingDirectory {
        process.currentDirectoryURL = URL(fileURLWithPath: workingDir)
      }
      
      let outputPipe = Pipe()
      let errorPipe = Pipe()
      
      process.standardOutput = outputPipe
      process.standardError = errorPipe
      
      // Close standard input to prevent process from waiting for input
      process.standardInput = nil
      
      // To prevent deadlock, we need to read output in background
      let outputData = ThreadSafeData()
      let errorData = ThreadSafeData()
      
      outputPipe.fileHandleForReading.readabilityHandler = { handle in
        let data = handle.availableData
          if !data.isEmpty {
          outputData.append(data)
        }
      }
      
      errorPipe.fileHandleForReading.readabilityHandler = { handle in
        let data = handle.availableData
          if !data.isEmpty {
          errorData.append(data)
        }
      }
      
      process.terminationHandler = { process in
        // Close reading handlers
        outputPipe.fileHandleForReading.readabilityHandler = nil
        errorPipe.fileHandleForReading.readabilityHandler = nil
        
        // Read remaining data
        let remainingOutput = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let remainingError = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        outputData.append(remainingOutput)
        errorData.append(remainingError)
        
        let output = String(data: outputData.data, encoding: .utf8) ?? ""
        let error = String(data: errorData.data, encoding: .utf8) ?? ""
        
        if process.terminationStatus == 0 {
          continuation.resume(returning: output)
        } else {
          let errorMessage = error.isEmpty ? "Command failed with exit code \(process.terminationStatus)" : error
          continuation.resume(throwing: CommandExecutionError.processError(message: errorMessage, exitCode: process.terminationStatus))
        }
      }
      
      do {
        try process.run()
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }
  
  /// Executes curl commands using URLSession for better performance
  /// 
  /// This method parses curl arguments and uses `URLSession` for HTTP requests,
  /// providing better performance and error handling than shelling out to curl.
  /// Only a minimal subset of curl flags is supported here (e.g., -H for headers).
  /// 
  /// - Parameter arguments: Array of curl command-line arguments
  /// 
  /// - Returns: The HTTP response content as a string
  /// 
  /// - Throws: 
  ///   - `CommandExecutionError.invalidURL` if URL cannot be parsed
  ///   - `CommandExecutionError.httpError` for HTTP errors
  ///   - `CommandExecutionError.encodingError` if response cannot be decoded
  private func executeCurlWithURLSession(arguments: [String]) async throws -> String {
    // Parse curl arguments
    var url: URL?
    var headers: [String: String] = [:]
    
    // swiftlint:disable:next identifier_name
    var i = 0
    while i < arguments.count {
      let arg = arguments[i]
      
      if arg == "-H" && i + 1 < arguments.count {
        let header = arguments[i + 1]
        let components = header.split(separator: ":", maxSplits: 1).map(String.init)
        if components.count == 2 {
          headers[components[0].trimmingCharacters(in: .whitespaces)] = components[1].trimmingCharacters(in: .whitespaces)
        }
        i += 2
      } else if !arg.hasPrefix("-") {
        url = URL(string: arg)
        i += 1
      } else {
        i += 1
      }
    }
    
    guard let targetURL = url else {
      throw CommandExecutionError.invalidURL
    }
    
    var request = URLRequest(url: targetURL)
    request.timeoutInterval = 30.0
    
    // Add custom headers
    for (key, value) in headers {
      request.setValue(value, forHTTPHeaderField: key)
    }
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
      throw CommandExecutionError.httpError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
    }
    
    guard let content = String(data: data, encoding: .utf8) else {
      throw CommandExecutionError.encodingError
    }
    
    return content
  }
}

// MARK: - Default Network Client

public struct DefaultNetworkClient: NetworkClientProtocol {
    private let session: URLSession
    private let defaultHeaders: [String: String]
    private let retryAttempts: Int
    private let retryBackoffBase: TimeInterval
    
    public init(configuration: DIConfiguration) {
        let cfg = URLSessionConfiguration.default
        cfg.waitsForConnectivity = true
        cfg.httpMaximumConnectionsPerHost = max(6, configuration.maxConcurrentDownloads)
        cfg.timeoutIntervalForRequest = configuration.downloadTimeout
        cfg.timeoutIntervalForResource = configuration.resourceTimeout
        cfg.httpAdditionalHeaders = configuration.defaultHeaders
        cfg.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: cfg)
        self.defaultHeaders = configuration.defaultHeaders
        self.retryAttempts = configuration.retryAttempts
        self.retryBackoffBase = configuration.retryBackoffBase
    }
    
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        var req = request
        for (k, v) in defaultHeaders where req.value(forHTTPHeaderField: k) == nil {
            req.setValue(v, forHTTPHeaderField: k)
        }
        var lastError: Error?
        for attempt in 0...retryAttempts {
            do {
                return try await session.data(for: req)
            } catch {
                lastError = error
                if attempt < retryAttempts {
                    let delay = retryBackoffBase * pow(2, Double(attempt))
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
                throw error
            }
        }
        throw lastError ?? URLError(.unknown)
    }
}

// MARK: - Command Execution Errors

/// Errors that can occur during command execution
/// 
/// This enum defines specific error types for command execution failures,
/// providing detailed information about what went wrong.
enum CommandExecutionError: LocalizedError {
  /// The URL provided to curl command is invalid
  case invalidURL
  
  /// HTTP request failed with a non-200 status code
  case httpError(statusCode: Int)
  
  /// Failed to decode response data as UTF-8
  case encodingError
  
  /// Process execution failed with an exit code
  case processError(message: String, exitCode: Int32)
  
  /// Localized error description
  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid URL provided to curl command"
    case .httpError(let statusCode):
      return "HTTP error with status code: \(statusCode)"
    case .encodingError:
      return "Failed to encode response data as UTF-8"
    case .processError(let message, let exitCode):
      return "Process failed with exit code \(exitCode): \(message)"
    }
  }
}

// MARK: - Thread-Safe Data Helper

/// Thread-safe data container for collecting command output
/// 
/// This class provides thread-safe access to Data for collecting
/// command output from multiple threads.
private final class ThreadSafeData: @unchecked Sendable {
  /// The underlying data storage
  private var _data = Data()
  
  /// Lock for thread-safe access
  private let lock = NSLock()
  
  /// Thread-safe access to the collected data
  var data: Data {
    lock.withLock {
      return _data
    }
  }
  
  /// Thread-safe data appending
  /// 
  /// - Parameter newData: The data to append
  func append(_ newData: Data) {
    lock.withLock {
      _data.append(newData)
    }
  }
} 
