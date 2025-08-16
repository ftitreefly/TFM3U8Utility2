# Third-Party Integration Guide

This document describes how to use the unified third-party interface for extracting M3U8 links from web pages. This interface provides a standardized way for third-party tools to extract streaming links from various websites and platforms.

## Overview

The TFM3U8Utility2 project provides a comprehensive protocol-based system for extracting M3U8 links from web pages. The system is designed to be:

- **Extensible**: Easy to add support for new websites and platforms
- **Unified**: Consistent interface across different extractors
- **Robust**: Multiple extraction methods with fallback strategies
- **Configurable**: Flexible options for different use cases

## Core Components

### 1. M3U8LinkExtractorProtocol

The main protocol that defines the interface for extracting M3U8 links from web pages.

```swift
public protocol M3U8LinkExtractorProtocol: Sendable {
    func extractM3U8Links(from url: URL, options: LinkExtractionOptions) async throws -> [M3U8Link]
    func getSupportedDomains() -> [String]
    func canHandle(url: URL) -> Bool
}
```

### 2. M3U8ExtractorRegistryProtocol

A registry protocol for managing multiple extractors and routing requests to the appropriate one.

```swift
public protocol M3U8ExtractorRegistryProtocol: Sendable {
    func registerExtractor(_ extractor: M3U8LinkExtractorProtocol)
    func extractM3U8Links(from url: URL, options: LinkExtractionOptions) async throws -> [M3U8Link]
    func getRegisteredExtractors() -> [ExtractorInfo]
}
```

### 3. Supporting Types

- `LinkExtractionOptions`: Configuration options for extraction
- `M3U8Link`: Represents an extracted M3U8 link with metadata
- `ExtractionMethod`: Different methods for extracting links
- `ExtractorInfo`: Information about registered extractors

## Basic Usage

### 1. Using the Default Extractor

The simplest way to extract M3U8 links is to use the default extractor:

```swift
import TFM3U8Utility

// Create a default extractor
let extractor = DefaultM3U8LinkExtractor()

// Configure extraction options
let options = LinkExtractionOptions(
    timeout: 30.0,
    maxRetries: 3,
    extractionMethods: [.directLinks, .javascriptVariables, .apiEndpoints],
    userAgent: "Custom User Agent",
    followRedirects: true,
    customHeaders: [:],
    executeJavaScript: true
)

// Extract M3U8 links
let url = URL(string: "https://example.com/video-page")!
let links = try await extractor.extractM3U8Links(from: url, options: options)

// Process the results
for link in links {
    print("Found M3U8: \(link.url)")
    print("Quality: \(link.quality ?? "Unknown")")
    print("Confidence: \(link.confidence)")
}
```

### 2. Using the Extractor Registry

For more advanced usage with multiple extractors:

```swift
// Create a registry
let registry = DefaultM3U8ExtractorRegistry()

// Register custom extractors
registry.registerExtractor(YouTubeExtractor())
registry.registerExtractor(VimeoExtractor())

// Extract links (automatically routes to appropriate extractor)
let links = try await registry.extractM3U8Links(
    from: URL(string: "https://youtube.com/watch?v=123")!,
    options: LinkExtractionOptions.default
)
```

### 3. CLI Usage

The project includes a CLI command for extracting M3U8 links:

```bash
# Basic extraction
m3u8-utility extract "https://example.com/video-page"

# With custom options
m3u8-utility extract "https://example.com/video-page" \
  --timeout 60 \
  --methods direct-links,javascript-variables \
  --user-agent "Custom Agent" \
  --verbose

# Save results to file
m3u8-utility extract "https://example.com/video-page" \
  --output links.txt \
  --format json
```

## Creating Custom Extractors

### 1. Basic Custom Extractor

To create a custom extractor for a specific website:

