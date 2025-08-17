//
//  Logger.swift
//  TFM3U8Utility
//
//  Created by tree_fly on 2025/7/16.
//

import Foundation

// MARK: - Log Level

/// Represents different levels of logging detail
/// 
/// This enum defines the various logging levels available in the system,
/// allowing for fine-grained control over what information is displayed.
public enum LogLevel: Int, CaseIterable, Comparable, Sendable {
    /// No logging output
    case none = 0
    
    /// Only critical errors and warnings
    case error = 1
    
    /// Important information and errors
    case info = 2
    
    /// Detailed debugging information
    case debug = 3
    
    /// Very detailed debugging information
    case verbose = 4
    
    /// All possible information including trace data
    case trace = 5
    
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Log Category

/// Categories for organizing log messages
/// 
/// This enum helps categorize log messages for better organization
/// and filtering capabilities.
public enum LogCategory: String, CaseIterable, Sendable {
    case general = "General"
    case network = "Network"
    case fileSystem = "FileSystem"
    case parsing = "Parsing"
    case processing = "Processing"
    case taskManager = "TaskManager"
    case download = "Download"
    case cli = "CLI"
    case extraction = "Extraction"
    
    var emoji: String {
        switch self {
        case .general: return "📋"
        case .network: return "🌐"
        case .fileSystem: return "📁"
        case .parsing: return "📝"
        case .processing: return "⚙️"
        case .taskManager: return "🎯"
        case .download: return "⬇️"
        case .cli: return "💻"
        case .extraction: return "🔗"
        }
    }
}

// MARK: - Logger Configuration

/// Configuration for the logging system
/// 
/// This struct contains all the configuration options for the logging system,
/// allowing for fine-grained control over logging behavior.
public struct LoggerConfiguration: Sendable {
    /// The minimum log level to display
    public let minimumLevel: LogLevel
    
    /// Whether to include timestamps in log messages
    public let includeTimestamps: Bool
    
    /// Whether to include category information in log messages
    public let includeCategories: Bool
    
    /// Whether to include emoji in log messages
    public let includeEmoji: Bool
    
    /// Whether to enable colored output (if supported)
    public let enableColors: Bool
    
    /// Initializes a new logger configuration
    /// 
    /// - Parameters:
    ///   - minimumLevel: The minimum log level to display (defaults to .info)
    ///   - includeTimestamps: Whether to include timestamps (defaults to true)
    ///   - includeCategories: Whether to include categories (defaults to true)
    ///   - includeEmoji: Whether to include emoji (defaults to true)
    ///   - enableColors: Whether to enable colored output (defaults to true)
    public init(
        minimumLevel: LogLevel = .info,
        includeTimestamps: Bool = true,
        includeCategories: Bool = true,
        includeEmoji: Bool = true,
        enableColors: Bool = true
    ) {
        self.minimumLevel = minimumLevel
        self.includeTimestamps = includeTimestamps
        self.includeCategories = includeCategories
        self.includeEmoji = includeEmoji
        self.enableColors = enableColors
    }
    
    /// Creates a configuration suitable for production use
    public static func production() -> LoggerConfiguration {
        return LoggerConfiguration(
            minimumLevel: .error,
            includeTimestamps: false,
            includeCategories: true,
            includeEmoji: false,
            enableColors: false
        )
    }
    
    /// Creates a configuration suitable for development use
    public static func development() -> LoggerConfiguration {
        return LoggerConfiguration(
            minimumLevel: .debug,
            includeTimestamps: true,
            includeCategories: true,
            includeEmoji: true,
            enableColors: true
        )
    }
    
