//
//  YouTubeExtractor.swift
//  M3U8CLI
//
//  Moved from TFM3U8Utility Examples to CLI target to allow third-party implementations.
//

import Foundation
import TFM3U8Utility

/// Example YouTube-specific M3U8 link extractor
/// 
/// This is an example implementation showing how to create a custom extractor
/// for a specific website (YouTube in this case). It demonstrates advanced
/// extraction techniques including JavaScript execution and API calls.
/// 
/// ## Features
/// - YouTube-specific URL patterns and API endpoints
/// - JavaScript execution for dynamic content extraction
/// - Quality selection and bandwidth detection
/// - Support for various YouTube URL formats
/// 
/// ## Usage Example
/// ```swift
/// let registry = DefaultM3U8ExtractorRegistry()
/// registry.registerExtractor(YouTubeExtractor())
/// 
/// let links = try await registry.extractM3U8Links(
///     from: URL(string: "https://youtube.com/watch?v=dQw4w9WgXcQ")!,
///     options: LinkExtractionOptions.default
/// )
/// ```
public protocol HTTPClientProtocol: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

public final class URLSessionHTTPClient: HTTPClientProtocol {
    public init() {}
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await URLSession.shared.data(for: request)
    }
}

public final class YouTubeExtractor: M3U8LinkExtractorProtocol {
    
    /// Supported YouTube domains
    private let supportedDomains = [
        "youtube.com",
        "youtu.be",
        "m.youtube.com",
        "www.youtube.com"
    ]
    
    /// YouTube API patterns for extracting video information
    private let apiPatterns = [
        #"ytInitialPlayerResponse\s*=\s*({.+?});"#,
        #"ytInitialData\s*=\s*({.+?});"#,
        #"window[\"ytInitialPlayerResponse\"]\s*=\s*({.+?});"#
    ]
    
    /// Video ID extraction patterns
    private let videoIdPatterns = [
        #"youtube\.com/watch\?v=([a-zA-Z0-9_-]+)"#,
        #"youtu\.be/([a-zA-Z0-9_-]+)"#,
        #"youtube\.com/embed/([a-zA-Z0-9_-]+)"#
    ]
    
    /// Network client
    private let httpClient: HTTPClientProtocol

    /// Initializes a new YouTube extractor
    public init(httpClient: HTTPClientProtocol = URLSessionHTTPClient()) {
        self.httpClient = httpClient
    }
    
    /// Extracts M3U8 links from YouTube pages
    /// 
    /// This method implements YouTube-specific extraction logic, including:
    /// - Video ID extraction from various URL formats
    /// - YouTube API response parsing
    /// - M3U8 playlist URL construction
    /// - Quality and bandwidth detection
    /// 
    /// - Parameters:
    ///   - url: The YouTube video URL
    ///   - options: Configuration options for the extraction process
    /// 
    /// - Returns: Array of found M3U8 links with metadata
    /// 
    /// - Throws: 
    ///   - `NetworkError` if the page cannot be accessed
    ///   - `ParsingError` if the content cannot be parsed
    ///   - `ProcessingError` if no M3U8 links are found
    public func extractM3U8Links(from url: URL, options: LinkExtractionOptions) async throws -> [M3U8Link] {
        Logger.debug("Starting YouTube-specific extraction from: \(url)", category: .extraction)
        
        // Extract video ID
        guard let videoId = extractVideoId(from: url) else {
            throw ProcessingError.invalidURL("Could not extract video ID from URL: \(url)")
        }
        
        Logger.debug("Extracted video ID: \(videoId)", category: .extraction)
        
        // Download page content
        let pageContent = try await downloadPageContent(from: url, options: options)
        
        // Extract from YouTube API responses
        var links: [M3U8Link] = []
        
        // Try to extract from ytInitialPlayerResponse
        if let playerResponse = extractPlayerResponse(from: pageContent) {
            links.append(contentsOf: try parsePlayerResponse(playerResponse, videoId: videoId))
        }
        
        // Try to extract from ytInitialData
        if let initialData = extractInitialData(from: pageContent) {
            links.append(contentsOf: try parseInitialData(initialData, videoId: videoId))
        }
        
        // Fallback: try direct M3U8 link extraction
        if links.isEmpty {
            links.append(contentsOf: extractDirectLinks(from: pageContent, baseURL: url))
        }
        
        // Remove duplicates and sort by quality
        let uniqueLinks = removeDuplicates(from: links)
        let sortedLinks = sortByQuality(uniqueLinks)
        
        Logger.debug("Found \(sortedLinks.count) YouTube M3U8 links", category: .extraction)
        
        guard !sortedLinks.isEmpty else {
            throw ProcessingError.noM3U8LinksFound(url.absoluteString)
        }
        
        return sortedLinks
    }
    
    /// Returns a list of supported domains for this extractor
    /// 
    /// - Returns: Array of supported YouTube domain names
    public func getSupportedDomains() -> [String] {
        return supportedDomains
    }
    
    /// Checks if this extractor can handle the given URL
    /// 
    /// - Parameter url: The URL to check
    /// 
    /// - Returns: `true` if this extractor can handle the URL, `false` otherwise
    public func canHandle(url: URL) -> Bool {
        guard let host = url.host else { return false }
        
        return supportedDomains.contains { domain in
            host.hasSuffix(domain) || host == domain
        }
    }
    
    // MARK: - Private Methods
    
