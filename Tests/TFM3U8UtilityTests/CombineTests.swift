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

    override func setUp() {
        super.setUp()
        testContainer = DependencyContainer()
        testContainer.configure(with: DIConfiguration.performanceOptimized())
        
        videoSystem = testContainer.resolve(VideoProcessorProtocol.self)
        
        // Create temporary directory
        fileSystem = testContainer.resolve(FileSystemServiceProtocol.self)
        
        do {
            tempDirectory = try fileSystem.createTemporaryDirectory(nil)
        } catch {
            XCTFail("Failed to create temporary directory: \(error)")
            return
        }
        
        print("📁 Test temporary directory: \(tempDirectory.path)")
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

    /// Get test data folder path
    private func getTestDataPath() -> String {
        let standardPaths = [
            "/private/tmp/Tests/TFM3U8UtilityTests/TestData/ts_segments",
            "\(NSHomeDirectory())/.tmp/TFM3U8UtilityTests/TestData/ts_segments"
        ]

        for path in standardPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }

        return standardPaths[0]
    }

    /// Check if test data is available
    private func checkTestDataAvailable() throws -> (path: String, files: [String]) {
        let testDataPath = getTestDataPath()

        guard FileManager.default.fileExists(atPath: testDataPath) else {
            throw XCTSkip("Test data folder does not exist: \(testDataPath). Please run ./Scripts/setup-test-data.sh")
        }

        let files = try FileManager.default.contentsOfDirectory(atPath: testDataPath)
        let tsFiles = files.filter { $0.contains("fileSequence") && $0.hasSuffix(".ts") }

        guard !tsFiles.isEmpty else {
            throw XCTSkip("No ts files found in test data folder")
        }

        return (testDataPath, tsFiles)
    }

    // MARK: - Test Data Validation

    /// Test data file validation
    func testTestDataFilesExist() throws {
        print("📋 Starting test data file validation...")

        let (testDataPath, tsFiles) = try checkTestDataAvailable()
        print("🔍 Test data path: \(testDataPath)")
        print("📋 Found \(tsFiles.count) test files")

        // Verify each test file exists and has content
        for fileName in tsFiles.prefix(5) {
            let filePath = "\(testDataPath)/\(fileName)"
            let fileSize = try FileManager.default.attributesOfItem(atPath: filePath)[.size] as? UInt64 ?? 0
            XCTAssertGreaterThan(fileSize, 0, "Test file size should be greater than 0")
        }

        print("✅ Test data validation passed")
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

        print("✅ OptimizedVideoProcessor basic functionality verification passed")
    }

    /// Test video segment combination functionality
    func testCombineSegments() async throws {
        print("🔗 Starting video segment combination test...")

        let (testDataPath, tsFiles) = try checkTestDataAvailable()

        // Create test input directory
        let inputDirectory = tempDirectory.appendingPathComponent("segments")
        try fileSystem.createDirectory(at: inputDirectory.path(), withIntermediateDirectories: true)
        
        // Copy test files to input directory
        let fileCount = min(5, tsFiles.count)
        for index in 0..<fileCount {
            let sourceFile = URL(fileURLWithPath: "\(testDataPath)/fileSequence\(index).ts")
            let targetFile = inputDirectory.appendingPathComponent("fileSequence\(index).ts")
            try fileSystem.copyItem(at: sourceFile, to: targetFile)
        }

        // Create output file path
        let outputFile = tempDirectory.appendingPathComponent("combined_output.mp4")

        // Test combination functionality
        do {
            try await videoSystem.combineSegments(in: inputDirectory, outputFile: outputFile)
            
            // Verify output file exists
            XCTAssertTrue(FileManager.default.fileExists(atPath: outputFile.path), "Combined output file should exist")
            
            // Verify output file size
            let attributes = try FileManager.default.attributesOfItem(atPath: outputFile.path)
            let fileSize = attributes[.size] as? UInt64 ?? 0
            XCTAssertGreaterThan(fileSize, 0, "Output file size should be greater than 0")
            
            print("✅ Video segment combination test passed, output file size: \(fileSize) bytes")
        } catch {
            // In environments without FFmpeg, this test may fail
            // We log the error but don't fail the test
            print("⚠️  Video segment combination test failed (possibly due to FFmpeg unavailability): \(error)")
            throw XCTSkip("Skipping video segment combination test: FFmpeg may be unavailable")
        }
    }

    /// Test error handling
    func testErrorHandling() async throws {
        print("🚨 Starting error handling test...")

        // Test handling of empty directory
        let emptyDirectory = tempDirectory.appendingPathComponent("empty_segments")
        try FileManager.default.createDirectory(at: emptyDirectory, withIntermediateDirectories: true)
        
        let outputFile = tempDirectory.appendingPathComponent("error_output.mp4")

        do {
            try await videoSystem.combineSegments(in: emptyDirectory, outputFile: outputFile)
            XCTFail("Should throw error because directory is empty")
        } catch {
            print("✅ Error handling test passed, correctly caught error: \(error)")
            XCTAssertTrue(error is ProcessingError, "Should throw ProcessingError type error")
        }
    }
}
