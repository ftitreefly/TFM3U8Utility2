//
//  Debug.swift
//  TFM3U8Utility
//
//  Created by tree_fly on 2025/7/16.
//

// MARK: - Public Verbose Output Helper

/// Global verbose print function with hierarchical indentation
///
/// This function prints messages only when verbose mode is enabled,
/// with support for hierarchical indentation to show the structure
/// of the download process.
///
/// - Parameters:
///   - verbose: Whether verbose mode is enabled
///   - tab: The indentation level (0 = no indentation, 1 = 2 spaces, etc.)
///   - message: The message to print
func vprintf(_ verbose: Bool, tab: Int = 0, _ message: String) {
    guard verbose else { return }
    let indent = String(repeating: "  ", count: tab)
    print("\(indent)* \(message)")
}