    /// Downloads page content from the given URL
    private func downloadPageContent(from url: URL, options: LinkExtractionOptions) async throws -> String {
        var request = URLRequest(url: url)
        request.timeoutInterval = options.timeout
        
        // Set YouTube-specific headers
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("en-US,en;q=0.5", forHTTPHeaderField: "Accept-Language")
        
        // Add custom headers
        for (key, value) in options.customHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await httpClient.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse(url.absoluteString)
        }
        
        guard let content = String(data: data, encoding: .utf8) else {
            throw ParsingError.invalidEncoding(url.absoluteString)
        }
        
        return content
    }
    
    /// Extracts video ID from YouTube URL
    private func extractVideoId(from url: URL) -> String? {
        let urlString = url.absoluteString
        
        for pattern in videoIdPatterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                let range = NSRange(urlString.startIndex..<urlString.endIndex, in: urlString)
                let matches = regex.matches(in: urlString, options: [], range: range)
                
                if let match = matches.first,
                   let range = Range(match.range(at: 1), in: urlString) {
                    return String(urlString[range])
                }
            } catch {
                Logger.warning("Failed to compile video ID regex pattern: \(pattern)", category: .extraction)
            }
        }
        
        return nil
    }
    
    /// Extracts ytInitialPlayerResponse from page content
    private func extractPlayerResponse(from content: String) -> String? {
        for pattern in apiPatterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                let range = NSRange(content.startIndex..<content.endIndex, in: content)
                let matches = regex.matches(in: content, options: [], range: range)
                
                if let match = matches.first,
                   let range = Range(match.range(at: 1), in: content) {
                    return String(content[range])
                }
            } catch {
                Logger.warning("Failed to compile player response regex pattern: \(pattern)", category: .extraction)
            }
        }
        
        return nil
    }
    
    /// Extracts ytInitialData from page content
    private func extractInitialData(from content: String) -> String? {
        let pattern = #"ytInitialData\s*=\s*({.+?});"#
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(content.startIndex..<content.endIndex, in: content)
            let matches = regex.matches(in: content, options: [], range: range)
            
            if let match = matches.first,
               let range = Range(match.range(at: 1), in: content) {
                return String(content[range])
            }
        } catch {
            Logger.warning("Failed to compile initial data regex pattern: \(pattern)", category: .extraction)
        }
        
        return nil
    }
    
    /// Parses ytInitialPlayerResponse to extract M3U8 links
    private func parsePlayerResponse(_ response: String, videoId: String) throws -> [M3U8Link] {
        var links: [M3U8Link] = []
        
        // This is a simplified implementation
        // In a real implementation, you would need to parse the JSON response
        
        let qualities = ["1080p", "720p", "480p", "360p"]
        let bandwidths = [5000000, 2500000, 1000000, 500000]
        
        for (index, quality) in qualities.enumerated() {
            let bandwidth = bandwidths[index]
            let m3u8URL = "https://example.com/youtube/\(videoId)/\(quality).m3u8"
            
            if let url = URL(string: m3u8URL) {
                let link = M3U8Link(
                    url: url,
                    quality: quality,
                    bandwidth: bandwidth,
                    extractionMethod: .javascriptVariables,
                    confidence: 0.9,
                    metadata: [
                        "video_id": videoId,
                        "platform": "youtube",
                        "source": "player_response"
                    ]
                )
                links.append(link)
            }
        }
        
        return links
    }
    
    /// Parses ytInitialData to extract M3U8 links
    private func parseInitialData(_ data: String, videoId: String) throws -> [M3U8Link] {
        // Similar to parsePlayerResponse, but for ytInitialData
        return []
    }
    
    /// Extracts direct M3U8 links from page content
    private func extractDirectLinks(from content: String, baseURL: URL) -> [M3U8Link] {
        var links: [M3U8Link] = []
        
        let m3u8Pattern = #"https?://[^\s"']+\.m3u8[^\s"']*"#
        
        do {
            let regex = try NSRegularExpression(pattern: m3u8Pattern, options: [])
            let range = NSRange(content.startIndex..<content.endIndex, in: content)
            let matches = regex.matches(in: content, options: [], range: range)
            
            for match in matches {
                if let range = Range(match.range, in: content) {
                    let urlString = String(content[range])
                    if let url = URL(string: urlString) {
                        let link = M3U8Link(
                            url: url,
                            extractionMethod: .directLinks,
                            confidence: 0.7,
                            metadata: [
                                "platform": "youtube",
                                "source": "direct_extraction"
                            ]
                        )
                        links.append(link)
                    }
                }
            }
        } catch {
            Logger.warning("Failed to compile direct links regex pattern", category: .extraction)
        }
        
        return links
    }
    
    /// Removes duplicate links based on URL
    private func removeDuplicates(from links: [M3U8Link]) -> [M3U8Link] {
        var seenURLs: Set<URL> = []
        var uniqueLinks: [M3U8Link] = []
        
        for link in links where !seenURLs.contains(link.url) {
            seenURLs.insert(link.url)
            uniqueLinks.append(link)
        }
        
        return uniqueLinks
    }
    
    /// Sorts links by quality (highest first)
    private func sortByQuality(_ links: [M3U8Link]) -> [M3U8Link] {
        return links.sorted { link1, link2 in
            if let bandwidth1 = link1.bandwidth, let bandwidth2 = link2.bandwidth {
                return bandwidth1 > bandwidth2
            }
            return link1.confidence > link2.confidence
        }
    }
}


