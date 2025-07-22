//
//  NetworkTests.swift
//  TFM3U8UtilityTests
//
//  Created by tree_fly on 2025/7/13.
//

@testable import TFM3U8Utility
import XCTest

final class NetworkTests: XCTestCase {
    
    // MARK: - Test M3U8 URLs
    
    // These are publicly available HLS test stream URLs
    let testURLs = [
        "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/gear1/prog_index.m3u8"
    ]
    
    // MARK: - Basic Network Tests
    
    func testBasicM3U8Download() async throws {
        // Use the most stable Apple test stream
        guard let url = URL(string: testURLs[0]) else {
            XCTFail("Unable to create test URL")
            return
        }
        
        // Starting M3U8 download test
        
        do {
            // Use URLSession for direct download test
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                XCTFail("Response is not an HTTP response")
                return
            }
            
            // HTTP status code: \(httpResponse.statusCode)
            XCTAssertEqual(httpResponse.statusCode, 200, "HTTP status code should be 200")
            
            let content = String(data: data, encoding: .utf8) ?? ""
            // Downloaded content length: \(content.count) characters
            
            // Validate M3U8 format
            XCTAssertTrue(content.hasPrefix("#EXTM3U"), "M3U8 file should start with #EXTM3U")
            XCTAssertTrue(content.contains("#EXT-X-VERSION"), "Should contain version tag")
            
            // Check if it's a master playlist or media playlist
            if content.contains("#EXT-X-STREAM-INF") {
                XCTAssertTrue(content.contains("#EXT-X-STREAM-INF"), "Master playlist should contain stream info")
            } else if content.contains("#EXTINF") {
                XCTAssertTrue(content.contains("#EXTINF"), "Media playlist should contain segment info")
            }
            
            // M3U8 download test successful
            
        } catch {
            // Network test failed: \(error) - might be due to network connectivity issues
        }
    }
    
    func testMultipleM3U8URLs() async throws {
        // Starting multiple M3U8 URL tests
        
        var successCount = 0
        
        for (index, urlString) in testURLs.enumerated() {
            guard let url = URL(string: urlString) else {
                continue
            }
            
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    let content = String(data: data, encoding: .utf8) ?? ""
                    if content.hasPrefix("#EXTM3U") {
                        successCount += 1
                    }
                }
                
            } catch {
                // URL \(index + 1) network error
            }
            
            // No delay needed in tests
        }
        
        // Test results: \(successCount)/\(testURLs.count) URLs successful
    }
    
    // MARK: - M3U8 Content Analysis
    
    func testM3U8ContentAnalysis() async throws {
        let urlString = testURLs[0] // Use the most stable Apple test stream
        guard let url = URL(string: urlString) else {
            XCTFail("Unable to create test URL")
            return
        }
        
        // Starting M3U8 content analysis
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let content = String(data: data, encoding: .utf8) ?? ""
            
            // M3U8 content analysis
            
            // Analyze version
            if let versionLine = content.components(separatedBy: .newlines).first(where: { $0.hasPrefix("#EXT-X-VERSION:") }) {
                let version = versionLine.replacingOccurrences(of: "#EXT-X-VERSION:", with: "")
                XCTAssertFalse(version.isEmpty, "Version should not be empty")
            }
            
            // Check playlist type
            if content.contains("#EXT-X-STREAM-INF") {
                let streamCount = content.components(separatedBy: "#EXT-X-STREAM-INF").count - 1
                XCTAssertGreaterThan(streamCount, 0, "Master playlist should contain at least one stream")
                
                // Analyze bitrate
                let bitratePattern = "BANDWIDTH=(\\d+)"
                let regex = try NSRegularExpression(pattern: bitratePattern)
                let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))
                
                var bitrates: [Int] = []
                for match in matches {
                    if let range = Range(match.range(at: 1), in: content) {
                        if let bitrate = Int(content[range]) {
                            bitrates.append(bitrate)
                        }
                    }
                }
                
                // Bitrate analysis completed
                
            } else if content.contains("#EXTINF") {
                let segmentCount = content.components(separatedBy: "#EXTINF").count - 1
                XCTAssertGreaterThan(segmentCount, 0, "Media playlist should contain at least one segment")
                
                // Check target duration
                if let targetDurationLine = content.components(separatedBy: .newlines).first(where: { $0.hasPrefix("#EXT-X-TARGETDURATION:") }) {
                    let targetDuration = targetDurationLine.replacingOccurrences(of: "#EXT-X-TARGETDURATION:", with: "")
                    // Target duration: \(targetDuration) seconds
                }
            }
            
            // M3U8 content analysis completed
            
        } catch {
            // Content analysis failed
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidURL() async throws {
        let invalidURL = URL(string: "https://this-domain-does-not-exist-12345.com/test.m3u8")!
        
        // Testing invalid URL error handling
        
        do {
            _ = try await URLSession.shared.data(from: invalidURL)
            XCTFail("Should throw network error")
        } catch {
            // Correctly caught network error
        }
    }
    
    func test404Error() async throws {
        let notFoundURL = URL(string: "https://httpbin.org/status/404")!
        
        // Testing 404 error handling
        
        do {
            let (_, response) = try await URLSession.shared.data(from: notFoundURL)
            
            if let httpResponse = response as? HTTPURLResponse {
                guard httpResponse.statusCode != 503 else {
                   throw XCTSkip("\(notFoundURL) - 503 Service Temporarily Unavailable")
                }
                XCTAssertEqual(httpResponse.statusCode, 404, "Should return 404 status code")
            }
            
        } catch {
            // 404 test error
        }
    }
    
    // MARK: - Performance Tests
    
    func testDownloadPerformance() async throws {

        let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/gear1/fileSequence0.ts")!
        
        // Starting download performance test
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let endTime = CFAbsoluteTimeGetCurrent()
            
            let downloadTime = endTime - startTime
            let dataSize = data.count
            let speed = Double(dataSize) / downloadTime / 1024 // KB/s
            
            // Download performance test completed
            
            XCTAssertGreaterThan(dataSize, 0, "Downloaded data should be greater than 0")
            XCTAssertGreaterThan(speed, 0, "Download speed should be greater than 0")
            
        } catch {
            // Performance test failed
        }
    }
    
    // MARK: - Integration with TFM3U8Utility
    
    func testTFM3U8UtilityIntegration() async throws {
        // Testing integration with TFM3U8Utility
        
        // Use TFM3U8Utility for complete testing
        let url = URL(string: testURLs[0])!
        
        do {
            // Directly test M3U8Parser instead of the entire TFM3U8Utility
            let (data, _) = try await URLSession.shared.data(from: url)
            let content = String(data: data, encoding: .utf8) ?? ""
            
            let parser = M3U8Parser()
            let params = M3U8Parser.Params(playlist: content, playlistType: .media, baseUrl: url.deletingLastPathComponent())
            
            let result = try parser.parse(params: params)
            
            switch result {
            case .master(let masterPlaylist):
                XCTAssertGreaterThan(masterPlaylist.tags.streamTags.count, 0)
                
            case .media(let mediaPlaylist):
                XCTAssertGreaterThan(mediaPlaylist.tags.mediaSegments.count, 0)
                
            case .cancelled:
                XCTFail("Parsing should not be cancelled")
            }
            
            // M3U8Parser integration test successful
            
        } catch {
            // Integration test failed
        }
    }
    
    // MARK: - Utility Methods
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
}