    /// Creates a configuration suitable for verbose debugging
    public static func verbose() -> LoggerConfiguration {
        return LoggerConfiguration(
            minimumLevel: .trace,
            includeTimestamps: false,
            includeCategories: true,
            includeEmoji: true,
            enableColors: true
        )
    }
}

// MARK: - Logger

/// A comprehensive logging system for TFM3U8Utility
/// 
/// This class provides a unified logging interface that can be configured
/// to display different levels of detail based on the current needs.
/// It supports multiple log levels, categories, timestamps, and colored output.
/// 
/// ## Features
/// - Multiple log levels (none, error, info, debug, verbose, trace)
/// - Categorized logging for better organization
/// - Configurable output formatting
/// - Thread-safe logging operations
/// - Support for custom output streams
/// - Colored output support
/// 
/// ## Usage Example
/// ```swift
/// // Configure logger
/// Logger.configure(.development())
/// 
/// // Log messages
/// Logger.info("Application started", category: .general)
/// Logger.debug("Downloading file", category: .download)
/// Logger.error("Network error", category: .network)
/// 
/// // Conditional logging
/// Logger.verbose("Detailed debug info", category: .parsing)
/// ```
public actor Logger {
    // Instance state (actor-isolated)
    /// Current logger configuration. Actor-isolated for concurrency safety.
    private var configuration: LoggerConfiguration = .development()
    /// Whether the logger has been explicitly configured. Defaults to false.
    private var isConfigured = false

    // Singleton actor instance to back static API
    /// Singleton backing instance for the static API.
    private static let shared = Logger()

    // MARK: - Public Static API (kept for source compatibility)

    /// Configure the logger with a specific configuration.
    ///
    /// - Parameter config: Configuration used by the logger.
    ///
    /// This schedules the configuration inside the actor to avoid race conditions.
    public static func configure(_ config: LoggerConfiguration) {
        Task { await shared.configureInstance(config) }
    }

    /// Log a message at the error level
    ///
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: Category of the log message (default: `.general`)
    ///   - file: Source file (auto captured)
    ///   - function: Source function (auto captured)
    ///   - line: Source line number (auto captured)
    public static func error(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        Task { await shared.log(.error, message: message, category: category, file: file, function: function, line: line) }
    }

    /// Log a message at the info level
    ///
    /// - Parameters are the same as `error`.
    public static func info(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        Task { await shared.log(.info, message: message, category: category, file: file, function: function, line: line) }
    }

    /// Log a message at the debug level
    ///
    /// - Parameters are the same as `error`.
    public static func debug(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        Task { await shared.log(.debug, message: message, category: category, file: file, function: function, line: line) }
    }

    /// Log a message at the verbose level
    ///
    /// - Parameters are the same as `error`.
    public static func verbose(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        Task { await shared.log(.verbose, message: message, category: category, file: file, function: function, line: line) }
    }

    /// Log a message at the trace level
    ///
    /// - Parameters are the same as `error`.
    public static func trace(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        Task { await shared.log(.trace, message: message, category: category, file: file, function: function, line: line) }
    }

    /// Log a success message (info level with success emoji formatting)
    ///
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: Category of the log message (default: `.general`)
    public static func success(
        _ message: String,
        category: LogCategory = .general
    ) {
        Task { await shared.log(.info, message: "✅ \(message)", category: category) }
    }

    /// Log a warning message (info level with warning emoji formatting)
    ///
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: Category of the log message (default: `.general`)
    public static func warning(
        _ message: String,
        category: LogCategory = .general
    ) {
        Task { await shared.log(.info, message: "⚠️  \(message)", category: category) }
    }

    /// Log a progress message (info level with progress emoji formatting)
    ///
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: Category of the log message (default: `.general`)
    public static func progress(
        _ message: String,
        category: LogCategory = .general
    ) {
        Task { await shared.log(.info, message: "📊 \(message)", category: category) }
    }

    /// Legacy compatibility method (vprintf-like)
    ///
    /// When `verbose` is true, logs at the verbose level; otherwise produces no output.
    /// - Parameters:
    ///   - verbose: Whether to log the message
    ///   - message: The message to log
    ///   - category: Category of the log message (default: `.general`)
    public static func vprintf(
        _ verbose: Bool,
        _ message: String,
        category: LogCategory = .general
    ) {
        guard verbose else { return }
        Task { await shared.log(.verbose, message: message, category: category) }
    }

    // MARK: - Actor-isolated instance methods

    /// Configure logger instance inside actor isolation.
    /// - Parameter config: Logger configuration.
    private func configureInstance(_ config: LoggerConfiguration) {
        configuration = config
        isConfigured = true
    }

    /// Internal logging method that handles the actual log output
    /// - Parameters:
    ///   - level: The log level
    ///   - message: The message to log
    ///   - category: The category of the log message (default: `.general`)
    ///   - file: The source file (auto captured)
    ///   - function: The source function (auto captured)
    ///   - line: The source line number (auto captured)
    private func log(
        _ level: LogLevel,
        message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard isConfigured && level <= configuration.minimumLevel else { return }
        let formattedMessage = formatMessage(
            level: level,
            message: message,
            category: category,
            fileAndLine: "\(file):\(line)",
            function: function
        )
        print(formattedMessage)
    }

    /// Format a log message according to the current configuration
    /// - Parameters:
    ///   - level: The log level
    ///   - message: The message to log
    ///   - category: The category of the log message
    ///   - fileAndLine: The source file and line number
    ///   - function: The source function
    /// - Returns: The formatted log message
    private func formatMessage(
        level: LogLevel,
        message: String,
        category: LogCategory,
        fileAndLine: String,
        function: String
    ) -> String {
        var components: [String] = []

        if configuration.includeTimestamps {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            components.append(formatter.string(from: Date()))
        }

        let levelIndicator = levelIndicator(for: level)
        components.append(levelIndicator)

        if configuration.includeCategories {
            let categoryText = configuration.includeEmoji ?
                "\(category.emoji)\(category.rawValue)" :
                category.rawValue
            components.append("[\(categoryText)]")
        }

        components.append(message)

        if level >= .debug && configuration.minimumLevel >= .debug {
            components.append("(\(fileAndLine))")
        }

        return components.joined(separator: " ")
    }

    /// Get the level indicator label for a given log level
    /// - Parameter level: The log level
    /// - Returns: A colored or plain indicator string depending on configuration
    private func levelIndicator(for level: LogLevel) -> String {
        let baseIndicator: String
        switch level {
        case .none: baseIndicator = "NONE"
        case .error: baseIndicator = "ERROR"
        case .info: baseIndicator = "INFO"
        case .debug: baseIndicator = "DEBUG"
        case .verbose: baseIndicator = "VERBOSE"
        case .trace: baseIndicator = "TRACE"
        }

        if configuration.enableColors {
            return colorize(baseIndicator, for: level)
        } else {
            return "[\(baseIndicator)]"
        }
    }

    /// Add ANSI color to a level label
    /// - Parameters:
    ///   - string: The label to colorize
    ///   - level: The log level
    /// - Returns: Colorized label wrapped by ANSI escape codes
    private func colorize(_ string: String, for level: LogLevel) -> String {
        let colorCode: String
        switch level {
        case .none: colorCode = "0"
        case .error: colorCode = "31"
        case .info: colorCode = "32"
        case .debug: colorCode = "34"
        case .verbose: colorCode = "35"
        case .trace: colorCode = "36"
        }
        return "\u{001B}[\(colorCode)m[\(string)]\u{001B}[0m"
    }

    // Logs once with a temporary configuration without mutating global state
    /// Log once with a temporary configuration without persisting any changes.
    /// - Parameters:
    ///   - tempConfig: Temporary configuration used only for this call
    ///   - level: Log level
    ///   - message: Log message
    ///   - category: Log category
    private func logTemporarily(
        with tempConfig: LoggerConfiguration,
        level: LogLevel,
        message: String,
        category: LogCategory
    ) {
        let original = configuration
        configuration = tempConfig
        log(level, message: message, category: category)
        configuration = original
    }
}

// MARK: - Logger Extensions

public extension Logger {
    /// Convenience method for logging with a specific configuration
    /// 
    /// This method allows logging with a temporary configuration override
    /// without changing the global configuration.
    /// 
    /// - Parameters:
    ///   - level: The log level
    ///   - message: The message to log
    ///   - category: The category of the log message
    ///   - config: The configuration to use for this log
    static func log(
        _ level: LogLevel,
        _ message: String,
        category: LogCategory = .general,
        with config: LoggerConfiguration
    ) {
        Task {
            await shared.logTemporarily(with: config, level: level, message: message, category: category)
        }
    }
} 
