//
//  NetworkError.swift
//  TFM3U8Utility
//
//  Created by tree_fly on 2025/7/13.
//

import Foundation

// MARK: - Network Error

/// Network and download related errors
public struct NetworkError: TFM3U8Error {
    public let domain = "TFM3U8Utility.Network"
    public let code: Int
    public let underlyingError: Error?
    public let message: String
    public let url: URL?
    
    public var recoverySuggestion: String? {
        switch code {
        case 1001: return "Check your internet connection and try again."
        case 1002: return "Verify the URL is correct and accessible."
        case 1003: return "The server may be temporarily unavailable. Try again later."
        default: return "Check network settings and retry the operation."
        }
    }
    
    public var userInfo: [String: Any] {
        var info: [String: Any] = ["message": message]
        if let url = url { info["url"] = url.absoluteString }
        if let underlying = underlyingError { info["underlyingError"] = underlying }
        return info
    }
    
    public var errorDescription: String? {
        return message
    }
    
    public var failureReason: String? {
        return underlyingError?.localizedDescription
    }
    
    // Common network errors
    public static func connectionFailed(_ url: URL, underlying: Error) -> NetworkError {
        NetworkError(
            code: 1001,
            underlyingError: underlying,
            message: "Failed to connect to \(url.host ?? "server")",
            url: url
        )
    }
    
    public static func invalidURL(_ urlString: String) -> NetworkError {
        NetworkError(
            code: 1002,
            underlyingError: nil,
            message: "Invalid URL: \(urlString)",
            url: nil
        )
    }
    
    public static func serverError(_ url: URL, statusCode: Int) -> NetworkError {
        NetworkError(
            code: 1003,
            underlyingError: nil,
            message: "Server error \(statusCode) for \(url.absoluteString)",
            url: url
        )
    }
    
    public static func invalidResponse(_ url: String) -> NetworkError {
        NetworkError(
            code: 1004,
            underlyingError: nil,
            message: "Invalid response from \(url)",
            url: URL(string: url)
        )
    }
} 