```swift
public class MyCustomExtractor: M3U8LinkExtractorProtocol {
    
    private let supportedDomains = ["mysite.com", "www.mysite.com"]
    
    public init() {}
    
    public func extractM3U8Links(from url: URL, options: LinkExtractionOptions) async throws -> [M3U8Link] {
        // Download page content
        let content = try await downloadPageContent(from: url, options: options)
        
        // Extract M3U8 links using your custom logic
        var links: [M3U8Link] = []
        
        // Example: Extract from JavaScript variables
        let jsPattern = #"['"`](https?://[^'`"]+\.m3u8[^'`"]*)['"`]"#
        let regex = try NSRegularExpression(pattern: jsPattern, options: [])
        let range = NSRange(content.startIndex..<content.endIndex, in: content)
        let matches = regex.matches(in: content, options: [], range: range)
        
        for match in matches {
            if let range = Range(match.range(at: 1), in: content) {
                let urlString = String(content[range])
                if let url = URL(string: urlString) {
                    let link = M3U8Link(
                        url: url,
                        quality: "1080p",
                        bandwidth: 5000000,
                        extractionMethod: .javascriptVariables,
                        confidence: 0.9,
                        metadata: ["platform": "mysite"]
                    )
                    links.append(link)
                }
            }
        }
        
        return links
    }
    
    public func getSupportedDomains() -> [String] {
        return supportedDomains
    }
    
    public func canHandle(url: URL) -> Bool {
        guard let host = url.host else { return false }
        return supportedDomains.contains { domain in
            host.hasSuffix(domain) || host == domain
        }
    }
    
    private func downloadPageContent(from url: URL, options: LinkExtractionOptions) async throws -> String {
        var request = URLRequest(url: url)
        request.timeoutInterval = options.timeout
        
        // Set custom headers
        for (key, value) in options.customHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse(url.absoluteString)
        }
        
        guard let content = String(data: data, encoding: .utf8) else {
            throw ParsingError.invalidEncoding(url.absoluteString)
        }
        
        return content
    }
}
```

### 2. Advanced Custom Extractor

For more complex websites that require JavaScript execution or API calls:

```swift
public class AdvancedExtractor: M3U8LinkExtractorProtocol {
    
    private let supportedDomains = ["complex-site.com"]
    private let apiEndpoint = "https://api.complex-site.com/video"
    
    public func extractM3U8Links(from url: URL, options: LinkExtractionOptions) async throws -> [M3U8Link] {
        // Extract video ID from URL
        let videoId = extractVideoId(from: url)
        
        // Make API call to get video information
        let apiResponse = try await makeAPIRequest(videoId: videoId, options: options)
        
        // Parse API response for M3U8 links
        let links = try parseAPIResponse(apiResponse, videoId: videoId)
        
        return links
    }
    
    private func makeAPIRequest(videoId: String, options: LinkExtractionOptions) async throws -> Data {
        var request = URLRequest(url: URL(string: "\(apiEndpoint)/\(videoId)")!)
        request.timeoutInterval = options.timeout
        
        // Add authentication headers
        request.setValue("Bearer token", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse(request.url?.absoluteString ?? "")
        }
        
        return data
    }
    
    private func parseAPIResponse(_ data: Data, videoId: String) throws -> [M3U8Link] {
        // Parse JSON response and extract M3U8 links
        // This is a simplified example
        return []
    }
    
    // ... other required methods
}
```

## Extraction Methods

The system supports multiple extraction methods:

### 1. Direct Links
Searches for direct M3U8 links in the page source.

### 2. JavaScript Variables
Extracts M3U8 URLs from JavaScript variables and objects.

### 3. API Endpoints
Discovers and calls API endpoints that return M3U8 playlists.

### 4. Video Elements
Parses HTML video elements for M3U8 sources.

### 5. Structured Data
Extracts from JSON-LD structured data.

### 6. Regular Expressions
Uses custom regex patterns for pattern matching.

## Configuration Options

### LinkExtractionOptions

```swift
let options = LinkExtractionOptions(
    timeout: 30.0,                    // Network timeout
    maxRetries: 3,                    // Retry attempts
    extractionMethods: [.directLinks, .javascriptVariables], // Methods to use
    userAgent: "Custom Agent",        // Custom User-Agent
    followRedirects: true,            // Follow HTTP redirects
    customHeaders: [:],               // Custom HTTP headers
    executeJavaScript: true           // Execute JavaScript
)
```

## Error Handling

The system provides comprehensive error handling:

```swift
do {
    let links = try await extractor.extractM3U8Links(from: url, options: options)
    // Process links
} catch NetworkError.invalidResponse(let url) {
    print("Network error for URL: \(url)")
} catch ParsingError.invalidEncoding(let url) {
    print("Parsing error for URL: \(url)")
} catch ProcessingError.noM3U8LinksFound(let url) {
    print("No M3U8 links found for URL: \(url)")
} catch {
    print("Unexpected error: \(error)")
}
```

## Best Practices

### 1. Domain-Specific Extractors
Create specialized extractors for websites with unique structures:

```swift
// Register domain-specific extractors
registry.registerExtractor(YouTubeExtractor())
registry.registerExtractor(VimeoExtractor())
registry.registerExtractor(TwitchExtractor())
```

### 2. Fallback Strategies
Implement multiple extraction methods with fallbacks:

```swift
public func extractM3U8Links(from url: URL, options: LinkExtractionOptions) async throws -> [M3U8Link] {
    var links: [M3U8Link] = []
    
    // Try primary method
    if options.extractionMethods.contains(.javascriptVariables) {
        links.append(contentsOf: extractFromJavaScript(from: content, baseURL: url))
    }
    
    // Fallback to direct links
    if links.isEmpty && options.extractionMethods.contains(.directLinks) {
        links.append(contentsOf: extractDirectLinks(from: content, baseURL: url))
    }
    
    return links
}
```

### 3. Quality Detection
Extract and provide quality information when available:

```swift
let link = M3U8Link(
    url: url,
    quality: "1080p",
    bandwidth: 5000000,
    extractionMethod: .javascriptVariables,
    confidence: 0.9,
    metadata: [
        "resolution": "1920x1080",
        "codec": "h264",
        "fps": "30"
    ]
)
```

### 4. Error Recovery
Implement robust error handling and recovery:

```swift
public func extractM3U8Links(from url: URL, options: LinkExtractionOptions) async throws -> [M3U8Link] {
    for attempt in 1...options.maxRetries {
        do {
            return try await performExtraction(from: url, options: options)
        } catch {
            if attempt == options.maxRetries {
                throw error
            }
            // Wait before retry
            try await Task.sleep(nanoseconds: UInt64(attempt * 1000) * 1_000_000)
        }
    }
    
    throw ProcessingError.maxRetriesExceeded
}
```

## Integration Examples

### 1. Integration with Download Manager

```swift
class DownloadManager {
    private let extractorRegistry: M3U8ExtractorRegistryProtocol
    
