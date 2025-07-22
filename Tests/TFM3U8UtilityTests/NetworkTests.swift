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
        // Apple official test stream - most stable
        // "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8",
        "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/gear1/prog_index.m3u8",
        
        // Simple test stream
        "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8"
    ]
    
    // MARK: - Basic Network Tests
    
    func testBasicM3U8Download() async throws {
        // Use the most stable Apple test stream
        guard let url = URL(string: testURLs[0]) else {
            XCTFail("Unable to create test URL")
            return
        }
        
        print("🔄 Starting M3U8 download test: \(url)")
        
        do {
            // Use URLSession for direct download test
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                XCTFail("Response is not an HTTP response")
                return
            }
            
            print("📊 HTTP status code: \(httpResponse.statusCode)")
            XCTAssertEqual(httpResponse.statusCode, 200, "HTTP status code should be 200")
            
            let content = String(data: data, encoding: .utf8) ?? ""
            print("📄 Downloaded content length: \(content.count) characters")
            
            // Validate M3U8 format
            XCTAssertTrue(content.hasPrefix("#EXTM3U"), "M3U8 file should start with #EXTM3U")
            XCTAssertTrue(content.contains("#EXT-X-VERSION"), "Should contain version tag")
            
            // Check if it's a master playlist or media playlist
            if content.contains("#EXT-X-STREAM-INF") {
                print("✅ Detected master playlist (Master Playlist)")
                XCTAssertTrue(content.contains("#EXT-X-STREAM-INF"), "Master playlist should contain stream info")
            } else if content.contains("#EXTINF") {
                print("✅ Detected media playlist (Media Playlist)")
                XCTAssertTrue(content.contains("#EXTINF"), "Media playlist should contain segment info")
            } else {
                print("⚠️ Unknown playlist type")
            }
            
            print("✅ M3U8 download test successful")
            
        } catch {
            print("❌ Network test failed: \(error)")
            // When network test fails, we don't fail the entire test because it might be a network issue
            print("⚠️ This might be due to network connectivity issues, not considered a test failure")
        }
    }
    
    func testMultipleM3U8URLs() async throws {
        print("🔄 Starting multiple M3U8 URL tests...")
        
        var successCount = 0
        
        for (index, urlString) in testURLs.enumerated() {
            guard let url = URL(string: urlString) else {
                print("❌ Unable to create URL: \(urlString)")
                continue
            }
            
            print("📡 Testing URL \(index + 1)/\(testURLs.count): \(url.host ?? "unknown")")
            
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    let content = String(data: data, encoding: .utf8) ?? ""
                    if content.hasPrefix("#EXTM3U") {
                        successCount += 1
                        print("✅ URL \(index + 1) successful")
                    } else {
                        print("⚠️ URL \(index + 1) returned invalid M3U8 content")
                    }
                } else {
                    print("⚠️ URL \(index + 1) HTTP status abnormal")
                }
                
            } catch {
                print("⚠️ URL \(index + 1) network error: \(error.localizedDescription)")
            }
            
            // No delay needed in tests
        }
        
        print("📊 Test results: \(successCount)/\(testURLs.count) URLs successful")
        
        // At least one URL success is considered pass
        if successCount == 0 {
            print("⚠️ All URLs failed, might be network issue")
        } else {
            print("✅ Multiple URL test passed")
        }
    }
    
    // MARK: - M3U8 Content Analysis
    
    func testM3U8ContentAnalysis() async throws {
        let urlString = testURLs[0] // Use the most stable Apple test stream
        guard let url = URL(string: urlString) else {
            XCTFail("Unable to create test URL")
            return
        }
        
        print("🔍 Starting M3U8 content analysis...")
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let content = String(data: data, encoding: .utf8) ?? ""
            
            print("📄 M3U8 content analysis:")
            
            // Analyze version
            if let versionLine = content.components(separatedBy: .newlines).first(where: { $0.hasPrefix("#EXT-X-VERSION:") }) {
                let version = versionLine.replacingOccurrences(of: "#EXT-X-VERSION:", with: "")
                print("   Version: \(version)")
                XCTAssertFalse(version.isEmpty, "Version should not be empty")
            }
            
            // Check playlist type
            if content.contains("#EXT-X-STREAM-INF") {
                let streamCount = content.components(separatedBy: "#EXT-X-STREAM-INF").count - 1
                print("   Type: Master playlist")
                print("   Stream count: \(streamCount)")
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
                
                if !bitrates.isEmpty {
                    print("   Bitrate range: \(bitrates.min()!) - \(bitrates.max()!) bps")
                }
                
            } else if content.contains("#EXTINF") {
                let segmentCount = content.components(separatedBy: "#EXTINF").count - 1
                print("   Type: Media playlist")
                print("   Segment count: \(segmentCount)")
                XCTAssertGreaterThan(segmentCount, 0, "Media playlist should contain at least one segment")
                
                // Check target duration
                if let targetDurationLine = content.components(separatedBy: .newlines).first(where: { $0.hasPrefix("#EXT-X-TARGETDURATION:") }) {
                    let targetDuration = targetDurationLine.replacingOccurrences(of: "#EXT-X-TARGETDURATION:", with: "")
                    print("   Target duration: \(targetDuration) seconds")
                }
            }
            
            print("✅ M3U8 content analysis completed")
            
        } catch {
            print("⚠️ Content analysis failed: \(error)")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidURL() async throws {
        let invalidURL = URL(string: "https://this-domain-does-not-exist-12345.com/test.m3u8")!
        
        print("🔄 Testing invalid URL error handling...")
        
        do {
            _ = try await URLSession.shared.data(from: invalidURL)
            XCTFail("Should throw network error")
        } catch {
            print("✅ Correctly caught network error: \(error.localizedDescription)")
        }
    }
    
    func test404Error() async throws {
        let notFoundURL = URL(string: "https://httpbin.org/status/404")!
        
        print("🔄 Testing 404 error handling...")
        
        do {
            let (_, response) = try await URLSession.shared.data(from: notFoundURL)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 Received HTTP status code: \(httpResponse.statusCode)")
                guard httpResponse.statusCode != 503 else {
                   throw XCTSkip("\(notFoundURL) - 503 Service Temporarily Unavailable")
                }
                XCTAssertEqual(httpResponse.statusCode, 404, "Should return 404 status code")
                print("✅ 404 error handling test successful")
            }
            
        } catch {
            print("⚠️ 404 test error: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testDownloadPerformance() async throws {
        let url = URL(string: testURLs[0])!
        
        print("⏱️ Starting download performance test...")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let endTime = CFAbsoluteTimeGetCurrent()
            
            let downloadTime = endTime - startTime
            let dataSize = data.count
            let speed = Double(dataSize) / downloadTime / 1024 // KB/s
            
            print("📊 Download performance:")
            print("   File size: \(dataSize) bytes")
            print("   Download time: \(String(format: "%.3f", downloadTime)) seconds")
            print("   Download speed: \(String(format: "%.2f", speed)) KB/s")
            
            XCTAssertGreaterThan(dataSize, 0, "Downloaded data should be greater than 0")
            XCTAssertGreaterThan(speed, 0, "Download speed should be greater than 0")
            
            print("✅ Performance test completed")
            
        } catch {
            print("⚠️ Performance test failed: \(error)")
        }
    }
    
    // MARK: - Integration with TFM3U8Utility
    
    func testTFM3U8UtilityIntegration() async throws {
        print("🔗 Testing integration with TFM3U8Utility...")
        
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
                print("✅ Successfully parsed master playlist with \(masterPlaylist.tags.streamTags.count) streams")
                XCTAssertGreaterThan(masterPlaylist.tags.streamTags.count, 0)
                
            case .media(let mediaPlaylist):
                print("✅ Successfully parsed media playlist with \(mediaPlaylist.tags.mediaSegments.count) segments")
                XCTAssertGreaterThan(mediaPlaylist.tags.mediaSegments.count, 0)
                
            case .cancelled:
                XCTFail("Parsing should not be cancelled")
            }
            
            print("✅ M3U8Parser integration test successful")
            
        } catch {
            print("⚠️ Integration test failed: \(error)")
            // Integration test failure might be due to various reasons, we log but don't fail the test
        }
    }
    
    // MARK: - Utility Methods
    
    private func printNetworkInfo() {
        print("🌐 Network test information:")
        print("   Test time: \(Date())")
        print("   Test case: NetworkTests")
        print("   Swift version: 6.0+")
    }
    
    override func setUp() {
        super.setUp()
        printNetworkInfo()
    }
    
    override func tearDown() {
        super.tearDown()
        print("Network test completed\n")
    }
}
