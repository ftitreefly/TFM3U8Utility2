# TFM3U8Utility2

A high-performance Swift library and CLI tool for downloading, parsing, and processing M3U8 video files. Built with Swift 6+ features, modern concurrency patterns, and comprehensive dependency injection architecture.

## ✨ Features

- 🚀 **Swift 6+ Ready**: Built with the latest Swift 6 features including strict concurrency checking
- 🔧 **Dependency Injection**: Full DI architecture for better testability and modularity
- 📱 **Cross-Platform**: macOS 12.0+ support with both library and CLI interfaces
- 🛡️ **Comprehensive Error Handling**: Detailed error types with context information
- 🔄 **Concurrent Downloads**: Configurable concurrent download support (up to 20 concurrent tasks)
- 📊 **Real-time Progress**: Verbose output mode for detailed download monitoring
- 🎯 **Multiple Sources**: Support for both web URLs and local M3U8 files
- 🎬 **Video Processing**: FFmpeg integration for video segment combination
- 🔐 **Encryption Support**: Built-in support for encrypted M3U8 streams
- 🧪 **Extensive Testing**: 8 comprehensive test suites covering all major functionality

## 📚 文档

- **[项目概览](Docs/DOCUMENTATION.md)** - 项目架构和技术栈说明
- **[快速开始指南](Docs/QUICKSTART.md)** - 5分钟快速上手
- **[完整文档](Docs/DOCUMENTATION.md)** - 详细的项目文档和架构说明
- **[API 参考](Docs/API_REFERENCE.md)** - 完整的 API 文档
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
    .package(url: "https://github.com/ftitreefly/TFM3U8Utility2.git", from: "1.0.0")
]
```

### External Dependencies

For optimal performance, install these tools:

```bash
# Install FFmpeg for video processing
brew install ffmpeg
```

## 🚀 Quick Start

### As a Library

```swift
import TFM3U8Utility

// Initialize the utility with performance-optimized configuration
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

# Download with custom filename (output will be .mp4)
m3u8-utility download https://example.com/video.m3u8 --name my-video

# Download with verbose output
m3u8-utility download https://example.com/video.m3u8 -v

# Show tool information and version
m3u8-utility info

# Get help for all commands
m3u8-utility --help
```

## 📖 API Reference

### Core Functions

#### `TFM3U8Utility.initialize(with:)`

Initializes the dependency injection container with configuration.

```swift
// Use default performance-optimized configuration
await TFM3U8Utility.initialize()

// Use custom configuration
let config = DIConfiguration.performanceOptimized()
config.maxConcurrentDownloads = 10
await TFM3U8Utility.initialize(with: config)
```

#### `TFM3U8Utility.download(_:url:savedDirectory:name:configuration:verbose:)`

Downloads M3U8 content and processes it with comprehensive error handling.

```swift
try await TFM3U8Utility.download(
    .web,  // or .local for local files
    url: URL(string: "https://example.com/video.m3u8")!,
    savedDirectory: "/path/to/save",
    name: "my-video",
    configuration: DIConfiguration.performanceOptimized(),
    verbose: true  // Enable detailed progress output
)
```

#### `TFM3U8Utility.parse(url:method:configuration:)`

Parses M3U8 files and returns structured data with support for both web and local files.

```swift
// Parse from web URL
let result = try await TFM3U8Utility.parse(
    url: URL(string: "https://example.com/video.m3u8")!,
    method: .web,
    configuration: DIConfiguration.performanceOptimized()
)

