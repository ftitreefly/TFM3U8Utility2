//
//  Main.swift
//  M3U8CLI
//
//  Created by tree_fly on 2025/7/13.
//

import ArgumentParser
import Foundation
import TFM3U8Utility

/// M3U8 Video Download and Processing Tool
@main
struct M3U8Utility: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "m3u8-utility",
        abstract: "M3U8 Video Download and Processing Tool",
        discussion: """
        This tool supports downloading and parsing M3U8 video files.
        Supports downloading from URLs or processing local files.
        """,
        version: "1.0.0",
        subcommands: [
            DownloadCommand.self,
            InfoCommand.self
        ]
    )
}