    init(extractorRegistry: M3U8ExtractorRegistryProtocol) {
        self.extractorRegistry = extractorRegistry
    }
    
    func downloadFromWebPage(_ url: URL) async throws {
        // Extract M3U8 links
        let links = try await extractorRegistry.extractM3U8Links(
            from: url,
            options: LinkExtractionOptions.default
        )
        
        // Select best quality link
        guard let bestLink = links.max(by: { $0.bandwidth ?? 0 < $1.bandwidth ?? 0 }) else {
            throw ProcessingError.noM3U8LinksFound(url.absoluteString)
        }
        
        // Download the M3U8 playlist
        try await downloadM3U8Playlist(bestLink.url)
    }
}
```

### 2. Integration with Web Scraper

```swift
class WebScraper {
    private let extractorRegistry: M3U8ExtractorRegistryProtocol
    
    func scrapeVideoLinks(from urls: [URL]) async throws -> [M3U8Link] {
        var allLinks: [M3U8Link] = []
        
        for url in urls {
            do {
                let links = try await extractorRegistry.extractM3U8Links(
                    from: url,
                    options: LinkExtractionOptions.default
                )
                allLinks.append(contentsOf: links)
            } catch {
                print("Failed to extract from \(url): \(error)")
            }
        }
        
        return allLinks
    }
}
```

## Testing

### 1. Unit Testing

```swift
class ExtractorTests: XCTestCase {
    func testYouTubeExtractor() async throws {
        let extractor = YouTubeExtractor()
        let url = URL(string: "https://youtube.com/watch?v=dQw4w9WgXcQ")!
        
        let links = try await extractor.extractM3U8Links(
            from: url,
            options: LinkExtractionOptions.default
        )
        
        XCTAssertFalse(links.isEmpty)
        XCTAssertTrue(links.allSatisfy { $0.url.absoluteString.contains(".m3u8") })
    }
}
```

### 2. Integration Testing

```swift
class RegistryTests: XCTestCase {
    func testExtractorRegistry() async throws {
        let registry = DefaultM3U8ExtractorRegistry()
        registry.registerExtractor(YouTubeExtractor())
        
        let links = try await registry.extractM3U8Links(
            from: URL(string: "https://youtube.com/watch?v=123")!,
            options: LinkExtractionOptions.default
        )
        
        XCTAssertFalse(links.isEmpty)
    }
}
```

## Conclusion

The unified third-party interface provides a powerful and flexible way to extract M3U8 links from web pages. By following the protocols and best practices outlined in this guide, you can create robust extractors that work seamlessly with the TFM3U8Utility2 system.

The system is designed to be extensible, so you can easily add support for new websites and platforms by implementing the `M3U8LinkExtractorProtocol`. The registry system ensures that requests are automatically routed to the appropriate extractor based on the target URL domain.

For more information, see the API reference documentation and the example implementations in the source code. 