# TFM3U8Utility

A high-performance Swift library and CLI tool for downloading, parsing, and processing M3U8 video files. Built with Swift 6+ features and modern concurrency patterns.

## Features

- 🚀 **High Performance**: Optimized for speed with Swift 6 concurrency features
- 🔧 **Dependency Injection**: Modular architecture with full DI support
- 📱 **Cross-Platform**: macOS 12.0+ support with CLI and library interfaces
- 🛡️ **Error Handling**: Comprehensive error handling with detailed error types
- 🔄 **Concurrent Downloads**: Configurable concurrent download support
- 📊 **Progress Tracking**: Real-time progress monitoring and status updates
- 🎯 **Multiple Sources**: Support for both web URLs and local files
- 🎬 **Video Processing**: Integration with FFmpeg for video segment combination
- 🔐 **Encryption Support**: Built-in support for encrypted M3U8 streams

## 📚 文档

- **[项目概览](Docs/DOCUMENTATION.md)** - 项目架构和技术栈说明
- **[快速开始指南](Docs/QUICKSTART.md)** - 5分钟快速上手
- **[完整文档](Docs/DOCUMENTATION.md)** - 详细的项目文档和架构说明
- **[API 参考](Docs/API_REFERENCE.md)** - 完整的 API 文档
- **[贡献指南](Docs/CONTRIBUTING.md)** - 如何为项目贡献代码

## Installation

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

## Quick Start

### As a Library

```swift
import TFM3U8Utility

// Initialize the utility
await TFM3U8Utility.initialize()

// Download an M3U8 file
try await TFM3U8Utility.download(
    .web,
    url: URL(string: "https://example.com/video.m3u8")!,
    savedDirectory: "/Users/username/Downloads/videos/",
    name: "my-video"
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
# Download an M3U8 file
m3u8-utility download https://example.com/video.m3u8

# Download with custom filename to my-video.mp4
m3u8-utility download https://example.com/video.m3u8 --name my-video

# Download with verbose output
m3u8-utility download https://example.com/video.m3u8 -v

# Show tool information
m3u8-utility info
```

## API Reference

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

#### `TFM3U8Utility.download(_:url:savedDirectory:name:configuration:)`

Downloads M3U8 content and processes it.

```swift
try await TFM3U8Utility.download(
    .web,  // or .local for local files
    url: URL(string: "https://example.com/video.m3u8")!,
    savedDirectory: "/path/to/save",
    name: "my-video",
    configuration: DIConfiguration.performanceOptimized()
)
```

#### `TFM3U8Utility.parse(url:method:configuration:)`

Parses M3U8 files and returns structured data.

```swift
let result = try await TFM3U8Utility.parse(
    url: URL(string: "https://example.com/video.m3u8")!,
    method: .web,
    configuration: DIConfiguration.performanceOptimized()
)
```

### Configuration

```swift
let config = DIConfiguration(
    ffmpegPath: "/opt/homebrew/bin/ffmpeg",
    curlPath: "/usr/bin/curl",
    defaultHeaders: ["User-Agent": "Custom User Agent"],
    maxConcurrentDownloads: 20,
    downloadTimeout: 60
)
```

## Architecture

### Core Components

- **TFM3U8Utility**: Main public API interface
- **M3U8Parser**: High-performance playlist parser
- **OptimizedTaskManager**: Concurrent task management
- **OptimizedVideoProcessor**: Video segment processing
- **DependencyContainer**: Dependency injection system

### Service Protocols

- `M3U8DownloaderProtocol`: Content downloading
- `M3U8ParserServiceProtocol`: Playlist parsing
- `VideoProcessorProtocol`: Video processing
- `TaskManagerProtocol`: Task coordination
- `FileSystemServiceProtocol`: File operations
- `CommandExecutorProtocol`: External command execution

### Error Handling

The library provides comprehensive error types:

- `NetworkError`: Network-related errors
- `ParsingError`: M3U8 parsing errors
- `FileSystemError`: File system operations
- `ProcessingError`: Video processing errors
- `ConfigurationError`: Configuration validation

## CLI Commands

### Download Command

```bash
m3u8-utility download <URL> [options]
```

**Options:**
- `--name, -n`: Custom output filename
- `--verbose, -v`: Enable verbose output

**Examples:**
```bash
# Basic download
m3u8-utility download https://example.com/video.m3u8

# Download with custom name
m3u8-utility download https://example.com/video.m3u8 --name my-video

# Verbose download
m3u8-utility download https://example.com/video.m3u8 -v
```

### Info Command

```bash
m3u8-utility info
```

Displays tool information, version, and available features.

## Advanced Usage

### Custom Configuration

```swift
// Create custom configuration
let customConfig = DIConfiguration(
    ffmpegPath: "/custom/path/ffmpeg",
    maxConcurrentDownloads: 5,
    downloadTimeout: 120
)
```

// Initialize with custom config
await TFM3U8Utility.initialize(with: customConfig)
```

### Error Handling

```swift
do {
    try await TFM3U8Utility.download(.web, url: videoURL)
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

## Performance Optimization

### Concurrent Downloads

The library supports configurable concurrent downloads:

```swift
let config = DIConfiguration.performanceOptimized()
config.maxConcurrentDownloads = 20  // Adjust based on your needs
```

### Hardware Acceleration

Video processing automatically detects and uses hardware acceleration when available.

### Memory Management

- Efficient streaming parser for large playlists
- Memory-mapped file operations
- Automatic cleanup of temporary files

## Testing

Run the test suite:

```bash
swift test
```

The project includes comprehensive tests for:
- Download functionality
- Parsing accuracy
- Error handling
- Performance optimization
- Integration scenarios

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
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
```

## License

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

## Support

- **Issues**: [GitHub Issues](https://github.com/ftitreefly/TFM3U8Utility2/issues)
- **Documentation**: [API Documentation](https://ftitreefly.github.io/TFM3U8Utility2)
- **Discussions**: [GitHub Discussions](https://github.com/ftitreefly/TFM3U8Utility2/discussions)

## Changelog

### Version 1.0.0
- Initial release
- Swift 6+ support
- High-performance M3U8 processing
- CLI tool with download and info commands
- Comprehensive error handling
- Dependency injection architecture
