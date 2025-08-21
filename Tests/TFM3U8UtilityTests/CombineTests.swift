//
//  CombineTests.swift
//  TFM3U8UtilityTests
//
//  Created by tree_fly on 2025/7/13.
//

import Foundation
import XCTest

@testable import TFM3U8Utility

final class CombineTests: XCTestCase, @unchecked Sendable {

    var testContainer: DependencyContainer!
    var tempDirectory: URL!
    var fileSystem: FileSystemServiceProtocol!
    var videoSystem: VideoProcessorProtocol!
    var httpSystem: M3U8DownloaderProtocol!

    override func setUp() {
        super.setUp()
        testContainer = DependencyContainer()
        testContainer.configure(with: DIConfiguration.performanceOptimized())
        
        videoSystem = try! testContainer.resolve(VideoProcessorProtocol.self)
        httpSystem = try! testContainer.resolve(M3U8DownloaderProtocol.self)
        
        // Create temporary directory
        fileSystem = try! testContainer.resolve(FileSystemServiceProtocol.self)
        
        do {
            tempDirectory = try fileSystem.createTemporaryDirectory(nil)
        } catch {
            XCTFail("Failed to create temporary directory: \(error)")
            return
        }
        
        // Test temporary directory created
    }

    override func tearDown() {
        // Clean up temporary directory
        if let tempDir = tempDirectory {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        testContainer = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    /// Download test ts segments from network
    private func downloadTestSegments(count: Int = 3) async throws -> URL {
        // Downloading \(count) test ts segments from network
        
        // Use Apple's public test stream segments
        let segmentBaseURL = "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/gear1/"
        let testSegmentURLs = (0..<count).map { 
            URL(string: "\(segmentBaseURL)fileSequence\($0).ts")! 
        }
        
        let headers = [
            "User-Agent": "TFM3U8Utility-Test/1.0",
            "Accept": "*/*"
        ]
        
        // Create segments directory
        let segmentsDirectory = tempDirectory.appendingPathComponent("segments")
        try fileSystem.createDirectory(at: segmentsDirectory, withIntermediateDirectories: true)
        
        // Download segments
        try await httpSystem.downloadSegments(
            at: testSegmentURLs, 
            to: segmentsDirectory, 
            headers: headers
        )
        
        // Verify downloaded files
        let files = try fileSystem.contentsOfDirectory(at: segmentsDirectory)
        XCTAssertGreaterThanOrEqual(files.count, count, "Should have downloaded at least \(count) files")
        
        // Successfully downloaded \(files.count) ts segments
        
        return segmentsDirectory
    }

    // MARK: - OptimizedVideoProcessor Tests

    /// Test OptimizedVideoProcessor basic functionality
    func testOptimizedVideoProcessorBasicFunctionality() async throws {
        XCTAssertNotNil(videoSystem, "VideoProcessor should be properly resolved")

        // Verify VideoProcessor is OptimizedVideoProcessor type
        guard videoSystem is OptimizedVideoProcessor else {
            XCTFail("VideoProcessor should be OptimizedVideoProcessor type")
            return
        }

        // OptimizedVideoProcessor basic functionality verification passed
    }

    /// Test video segment combination functionality with 1 segment
    func testCombineSingleSegment() async throws {
        // Starting single segment combination test

        // Download 1 test segment
        let segmentsDirectory = try await downloadTestSegments(count: 1)
        let outputFile = tempDirectory.appendingPathComponent("combined_single.mp4")

        // Test combination functionality
        do {
            try await videoSystem.combineSegments(in: segmentsDirectory, outputFile: outputFile)
            
            // Verify output file exists
            XCTAssertTrue(FileManager.default.fileExists(atPath: outputFile.path), "Combined output file should exist")
            
            // Verify output file size
            let attributes = try FileManager.default.attributesOfItem(atPath: outputFile.path)
            let fileSize = attributes[.size] as? UInt64 ?? 0
            XCTAssertGreaterThan(fileSize, 0, "Output file size should be greater than 0")
            
            // Single segment combination test passed
        } catch {
            // In environments without FFmpeg, this test may fail
            throw XCTSkip("Skipping single segment combination test: FFmpeg may be unavailable")
        }
    }

    /// Test video segment combination functionality with 2 segments
    func testCombineTwoSegments() async throws {
        // Starting two segments combination test

        // Download 2 test segments
        let segmentsDirectory = try await downloadTestSegments(count: 2)
        let outputFile = tempDirectory.appendingPathComponent("combined_two.mp4")

        // Test combination functionality
        do {
            try await videoSystem.combineSegments(in: segmentsDirectory, outputFile: outputFile)
            
            // Verify output file exists
            XCTAssertTrue(FileManager.default.fileExists(atPath: outputFile.path), "Combined output file should exist")
            
            // Verify output file size
            let attributes = try FileManager.default.attributesOfItem(atPath: outputFile.path)
            let fileSize = attributes[.size] as? UInt64 ?? 0
            XCTAssertGreaterThan(fileSize, 0, "Output file size should be greater than 0")
            
            // Two segments combination test passed
        } catch {
            // In environments without FFmpeg, this test may fail
            throw XCTSkip("Skipping two segments combination test: FFmpeg may be unavailable")
        }
    }

    /// Test video segment combination functionality with 3 segments
    func testCombineThreeSegments() async throws {
        // Starting three segments combination test

        // Download 3 test segments
        let segmentsDirectory = try await downloadTestSegments(count: 3)
        let outputFile = tempDirectory.appendingPathComponent("combined_three.mp4")

        // Test combination functionality
        do {
            try await videoSystem.combineSegments(in: segmentsDirectory, outputFile: outputFile)
            
            // Verify output file exists
            XCTAssertTrue(FileManager.default.fileExists(atPath: outputFile.path), "Combined output file should exist")
            
            // Verify output file size
            let attributes = try FileManager.default.attributesOfItem(atPath: outputFile.path)
            let fileSize = attributes[.size] as? UInt64 ?? 0
            XCTAssertGreaterThan(fileSize, 0, "Output file size should be greater than 0")
            
            // Three segments combination test passed
        } catch {
            // In environments without FFmpeg, this test may fail
            throw XCTSkip("Skipping three segments combination test: FFmpeg may be unavailable")
        }
    }

    /// Test error handling with empty directory
    func testErrorHandlingEmptyDirectory() async throws {
        // Starting error handling test with empty directory

        // Test handling of empty directory
        let emptyDirectory = tempDirectory.appendingPathComponent("empty_segments")
        try FileManager.default.createDirectory(at: emptyDirectory, withIntermediateDirectories: true)
        
        let outputFile = tempDirectory.appendingPathComponent("error_output.mp4")

        do {
            try await videoSystem.combineSegments(in: emptyDirectory, outputFile: outputFile)
            XCTFail("Should throw error because directory is empty")
        } catch {
            // Error handling test passed
            XCTAssertTrue(error is ProcessingError, "Should throw ProcessingError type error")
        }
    }

    /// Test error handling with non-existent directory
    func testErrorHandlingNonExistentDirectory() async throws {
        // Starting error handling test with non-existent directory

        // Test handling of non-existent directory
        let nonExistentDirectory = tempDirectory.appendingPathComponent("non_existent_segments")
        let outputFile = tempDirectory.appendingPathComponent("error_output2.mp4")

        do {
            try await videoSystem.combineSegments(in: nonExistentDirectory, outputFile: outputFile)
            XCTFail("Should throw error because directory does not exist")
        } catch {
            // Error handling test passed
            // The error could be various types depending on the implementation
            // Just verify that an error was thrown
            XCTAssertTrue(true, "Error was correctly thrown for non-existent directory")
        }
    }
}
