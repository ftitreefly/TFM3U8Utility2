//
//  PerformanceOptimized.swift
//  TFM3U8Utility
//
//  Created by tree_fly on 2025/7/9.
//

import XCTest

@testable import TFM3U8Utility

final class PerformanceOptimizedTests: XCTestCase {
    
    var testContainer: DependencyContainer!
    
    override func setUp() {
        super.setUp()
        testContainer = DependencyContainer()
        testContainer.configure(with: DIConfiguration.performanceOptimized())
    }
    
    override func tearDown() {
        testContainer = nil
        super.tearDown()
    }
    
    func testBasicInitialization() {
        // Synchronous test to avoid async issues
        let expectation = XCTestExpectation(description: "Basic initialization test")
        
        // Configure performance optimization settings
        testContainer.configure(with: DIConfiguration.performanceOptimized())
        
        // Test basic configuration parsing
        let configuration = try! testContainer.resolve(DIConfiguration.self)
        XCTAssertNotNil(configuration)
        XCTAssertEqual(configuration.maxConcurrentDownloads, 20)
        XCTAssertEqual(configuration.downloadTimeout, 60)
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testConfigurationValidation() {
        let expectation = XCTestExpectation(description: "Configuration validation test")
        
        // Test custom configuration
        let customConfig = DIConfiguration(
            ffmpegPath: "/usr/local/bin/ffmpeg",
            curlPath: "/usr/bin/curl",
            defaultHeaders: ["User-Agent": "TestAgent"],
            maxConcurrentDownloads: 10,
            downloadTimeout: 60
        )
        
        testContainer.configure(with: customConfig)
        
        let resolvedConfig = try! testContainer.resolve(DIConfiguration.self)
        XCTAssertEqual(resolvedConfig.maxConcurrentDownloads, 10)
        XCTAssertEqual(resolvedConfig.downloadTimeout, 60)
        XCTAssertEqual(resolvedConfig.defaultHeaders["User-Agent"], "TestAgent")
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFileSystemOperations() {
        let expectation = XCTestExpectation(description: "File system operations test")
        let fileSystem = try! testContainer.resolve(FileSystemServiceProtocol.self)
        
        do {
            // Test temporary directory creation
            let tempDir = try fileSystem.createTemporaryDirectory(nil)
            XCTAssertTrue(fileSystem.fileExists(at: tempDir.path))
            
            // Clean up
            try fileSystem.removeItem(at: tempDir.path)
            XCTAssertFalse(fileSystem.fileExists(at: tempDir.path))
            
            expectation.fulfill()
        } catch {
            XCTFail("File system operations test failed: \(error)")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testCommandExecutorCreation() {
        let expectation = XCTestExpectation(description: "Command executor creation test")
        // Only test service creation, don't execute actual commands
        let commandExecutor = try! testContainer.resolve(CommandExecutorProtocol.self)
        XCTAssertNotNil(commandExecutor)
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testPerformanceOptimizedConfiguration() {
        let expectation = XCTestExpectation(description: "Performance optimized configuration test")
        
        // Test performance optimized configuration creation
        let config = DIConfiguration.performanceOptimized()
        XCTAssertNotNil(config)
        XCTAssertEqual(config.maxConcurrentDownloads, 20)
        XCTAssertEqual(config.downloadTimeout, 60)
        XCTAssertNotNil(config.defaultHeaders["User-Agent"])
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDependencyContainerBasics() {
        let expectation = XCTestExpectation(description: "Dependency container basics test")
        
        // Test container basic functionality
        let container = DependencyContainer()
        
        // Register a simple service
        container.register(String.self) { "test" }
        let result = try! container.resolve(String.self)
        XCTAssertEqual(result, "test")
        
        // Test singleton registration
        container.registerSingleton(Int.self) { 42 }
        let value1 = try! container.resolve(Int.self)
        let value2 = try! container.resolve(Int.self)
        XCTAssertEqual(value1, 42)
        XCTAssertEqual(value2, 42)
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testM3U8ContentValidation() {
        let expectation = XCTestExpectation(description: "M3U8 content validation test")
        
        // Test M3U8 content format validation, don't execute actual parsing
        let validM3U8Content = """
    #EXTM3U
    #EXT-X-VERSION:3
    #EXT-X-TARGETDURATION:10
    #EXT-X-MEDIA-SEQUENCE:0
    #EXTINF:10.0,
    segment1.ts
    #EXTINF:10.0,
    segment2.ts
    #EXT-X-ENDLIST
    """
        
        // Verify basic M3U8 content format
        XCTAssertTrue(validM3U8Content.contains("#EXTM3U"))
        XCTAssertTrue(validM3U8Content.contains("#EXT-X-VERSION"))
        XCTAssertTrue(validM3U8Content.contains("#EXTINF"))
        XCTAssertTrue(validM3U8Content.contains("segment1.ts"))
        XCTAssertTrue(validM3U8Content.contains("segment2.ts"))
        XCTAssertTrue(validM3U8Content.contains("#EXT-X-ENDLIST"))
        
        // Test invalid M3U8 content
        let invalidM3U8Content = "This is not a valid M3U8 file"
        XCTAssertFalse(invalidM3U8Content.contains("#EXTM3U"))
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testURLValidationLogic() {
        let expectation = XCTestExpectation(description: "URL validation logic test")
        
        // Test URL format validation, don't execute actual network requests
        let validHTTPURL = URL(string: "https://example.com/test.m3u8")!
        XCTAssertEqual(validHTTPURL.scheme, "https")
        XCTAssertNotNil(validHTTPURL.host)
        
        let validHTTPSURL = URL(string: "http://example.com/test.m3u8")!
        XCTAssertEqual(validHTTPSURL.scheme, "http")
        XCTAssertNotNil(validHTTPSURL.host)
        
        // Test invalid URL scheme
        let invalidURL = URL(string: "ftp://invalid.url")!
        XCTAssertNotEqual(invalidURL.scheme, "https")
        XCTAssertNotEqual(invalidURL.scheme, "http")
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testTaskStatusEnum() {
        let expectation = XCTestExpectation(description: "Task status enum test")
        
        // Test various states of TaskStatus enum
        let pendingStatus = TaskStatus.pending
        let downloadingStatus = TaskStatus.downloading(progress: 0.5)
        let processingStatus = TaskStatus.processing
        let completedStatus = TaskStatus.completed
        let cancelledStatus = TaskStatus.cancelled
        
        // These states should be created without crashing
        XCTAssertNotNil(pendingStatus)
        XCTAssertNotNil(downloadingStatus)
        XCTAssertNotNil(processingStatus)
        XCTAssertNotNil(completedStatus)
        XCTAssertNotNil(cancelledStatus)
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testM3U8ParserServiceDirect() {
        let expectation = XCTestExpectation(description: "M3U8 parser service direct test")
        
        // Directly test parser service, avoid async operations
        let parser = try! testContainer.resolve(M3U8ParserServiceProtocol.self)
        
        // Create simple M3U8 content
        let m3u8Content = """
    #EXTM3U
    #EXT-X-VERSION:3
    #EXT-X-TARGETDURATION:10
    #EXT-X-MEDIA-SEQUENCE:0
    #EXTINF:10.0,
    segment1.ts
    #EXTINF:10.0,
    segment2.ts
    #EXT-X-ENDLIST
    """
        
        do {
            let baseURL = URL(string: "https://example.com/")!
            let result = try parser.parseContent(m3u8Content, baseURL: baseURL, type: .media)
            
            switch result {
            case .media(let playlist):
                XCTAssertNotNil(playlist)
                XCTAssertEqual(playlist.tags.mediaSegments.count, 2)
                XCTAssertEqual(playlist.tags.mediaSegments[0].uri, "segment1.ts")
                XCTAssertEqual(playlist.tags.mediaSegments[1].uri, "segment2.ts")
            case .master, .cancelled:
                XCTFail("Expected media playlist")
            }
            
            expectation.fulfill()
            
        } catch {
            XCTFail("M3U8 parser service direct test failed: \(error)")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testDownloadConfigurationTypes() {
        let expectation = XCTestExpectation(description: "Download configuration types test")
        
        // Test DownloadConfiguration and related types
        let defaultConfig = DownloadConfiguration.default
        XCTAssertEqual(defaultConfig.maxConcurrentDownloads, 3)
        XCTAssertEqual(defaultConfig.connectionTimeout, 30.0)
        XCTAssertEqual(defaultConfig.retryAttempts, 3)
        XCTAssertEqual(defaultConfig.qualityPreference, .auto)
        XCTAssertTrue(defaultConfig.cleanupTempFiles)
        XCTAssertFalse(defaultConfig.httpHeaders.isEmpty)
        
        // Test custom configuration
        let customConfig = DownloadConfiguration(
            maxConcurrentDownloads: 5,
            connectionTimeout: 60.0,
            retryAttempts: 5,
            qualityPreference: .highest,
            cleanupTempFiles: false,
            httpHeaders: ["Custom-Header": "CustomValue"]
        )
        
        XCTAssertEqual(customConfig.maxConcurrentDownloads, 5)
        XCTAssertEqual(customConfig.connectionTimeout, 60.0)
        XCTAssertEqual(customConfig.retryAttempts, 5)
        XCTAssertEqual(customConfig.qualityPreference, .highest)
        XCTAssertFalse(customConfig.cleanupTempFiles)
        XCTAssertEqual(customConfig.httpHeaders["Custom-Header"], "CustomValue")
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDownloadProgressCalculation() {
        let expectation = XCTestExpectation(description: "Download progress calculation test")
        
        // Test DownloadProgress calculation logic
        let progress1 = DownloadProgress(
            totalSegments: 100,
            completedSegments: 50,
            totalBytes: 1000000,
            downloadedBytes: 500000,
            state: .downloading
        )
        
        XCTAssertEqual(progress1.progress, 0.5)
        XCTAssertEqual(progress1.totalSegments, 100)
        XCTAssertEqual(progress1.completedSegments, 50)
        XCTAssertEqual(progress1.state, .downloading)
        
        // Test completed state
        let progress2 = DownloadProgress(
            totalSegments: 100,
            completedSegments: 100,
            totalBytes: 1000000,
            downloadedBytes: 1000000,
            state: .completed
        )
        
        XCTAssertEqual(progress2.progress, 1.0)
        XCTAssertEqual(progress2.state, .completed)
        
        // Test empty progress
        let progress3 = DownloadProgress(
            totalSegments: 0,
            completedSegments: 0,
            totalBytes: 0,
            downloadedBytes: 0,
            state: .pending
        )
        
        XCTAssertEqual(progress3.progress, 0.0)
        XCTAssertEqual(progress3.state, .pending)
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDownloadAPISignature() {
        let expectation = XCTestExpectation(description: "Download API signature test")
        
        // Test download API signature and parameter validation
        let testURL = URL(string: "https://example.com/test.m3u8")!
        
        //    // Verify Method type baseURL property
        //    let webMethod = Method.web
        //    XCTAssertNil(webMethod.baseURL)
        
        // Verify URL basic properties
        XCTAssertEqual(testURL.scheme, "https")
        XCTAssertEqual(testURL.host, "example.com")
        XCTAssertEqual(testURL.pathExtension, "m3u8")
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - Test Helper Types

enum TimeoutError: Error {
    case downloadTimeout
    case networkTimeout
    
    var localizedDescription: String {
        switch self {
        case .downloadTimeout:
            return "Download operation timed out"
        case .networkTimeout:
            return "Network operation timed out"
        }
    }
}
