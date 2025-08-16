//
//  DefaultM3U8ExtractorRegistry.swift
//  TFM3U8Utility
//
//  Created by tree_fly on 2025/1/27.
//

import Foundation

/// Default implementation of M3U8 extractor registry
/// 
/// This class manages multiple M3U8 link extractors and routes requests
/// to the appropriate extractor based on the target URL domain.
/// 
/// ## Features
/// - Automatic extractor registration and management
/// - Domain-based routing to appropriate extractors
/// - Fallback to default extractor when no specific extractor is found
/// - Support for multiple extractors per domain
/// - Extractor information and status tracking
/// 
/// ## Usage Example
/// ```swift
/// let registry = DefaultM3U8ExtractorRegistry()
/// 
/// // Register specific extractors
/// registry.registerExtractor(YouTubeExtractor())
/// registry.registerExtractor(VimeoExtractor())
/// 
/// // Extract links (automatically routes to appropriate extractor)
/// let links = try await registry.extractM3U8Links(
///     from: URL(string: "https://youtube.com/watch?v=123")!,
///     options: LinkExtractionOptions.default
/// )
/// ```
public final class DefaultM3U8ExtractorRegistry: M3U8ExtractorRegistryProtocol, @unchecked Sendable {
    
    /// Registered extractors with their domain mappings
    private var extractors: [String: M3U8LinkExtractorProtocol] = [:]
    
    /// Default extractor for fallback
    private let defaultExtractor: M3U8LinkExtractorProtocol
    
    /// Extractor metadata for tracking
    private var extractorMetadata: [String: ExtractorInfo] = [:]
    
    /// Initializes a new extractor registry
    /// 
    /// - Parameter defaultExtractor: Default extractor to use when no specific extractor is found
    public init(defaultExtractor: M3U8LinkExtractorProtocol = DefaultM3U8LinkExtractor()) {
        self.defaultExtractor = defaultExtractor
        
        // Register the default extractor
        registerDefaultExtractor()
    }
    
    /// Registers a new link extractor
    /// 
    /// This method registers an extractor and maps it to its supported domains.
    /// If multiple extractors support the same domain, the last registered one
    /// will be used for that domain.
    /// 
    /// - Parameter extractor: The extractor to register
    public func registerExtractor(_ extractor: M3U8LinkExtractorProtocol) {
        let domains = extractor.getSupportedDomains()
        
        // If no specific domains are provided, register as a general extractor
        if domains.isEmpty {
            extractors["*"] = extractor
            extractorMetadata["*"] = ExtractorInfo(
                name: String(describing: type(of: extractor)),
                version: "1.0.0",
                supportedDomains: ["*"],
                capabilities: [.directLinks, .javascriptVariables, .apiEndpoints]
            )
        } else {
            // Register for each supported domain
            for domain in domains {
                extractors[domain] = extractor
                extractorMetadata[domain] = ExtractorInfo(
                    name: String(describing: type(of: extractor)),
                    version: "1.0.0",
                    supportedDomains: [domain],
                    capabilities: [.directLinks, .javascriptVariables, .apiEndpoints]
                )
            }
        }
        
        Logger.debug("Registered extractor: \(String(describing: type(of: extractor))) for domains: \(domains.isEmpty ? ["*"] : domains)", category: .extraction)
    }
    
    /// Extracts M3U8 links using the appropriate registered extractor
    /// 
    /// This method automatically selects the appropriate extractor based on
    /// the URL domain and delegates the extraction to it. If no specific
    /// extractor is found, it falls back to the default extractor.
    /// 
    /// - Parameters:
    ///   - url: The URL of the web page to analyze
    ///   - options: Configuration options for the extraction process
    /// 
    /// - Returns: Array of found M3U8 links with metadata
    /// 
    /// - Throws: 
    ///   - `ProcessingError` if no suitable extractor is found
    ///   - Various errors from the selected extractor
    public func extractM3U8Links(from url: URL, options: LinkExtractionOptions) async throws -> [M3U8Link] {
        guard let host = url.host else {
            throw ProcessingError.invalidURL(url.absoluteString)
        }
        
        // Find the appropriate extractor
        let extractor = findExtractor(for: host)
        
        Logger.debug("Using extractor: \(String(describing: type(of: extractor))) for host: \(host)", category: .extraction)
        
        // Extract links using the selected extractor
        return try await extractor.extractM3U8Links(from: url, options: options)
    }
    
    /// Gets a list of all registered extractors
    /// 
    /// This method returns information about all registered extractors,
    /// useful for debugging and monitoring purposes.
    /// 
    /// - Returns: Array of extractor information
    public func getRegisteredExtractors() -> [ExtractorInfo] {
        return Array(extractorMetadata.values)
    }
    
    // MARK: - Private Methods
    
    /// Registers the default extractor
    private func registerDefaultExtractor() {
        extractors["*"] = defaultExtractor
        extractorMetadata["*"] = ExtractorInfo(
            name: "Default M3U8 Extractor",
            version: "1.0.0",
            supportedDomains: ["*"],
            capabilities: [.directLinks, .javascriptVariables, .apiEndpoints, .videoElements, .structuredData, .regexPatterns]
        )
    }
    
    /// Finds the appropriate extractor for a given host
    /// 
    /// This method searches for an extractor that can handle the given host.
    /// It first looks for exact domain matches, then for partial matches,
    /// and finally falls back to the default extractor.
    /// 
    /// - Parameter host: The host to find an extractor for
    /// 
    /// - Returns: The appropriate extractor
    private func findExtractor(for host: String) -> M3U8LinkExtractorProtocol {
        // First, try exact domain match
        if let extractor = extractors[host] {
            return extractor
        }
        
        // Then, try partial domain matches
        for (domain, extractor) in extractors {
            if domain != "*" && host.hasSuffix(domain) {
                return extractor
            }
        }
        
        // Finally, fall back to default extractor
        return defaultExtractor
    }
}

// MARK: - Convenience Extensions

extension DefaultM3U8ExtractorRegistry {
    
    /// Registers multiple extractors at once
    /// 
    /// This convenience method allows registering multiple extractors
    /// in a single call.
    /// 
    /// - Parameter extractors: Array of extractors to register
    public func registerExtractors(_ extractors: [M3U8LinkExtractorProtocol]) {
        for extractor in extractors {
            registerExtractor(extractor)
        }
    }
    
    /// Unregisters an extractor for a specific domain
    /// 
    /// This method removes an extractor from the registry for the specified domain.
    /// 
    /// - Parameter domain: The domain to unregister the extractor from
    public func unregisterExtractor(for domain: String) {
        extractors.removeValue(forKey: domain)
        extractorMetadata.removeValue(forKey: domain)
        
        Logger.debug("Unregistered extractor for domain: \(domain)", category: .extraction)
    }
    
    /// Checks if an extractor is registered for a domain
    /// 
    /// - Parameter domain: The domain to check
    /// 
    /// - Returns: `true` if an extractor is registered for the domain, `false` otherwise
    public func hasExtractor(for domain: String) -> Bool {
        return extractors[domain] != nil
    }
    
    /// Gets the extractor for a specific domain
    /// 
    /// - Parameter domain: The domain to get the extractor for
    /// 
    /// - Returns: The extractor for the domain, or `nil` if not found
    public func getExtractor(for domain: String) -> M3U8LinkExtractorProtocol? {
        return extractors[domain]
    }
}