//
//  DefaultM3U8ParserService.swift
//  TFM3U8Utility
//
//  Created by tree_fly on 2025/7/13.
//

import Foundation

// MARK: - Default M3U8 Parser Service

public struct DefaultM3U8ParserService: M3U8ParserServiceProtocol {
  
  public init() {}
  
  public func parseContent(_ content: String, baseURL: URL, type: PlaylistType) throws -> M3U8Parser.ParserResult {
    let parser = M3U8Parser()
    let params = M3U8Parser.Params(playlist: content, playlistType: type, baseUrl: baseURL)
    return try parser.parse(params: params)
  }
} 
