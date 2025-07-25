//
//  ParsingError.swift
//  TFM3U8Utility
//
//  Created by tree_fly on 2025/7/13.
//

import Foundation

// MARK: - Parsing Error

/// Parsing related errors
public struct ParsingError: TFM3U8Error {
    public let domain = "TFM3U8Utility.Parsing"
    public let code: Int
    public let underlyingError: Error?
    public let message: String
    public let context: String?
    
    public var recoverySuggestion: String? {
        switch code {
        case 2001: return "Ensure the M3U8 file is properly formatted and contains required tags."
        case 2002: return "Check if the file is corrupted or incomplete."
        case 2003: return "Verify the tag format matches M3U8 specifications."
        default: return "Validate the M3U8 file format and content."
        }
    }
    
    public var userInfo: [String: Any] {
        var info: [String: Any] = ["message": message]
        if let context = context { info["context"] = context }
        if let underlying = underlyingError { info["underlyingError"] = underlying }
        return info
    }
    
    public var errorDescription: String? {
        return message
    }
    
    public var failureReason: String? {
        return context ?? underlyingError?.localizedDescription
    }
    
    // Common parsing errors
    public static func malformedPlaylist(_ reason: String) -> ParsingError {
        ParsingError(
            code: 2001,
            underlyingError: nil,
            message: "Malformed M3U8 playlist",
            context: reason
        )
    }
    
    public static func invalidTag(_ tag: String, expected: String, received: String) -> ParsingError {
        ParsingError(
            code: 2003,
            underlyingError: nil,
            message: "Invalid tag format: \(tag)",
            context: "Expected: \(expected), Received: \(received)"
        )
    }
    
    public static func missingRequiredTag(_ tag: String) -> ParsingError {
        ParsingError(
            code: 2001,
            underlyingError: nil,
            message: "Missing required tag: \(tag)",
            context: nil
        )
    }
} 
