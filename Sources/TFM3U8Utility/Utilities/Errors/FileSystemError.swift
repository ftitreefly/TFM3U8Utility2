//
//  FileSystemError.swift
//  TFM3U8Utility
//
//  Created by tree_fly on 2025/7/13.
//

import Foundation

// MARK: - File System Error

/// File system and I/O related errors
public struct FileSystemError: TFM3U8Error {
    public let domain = "TFM3U8Utility.FileSystem"
    public let code: Int
    public let underlyingError: Error?
    public let message: String
    public let path: String?
    
    public var recoverySuggestion: String? {
        switch code {
        case 3001: return "Check if the file exists and you have read permissions."
        case 3002: return "Ensure you have write permissions to the destination directory."
        case 3003: return "Verify there's enough disk space available."
        case 3004: return "Check if the directory exists and is accessible."
        default: return "Verify file permissions and disk space."
        }
    }
    
    public var userInfo: [String: Any] {
        var info: [String: Any] = ["message": message]
        if let path = path { info["path"] = path }
        if let underlying = underlyingError { info["underlyingError"] = underlying }
        return info
    }
    
    public var errorDescription: String? {
        return message
    }
    
    public var failureReason: String? {
        return underlyingError?.localizedDescription
    }
    
    // Common file system errors
    public static func fileNotFound(_ path: String) -> FileSystemError {
        FileSystemError(
            code: 3001,
            underlyingError: nil,
            message: "File not found",
            path: path
        )
    }
    
    public static func writePermissionDenied(_ path: String) -> FileSystemError {
        FileSystemError(
            code: 3002,
            underlyingError: nil,
            message: "Write permission denied",
            path: path
        )
    }
    
    public static func insufficientSpace(_ path: String) -> FileSystemError {
        FileSystemError(
            code: 3003,
            underlyingError: nil,
            message: "Insufficient disk space",
            path: path
        )
    }
    
    // failed to create directory
    public static func failedToCreateDirectory(_ path: String) -> FileSystemError {
        FileSystemError(
            code: 3004,
            underlyingError: nil,
            message: "Failed to create directory",
            path: path
        )
    }
    
    // failed to create file
    public static func failedToCreateFile(_ path: String) -> FileSystemError {   
        FileSystemError(
            code: 3005,
            underlyingError: nil,
            message: "Failed to create file",
            path: path
        )
    }
    
    // failed to write to file
    public static func failedToWriteToFile(_ path: String) -> FileSystemError {
        FileSystemError(
            code: 3006,
            underlyingError: nil,
            message: "Failed to write to file",
            path: path
        )
    }
    
    // failed to read from file
    public static func failedToReadFromFile(_ path: String) -> FileSystemError {
        FileSystemError(
            code: 3007,
            underlyingError: nil,
            message: "Failed to read from file",
            path: path
        )
    }
    
    // failed to delete file
    public static func failedToDeleteFile(_ path: String) -> FileSystemError {
        FileSystemError(
            code: 3008,
            underlyingError: nil,
            message: "Failed to delete file",
            path: path
        )
    }
    
    // failed to move file
    public static func failedToMoveFile(_ path: String) -> FileSystemError {
        FileSystemError(
            code: 3009,
            underlyingError: nil,
            message: "Failed to move file",
            path: path
        )
    }
    
    // failed to copy file
    public static func failedToCopyFile(_ path: String) -> FileSystemError {
        FileSystemError(
            code: 3010,
            underlyingError: nil,
            message: "Failed to copy file",
            path: path
        )
    }
}
