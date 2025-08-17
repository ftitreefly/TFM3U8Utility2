# TFM3U8Utility2

A high-performance Swift library and CLI tool for downloading, parsing, and processing M3U8 video files. Built with Swift 6+ features, modern concurrency patterns, and comprehensive dependency injection architecture.

## ✨ Features

- 🚀 **Swift 6+ Ready**: Built with the latest Swift 6 features including strict concurrency checking
- 🔧 **Dependency Injection**: Full DI architecture for better testability and modularity
- 📱 **Cross-Platform**: macOS 12.0+ support with both library and CLI interfaces
- 🛡️ **Comprehensive Error Handling**: Detailed error types with context information
- 🔄 **Concurrent Downloads**: Configurable concurrent download support (up to 20 concurrent tasks)
- 📊 **Advanced Logging System**: Multi-level logging with categories and colored output
- 🎯 **Multiple Sources**: Support for both web URLs and local M3U8 files
- 🎬 **Video Processing**: FFmpeg integration for video segment combination
- 🔐 **Encryption Support**: Built-in support for encrypted M3U8 streams
- 🧪 **Extensive Testing**: Comprehensive test suites covering all major functionality

## 📚 文档

- **[项目概览](Docs/DOCUMENTATION.md)** - 项目架构和技术栈说明
- **[快速开始指南](Docs/QUICKSTART.md)** - 5分钟快速上手
- **[完整文档](Docs/DOCUMENTATION.md)** - 详细的项目文档和架构说明
- **[API 参考](Docs/API_REFERENCE.md)** - 完整的 API 文档
- **[日志系统指南](Docs/LOGGING_GUIDE.md)** - 高级日志系统使用指南
- **[第三方集成指南](Docs/THIRD_PARTY_INTEGRATION.md)** - 统一的第三方工具接口使用指南
- **[贡献指南](Docs/CONTRIBUTING.md)** - 如何为项目贡献代码

## 🛠️ Installation

### Requirements

- macOS 12.0 or later
- Swift 6.0 or later
- Xcode 15.0 or later (for development)

### Swift Package Manager

Add TFM3U8Utility2 to your project dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/ftitreefly/TFM3U8Utility2.git", from: "1.3.1")
]
```

### External Dependencies

```bash
# Install FFmpeg for video processing
brew install ffmpeg
```

## 🚀 Quick Start

### As a Library

```swift
import TFM3U8Utility

// Initialize the utility
await TFM3U8Utility.initialize()

// Download an M3U8 file with verbose output
try await TFM3U8Utility.download(
    .web,
    url: URL(string: "https://example.com/video.m3u8")!,
    savedDirectory: "/Users/username/Downloads/videos/",
    name: "my-video",
    verbose: true
)

// Parse an M3U8 file
let result = try await TFM3U8Utility.parse(
    url: URL(string: "https://example.com/video.m3u8")!
)

switch result {
case .master(let masterPlaylist):
    print("Master playlist with \(masterPlaylist.tags.streamTags.count) streams")
case .media(let mediaPlaylist):
    print("Media playlist with \(mediaPlaylist.tags.mediaSegments.count) segments")
case .cancelled:
    print("Parsing was cancelled")
}
```

### As a CLI Tool

```bash
# Download an M3U8 file with default settings
m3u8-utility download https://example.com/video.m3u8

# Download with custom filename
m3u8-utility download https://example.com/video.m3u8 --name my-video

# Extract M3U8 links from web pages
m3u8-utility extract "https://example.com/video-page"

# Show tool information
m3u8-utility info
```

## 📊 Logging System

Configure logging levels and categories:

```swift
// Production configuration - minimal output
Logger.configure(.production())

// Development configuration - detailed output
Logger.configure(.development())

// Custom configuration
let customConfig = LoggerConfiguration(
    minimumLevel: .debug,
    includeTimestamps: true,
    includeCategories: true,
    enableColors: true
)
Logger.configure(customConfig)
```

## 🔧 Advanced Usage

### Custom Configuration

```swift
let customConfig = DIConfiguration(
    ffmpegPath: "/custom/path/ffmpeg",
    maxConcurrentDownloads: 10,
    downloadTimeout: 60
)

await TFM3U8Utility.initialize(with: customConfig)
```

### Error Handling

```swift
do {
    try await TFM3U8Utility.download(.web, url: videoURL, verbose: true)
} catch let error as FileSystemError {
    print("File system error: \(error.message)")
} catch let error as NetworkError {
    print("Network error: \(error.message)")
} catch {
    print("Unexpected error: \(error)")
}
```

## 🔗 Third-Party Integration

TFM3U8Utility2 provides a unified protocol interface for extracting M3U8 links from web pages, making it easy for third-party tools to integrate with various streaming platforms.

### Quick Start

```swift
import TFM3U8Utility

let registry = DefaultM3U8ExtractorRegistry()
registry.registerExtractor(YouTubeExtractor())

let links = try await registry.extractM3U8Links(
    from: URL(string: "https://youtube.com/watch?v=123")!,
    options: LinkExtractionOptions.default
)
```

### CLI Integration

```bash
# Extract M3U8 links from web pages
m3u8-utility extract "https://example.com/video-page" --verbose

# Save results to file
m3u8-utility extract "https://example.com/video-page" --output links.txt
```

## 🧪 Testing

Run the comprehensive test suite:

```bash
swift test
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes following Swift 6+ guidelines
4. Add tests for new functionality
5. Ensure all tests pass with `swift test`
6. Submit a pull request

### Development Setup

```bash
git clone https://github.com/ftitreefly/TFM3U8Utility2.git
cd TFM3U8Utility2
swift build
swift test

# Build and run CLI
swift run m3u8-utility --help

# Run with verbose output
swift run m3u8-utility download https://example.com/video.m3u8 -v
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Third-Party Notices

This project includes code adapted from [go-swifty-m3u8](https://github.com/gal-orlanczyk/go-swifty-m3u8), which is licensed under the MIT License:

```
Copyright (c) Gal Orlanczyk

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/ftitreefly/TFM3U8Utility2/issues)
- **Documentation**: [API Documentation](https://ftitreefly.github.io/TFM3U8Utility2)
- **Discussions**: [GitHub Discussions](https://github.com/ftitreefly/TFM3U8Utility2/discussions)

## 📋 Changelog

### Version 1.3.1 - 2025-01-27
- 🔧 Enhanced YouTube M3U8 link extractor with improved error handling
- 🏗️ Simplified ExtractCommand structure for better maintainability
- ⚡ Optimized YouTubeExtractor demo implementation
- 🎯 Enhanced command structures with dynamic versioning support

### Version 1.3.0 - 2025-01-27
- 🎬 YouTube M3U8 link extractor for extracting streaming links
- 🔗 Third-party integration support for M3U8 link extraction
- 🌐 Enhanced CLI extract command with comprehensive options
- 📊 Support for multiple extraction methods
- 🔧 Custom User-Agent and HTTP header support

### Version 1.2.0 - 2025-07-28
- ⚡ Performance optimization with streamlined task management
- 🧹 Code cleanup and architecture improvements
- 📊 Enhanced logging integration

### Version 1.1.0 - 2025-07-25
- 🎉 Advanced logging system with multiple levels and categories
- 🚀 Comprehensive logging configuration
- 📊 Log categories for better organization

### Version 1.0.0 - 2025-07-21
- 🎉 Initial release with Swift 6+ support
- 🚀 High-performance M3U8 processing
- 🖥️ CLI tool with download and info commands
- 🛡️ Comprehensive error handling
- 🔧 Full dependency injection architecture