// Parse local file
let localResult = try await TFM3U8Utility.parse(
    url: URL(fileURLWithPath: "/path/to/local/playlist.m3u8"),
    method: .local,
    configuration: DIConfiguration.performanceOptimized()
)
```

### Configuration

```swift
let config = DIConfiguration(
    ffmpegPath: "/opt/homebrew/bin/ffmpeg",
    curlPath: "/usr/bin/curl",
    defaultHeaders: [
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
        "Accept": "*/*",
        "Accept-Language": "en-US,en;q=0.9"
    ],
    maxConcurrentDownloads: 20,
    downloadTimeout: 60
)
```

## 🏗️ Architecture

### Core Components

- **TFM3U8Utility**: Main public API interface with comprehensive documentation
- **M3U8Parser**: High-performance playlist parser supporting master and media playlists
- **OptimizedTaskManager**: Concurrent task management with configurable limits
- **OptimizedVideoProcessor**: Video segment processing with FFmpeg integration
- **DependencyContainer**: Full dependency injection system for modularity

### Service Protocols

- `M3U8DownloaderProtocol`: Content downloading with retry mechanisms
- `M3U8ParserServiceProtocol`: Playlist parsing with error context
- `VideoProcessorProtocol`: Video processing and segment combination
- `TaskManagerProtocol`: Task coordination and progress tracking
- `FileSystemServiceProtocol`: File operations with error handling
- `CommandExecutorProtocol`: External command execution (FFmpeg, curl)

### Error Handling

The library provides comprehensive error types with detailed context:

- `NetworkError`: Network-related errors with HTTP status codes
- `ParsingError`: M3U8 parsing errors with line numbers and context
- `FileSystemError`: File system operations with path information
- `ProcessingError`: Video processing errors with command details
- `ConfigurationError`: Configuration validation errors

## 🖥️ CLI Commands

### Download Command

```bash
m3u8-utility download <URL> [options]
```

**Options:**
- `--name, -n`: Custom output filename (outputs .mp4 file)
- `--verbose, -v`: Enable verbose output for detailed progress

**Examples:**
```bash
# Basic download to Downloads folder
m3u8-utility download https://example.com/video.m3u8

# Download with custom name
m3u8-utility download https://example.com/video.m3u8 --name my-video

# Verbose download with progress details
m3u8-utility download https://example.com/video.m3u8 -v

# Combined options
m3u8-utility download https://example.com/video.m3u8 --name my-video -v
```

### Info Command

```bash
m3u8-utility info
```

Displays tool information, version, and available features.

## 🔧 Advanced Usage

### Custom Configuration

```swift
// Create custom configuration
let customConfig = DIConfiguration(
    ffmpegPath: "/custom/path/ffmpeg",
    maxConcurrentDownloads: 5,
    downloadTimeout: 120
)

// Initialize with custom config
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
} catch let error as ProcessingError {
    print("Processing error: \(error.message)")
} catch {
    print("Unexpected error: \(error)")
}
```

### Dependency Injection

```swift
// Register custom services
let container = DependencyContainer()
container.register(M3U8DownloaderProtocol.self) {
    CustomDownloader()
}

// Use custom container
Dependencies = container
```

## ⚡ Performance Optimization

### Concurrent Downloads

The library supports highly configurable concurrent downloads:

```swift
let config = DIConfiguration.performanceOptimized()
config.maxConcurrentDownloads = 20  // Adjust based on your needs
```

### Hardware Acceleration

Video processing automatically detects and uses hardware acceleration when available through FFmpeg.

### Memory Management

- Efficient streaming parser for large playlists
- Memory-mapped file operations
- Automatic cleanup of temporary files
- Configurable download timeouts

## 🧪 Testing

Run the comprehensive test suite:

```bash
swift test
```

The project includes 8 comprehensive test suites:

- **DownloadTests**: Download functionality and error handling
- **ParseTests**: M3U8 parsing accuracy and edge cases
- **NetworkTests**: Network operations and retry mechanisms
- **TaskManagerTests**: Concurrent task management
- **PerformanceOptimizedTests**: Performance optimization features
- **IntegrationTests**: End-to-end functionality
- **CombineTests**: Reactive programming patterns
- **XCTestManifests**: Test discovery and organization

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes following Swift 6+ guidelines
4. Add tests for new functionality
5. Ensure all tests pass with `swift test`
6. Submit a pull request

### Development Setup

```bash
# Clone the repository
git clone https://github.com/ftitreefly/TFM3U8Utility2.git
cd TFM3U8Utility2

# Build the project
swift build

# Run tests
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

### Version 1.0.0 - 2025-07-21
- 🎉 Initial release with Swift 6+ support
- 🚀 High-performance M3U8 processing with concurrent downloads
- 🖥️ CLI tool with download and info commands
- 🛡️ Comprehensive error handling with detailed error types
- 🔧 Full dependency injection architecture
- 📱 Cross-platform macOS support (12.0+)
- 🎬 Video processing with FFmpeg integration
- 🔐 Encryption support for M3U8 streams
- 🧪 Extensive test coverage (8 test suites)
- 📊 Verbose output mode for detailed progress tracking
