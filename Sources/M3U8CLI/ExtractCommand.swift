//
//  ExtractCommand.swift
//  M3U8CLI
//
//  Created by tree_fly on 2025/1/27.
//

import ArgumentParser
import Foundation
import TFM3U8Utility
// Register site-specific extractors per-app (not in the library)

/// Command for extracting M3U8 links from web pages
/// 
/// This command demonstrates the use of the unified third-party interface
/// for extracting M3U8 links from various web pages and platforms.
/// 
/// ## Usage Examples
/// ```bash
/// # Extract M3U8 links from a web page
/// m3u8-utility extract "https://example.com/video-page"
/// 
/// # Extract with custom options
/// m3u8-utility extract "https://example.com/video-page" \
///   --timeout 60 \
///   --methods direct-links,javascript-variables \
///   --user-agent "Custom Agent" \
///   --verbose
/// 
/// # Extract and save to file
/// m3u8-utility extract "https://example.com/video-page" \
///   --output links.txt \
///   --format json
/// ```
struct ExtractCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "extract",
        abstract: "Extract M3U8 links from web pages using simplified methods",
        discussion: """
        This command extracts M3U8 playlist URLs from web pages using focused extraction methods.
        Optimized for simplicity and effectiveness, supporting direct M3U8 links and JavaScript variables.
        
        The command automatically selects the appropriate extractor based on the target URL domain.
        """,
        version: CLI.version
    )
    
    /// The URL of the web page to extract M3U8 links from
    @Argument(help: "URL of the web page to extract M3U8 links from")
    var url: String
    
    /// Network timeout in seconds
    @Option(name: .long, help: "Network timeout in seconds (default: 30)")
    var timeout: TimeInterval = 30.0
    
    /// Maximum number of retry attempts
    @Option(name: .long, help: "Maximum number of retry attempts (default: 3)")
    var maxRetries: Int = 3
    
    /// Extraction methods to use
    @Option(name: .long, help: "Extraction methods to use (comma-separated)")
    var methods: String = "direct-links,javascript-variables"
    
    /// Custom User-Agent string
    @Option(name: .long, help: "Custom User-Agent string")
    var userAgent: String?
    
    /// Whether to follow HTTP redirects
    @Flag(name: .long, inversion: .prefixedNo, help: "Follow HTTP redirects")
    var followRedirects: Bool = true
    
    /// Whether to execute JavaScript
    @Flag(name: .long, inversion: .prefixedNo, help: "Execute JavaScript for dynamic content")
    var executeJavaScript: Bool = true
    
    /// Output file path
    @Option(name: .long, help: "Output file path for extracted links")
    var output: String?
    
    /// Output format
    @Option(name: .long, help: "Output format (text, json, csv)")
    var format: OutputFormat = .text
    
    /// Whether to output verbose information
    @Flag(name: .long, help: "Output verbose information")
    var verbose: Bool = false
    
    /// Whether to show extractor information
    @Flag(name: .long, help: "Show registered extractor information")
    var showExtractors: Bool = false
    
    /// Runs the extract command
    func run() async throws {
        // Validate URL
        guard let targetURL = URL(string: url) else {
            throw ValidationError("Invalid URL: \(url)")
        }
        
        if verbose {
            print("🔍 Starting M3U8 link extraction...")
            print("📄 Target URL: \(targetURL)")
            print("⏱️  Timeout: \(timeout)s")
            print("🔄 Max retries: \(maxRetries)")
            print("🔧 Methods: \(methods)")
            print()
        }
        
        // Create extractor registry
        let registry = DefaultM3U8ExtractorRegistry()
        // Register CLI-provided extractors here (example: YouTube) with DI-friendly http client
        let httpClient = URLSessionHTTPClient()
        registry.registerExtractor(YouTubeExtractor(httpClient: httpClient))
        
        // Show extractor information if requested
        if showExtractors {
            print("📋 Registered Extractors:")
            let extractors = registry.getRegisteredExtractors()
            for extractor in extractors {
                print("  • \(extractor.name) v\(extractor.version)")
                print("    Domains: \(extractor.supportedDomains.joined(separator: ", "))")
                print("    Capabilities: \(extractor.capabilities.map { $0.description }.joined(separator: ", "))")
                print("    Status: \(extractor.isActive ? "Active" : "Inactive")")
                print()
            }
        }
        
        // Parse extraction methods
        let extractionMethods = parseExtractionMethods(methods)
        
        // Create extraction options
        let options = LinkExtractionOptions(
            timeout: timeout,
            maxRetries: maxRetries,
            extractionMethods: extractionMethods,
            userAgent: userAgent,
            followRedirects: followRedirects,
            customHeaders: [:],
            executeJavaScript: executeJavaScript
        )
        
        do {
            // Extract M3U8 links
            let startTime = Date()
            let links = try await registry.extractM3U8Links(from: targetURL, options: options)
            let extractionTime = Date().timeIntervalSince(startTime)
            
            // Display results
            displayResults(links, extractionTime: extractionTime)
            
            // Save to file if requested
            if let outputPath = output {
                try saveResults(links, to: outputPath, format: format)
            }
            
        } catch {
            print("❌ Extraction failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    /// Parses extraction methods from string
    private func parseExtractionMethods(_ methodsString: String) -> [ExtractionMethod] {
        let methodStrings = methodsString.split(separator: ",").map(String.init)
        var methods: [ExtractionMethod] = []
        
        for methodString in methodStrings {
            let trimmed = methodString.trimmingCharacters(in: .whitespaces)
            switch trimmed.lowercased() {
            case "direct-links":
                methods.append(.directLinks)
            case "javascript-variables":
                methods.append(.javascriptVariables)
            default:
                print("⚠️  Unknown extraction method: \(trimmed)")
            }
        }
        
        return methods.isEmpty ? [.directLinks, .javascriptVariables] : methods
    }
    
    /// Displays extraction results
    private func displayResults(_ links: [M3U8Link], extractionTime: TimeInterval) {
        print("✅ Extraction completed in \(String(format: "%.2f", extractionTime))s")
        print("🔗 Found \(links.count) M3U8 link(s):")
        print()
        
        for (index, link) in links.enumerated() {
            print("\(index + 1). \(link.url)")
            print("   Quality: \(link.quality ?? "Unknown")")
            print("   Bandwidth: \(link.bandwidth != nil ? "\(link.bandwidth!) bps" : "Unknown")")
            print("   Method: \(link.extractionMethod.description)")
            print("   Confidence: \(String(format: "%.1f", link.confidence * 100))%")
            
            if !link.metadata.isEmpty {
                print("   Metadata:")
                for (key, value) in link.metadata {
                    print("     \(key): \(value)")
                }
            }
            print()
        }
    }
    
    /// Saves results to file
    private func saveResults(_ links: [M3U8Link], to path: String, format: OutputFormat) throws {
        let outputURL = URL(fileURLWithPath: path)
        let outputData: Data
        
        switch format {
        case .text:
            outputData = createTextOutput(links)
        case .json:
            outputData = try createJSONOutput(links)
        case .csv:
            outputData = createCSVOutput(links)
        }
        
        try outputData.write(to: outputURL)
        print("💾 Results saved to: \(path)")
    }
    
    /// Creates text output
    private func createTextOutput(_ links: [M3U8Link]) -> Data {
        var output = "M3U8 Links Extracted\n"
        output += "====================\n\n"
        
        for (index, link) in links.enumerated() {
            output += "\(index + 1). \(link.url)\n"
            output += "   Quality: \(link.quality ?? "Unknown")\n"
            output += "   Method: \(link.extractionMethod.description)\n"
            output += "   Confidence: \(String(format: "%.1f", link.confidence * 100))%\n\n"
        }
        
        return output.data(using: .utf8) ?? Data()
    }
    
    /// Creates JSON output
    private func createJSONOutput(_ links: [M3U8Link]) throws -> Data {
        let linkData = links.map { link in
            [
                "url": link.url.absoluteString,
                "quality": link.quality ?? "",
                "bandwidth": link.bandwidth ?? 0,
                "method": link.extractionMethod.rawValue,
                "confidence": link.confidence,
                "metadata": link.metadata
            ] as [String: Any]
        }
        
        let output = [
            "extraction_time": Date().timeIntervalSince1970,
            "total_links": links.count,
            "links": linkData
        ] as [String: Any]
        
        return try JSONSerialization.data(withJSONObject: output, options: .prettyPrinted)
    }
    
    /// Creates CSV output
    private func createCSVOutput(_ links: [M3U8Link]) -> Data {
        var output = "URL,Quality,Bandwidth,Method,Confidence\n"
        
        for link in links {
            let quality = link.quality ?? ""
            let bandwidth = link.bandwidth?.description ?? ""
            let method = link.extractionMethod.description
            let confidence = String(format: "%.2f", link.confidence)
            
            output += "\(link.url),\(quality),\(bandwidth),\(method),\(confidence)\n"
        }
        
        return output.data(using: .utf8) ?? Data()
    }
}

/// Output format options
enum OutputFormat: String, CaseIterable, ExpressibleByArgument {
    case text
    case json
    case csv
    
    static var allValueStrings: [String] {
        return allCases.map { $0.rawValue }
    }
}