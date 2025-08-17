//
//  DownloadCommand.swift
//  M3U8CLI
//
//  Created by tree_fly on 2025/7/13.
//

import ArgumentParser
import Foundation
import TFM3U8Utility

/// Command for downloading M3U8 video files from URLs
/// 
/// This command downloads M3U8 playlist files and all their associated video segments
/// to the user's Downloads directory. It supports both HTTP and HTTPS URLs.
/// 
/// ## Usage Examples
/// ```bash
/// # Download with default settings
/// m3u8-utility download https://example.com/video.m3u8
/// 
/// # Download with custom filename
/// m3u8-utility download https://example.com/video.m3u8 --name my-video
/// 
/// # Download with verbose output
/// m3u8-utility download https://example.com/video.m3u8 -v
/// 
/// # Download with both custom name and verbose output
/// m3u8-utility download https://example.com/video.m3u8 --name my-video -v
/// ```
/// 
/// ## Output
/// Downloaded files will be saved to the user's Downloads directory with the following structure:
struct DownloadCommand: AsyncParsableCommand {
    /// Command configuration including name and description
    static let configuration = CommandConfiguration(
        commandName: "download",
        abstract: "Download M3U8 Video Files",
        discussion: """
        Download M3U8 playlist files and all their associated video segments.
        
        Supported features:
        - Automatically download all video segments in the playlist
        - Support for HTTP and HTTPS URLs
        - Customizable output filename
        - Detailed download progress information
        - Error handling and retry mechanisms
        
        Downloaded files will be saved to the user's Downloads directory by default.
        """,
        version: CLI.version
    )
    
    /// The URL of the M3U8 file to download
    /// 
    /// This must be a valid HTTP or HTTPS URL pointing to an M3U8 playlist file.
    /// The URL should be accessible and the file should be a valid M3U8 format.
    @Argument(help: "URL of the M3U8 file")
    var url: String

    /// Optional custom name for the output file
    /// 
    /// If provided, this name will be used for the downloaded M3U8 file.
    /// If not provided, the original filename from the URL will be used.
    /// 
    /// Example: `--name my-video` will save the file as `my-video.mp4`
    @Option(name: [.short, .long], help: "Output filename, file extension is *only* .mp4")
    var name: String?

    /// Enable verbose output for detailed download information
    /// 
    /// When enabled, provides detailed information about the download process,
    /// including progress updates, file sizes, and timing information.
    @Flag(name: [.short], help: "Show verbose output")
    var verbose: Bool = false
    
    /// Executes the download command
    /// 
    /// This method performs the following steps:
    /// 1. Initializes the dependency injection container
    /// 2. Validates the provided URL
    /// 3. Downloads the M3U8 file and all associated segments
    /// 4. Saves files to the Downloads directory
    /// 5. Provides status updates and error handling
    /// 
    /// - Throws: 
    ///   - `ExitCode.failure` if URL is invalid or download fails
    ///   - Various network and file system errors during download
    mutating func run() async throws {

        let outputDirectory: String = "\(NSHomeDirectory())/Downloads/"
            
        // Validate URL
        guard let downloadURL = URL(string: url) else {
            OutputFormatter.printError("Invalid URL format")
            throw ExitCode.failure
        }
     
        do {
            if verbose { OutputFormatter.printInfo("Starting m3u8 file download...") }
            try await TFM3U8Utility.download(
                .web,
                url: downloadURL,
                savedDirectory: outputDirectory,
                name: name,
                verbose: verbose
            )
            if verbose { OutputFormatter.printSuccess("Download completed!") }
        } catch {
            OutputFormatter.printError("Download failed: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }
}

// MARK: - Output Helpers

struct OutputFormatter {
    static func printSuccess(_ message: String) {
        print("✅ \(message)")
    }
    
    static func printError(_ message: String) {
        print("❌ \(message)")
    }
    
    static func printInfo(_ message: String) {
        print("ℹ️  \(message)")
    }
    
    static func printWarning(_ message: String) {
        print("⚠️  \(message)")
    }
}
