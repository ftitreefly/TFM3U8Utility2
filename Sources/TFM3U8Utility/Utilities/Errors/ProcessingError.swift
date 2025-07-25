//
//  ProcessingError.swift
//  TFM3U8Utility
//
//  Created by tree_fly on 2025/7/13.
//

import Foundation

// MARK: - Processing Error

/// Download and processing related errors
public struct ProcessingError: TFM3U8Error {
    public let domain = "TFM3U8Utility.Processing"
    public let code: Int
    public let underlyingError: Error?
    public let message: String
    public let operation: String?
    
    public var recoverySuggestion: String? {
        switch code {
        case 4001: return "Check if required tools are installed and accessible in PATH."
        case 4002: return "Verify FFmpeg is installed and supports the required codecs."
        case 4003: return "Ensure the source files are not corrupted."
        case 4004: return "Check if the process was interrupted and retry."
        default: return "Verify external tools are installed and retry the operation."
        }
    }
    
    public var userInfo: [String: Any] {
        var info: [String: Any] = ["message": message]
        if let operation = operation { info["operation"] = operation }
        if let underlying = underlyingError { info["underlyingError"] = underlying }
        return info
    }
    
    public var errorDescription: String? {
        return message
    }
    
    public var failureReason: String? {
        return underlyingError?.localizedDescription
    }
    
    // Common processing errors
    public static func toolNotFound(_ tool: String) -> ProcessingError {
        ProcessingError(
            code: 4001,
            underlyingError: nil,
            message: "Required tool not found: \(tool)",
            operation: "tool check"
        )
    }
    
    public static func conversionFailed(_ reason: String) -> ProcessingError {
        ProcessingError(
            code: 4002,
            underlyingError: nil,
            message: "Video conversion failed",
            operation: reason
        )
    }
    
    public static func corruptedSource(_ path: String) -> ProcessingError {
        ProcessingError(
            code: 4003,
            underlyingError: nil,
            message: "Source file is corrupted: \(path)",
            operation: "validation"
        )
    }
    
    public static func operationCancelled(_ operation: String) -> ProcessingError {
        ProcessingError(
            code: 4004,
            underlyingError: nil,
            message: "Operation was cancelled",
            operation: operation
        )
    }

    public static func masterPlaylistsNotSupported() -> ProcessingError {
        ProcessingError(
            code: 4005,
            underlyingError: nil,
            message: "Master playlists not supported yet",
            operation: "download"
        )
    }

    public static func emptyContent() -> ProcessingError {
        ProcessingError(
            code: 4007,
            underlyingError: nil,
            message: "Downloaded content is empty",
            operation: "download"
        )
    }

    public static func noValidSegments() -> ProcessingError {
        ProcessingError(
            code: 4008,
            underlyingError: nil,
            message: "No valid segments found",
            operation: "segment extraction"
        )
    }

    public static func ffmpegNotFound() -> ProcessingError {
        ProcessingError(
            code: 4009,
            underlyingError: nil,
            message: "FFmpeg command not found",
            operation: "decrypt"
        )
    }

    public static func taskNotFound(_ taskId: String) -> ProcessingError {
        ProcessingError(
            code: 4010,
            underlyingError: nil,
            message: "Task not found: \(taskId)",
            operation: "cancel"
        )
    }

    public init(code: Int, underlyingError: Error?, message: String, operation: String?) {
        self.code = code
        self.underlyingError = underlyingError
        self.message = message
        self.operation = operation
    }
}
