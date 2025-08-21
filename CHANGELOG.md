# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.3] - 2025-08-22

### Added
- Enhanced dependency injection architecture with improved service registration
- Better error handling and logging throughout the codebase
- Improved test coverage and performance optimizations
- Enhanced CLI command structure and user experience

### Changed
- Refactored dependency injection container for better modularity
- Improved service protocol definitions and implementations
- Enhanced error handling with more specific error types
- Optimized task management and download performance
- Enhanced URL validation in DownloadCommand and ExtractCommand
- Improved error handling with detailed error messages and codes

### Deprecated
- N/A

### Removed
- N/A

### Fixed
- Various code quality improvements and bug fixes
- Enhanced test stability and performance
- Improved thread safety in logging system

### Security
- N/A

## [1.3.2] - 2025-01-27

## [Unreleased]

### Added
- N/A

### Changed
- N/A

### Deprecated
- N/A

### Removed
- N/A

### Fixed
- N/A

### Security
- N/A

## [1.3.1] - 2025-01-27

### Added
- Enhanced YouTube M3U8 link extractor with improved error handling
- Simplified ExtractCommand structure for better maintainability
- Optimized YouTubeExtractor demo implementation
- Enhanced command structures with dynamic versioning support

### Changed
- Refactored ExtractCommand for clarity and demonstration purposes
- Improved command structure architecture for better extensibility
- Enhanced extractor capabilities with better error handling
- Streamlined YouTubeExtractor implementation

### Deprecated
- N/A

### Removed
- N/A

### Fixed
- N/A

### Security
- N/A

## [1.3.0] - 2025-01-27

### Added
- YouTube M3U8 link extractor for extracting streaming links from YouTube pages
- Third-party integration support for extracting M3U8 links from web pages
- Reusable URLSession implementation for enhanced M3U8 link extraction
- M3U8 link extraction registry system for managing multiple extractors
- Enhanced CLI extract command with comprehensive extraction options
- Support for multiple extraction methods (direct-links, javascript-variables, api-endpoints)
- Custom User-Agent and HTTP header support for extraction requests
- JavaScript execution support for dynamic content extraction
- Output format options (text, json, csv) for extracted links

### Changed
- Improved M3U8 link extraction architecture with plugin-style extractors
- Enhanced CLI extract command with better error handling and progress reporting
- Updated dependency injection to support extractor services
- Improved network request handling with reusable URLSession instances

### Deprecated
- N/A

### Removed
- N/A

### Fixed
- N/A

### Security
- N/A

## [1.2.0] - 2025-07-28

### Added
- Performance optimization features for task management
- Streamlined state handling in OptimizedTaskManager
- Enhanced architecture documentation

### Changed
- Optimized task state management with minimal overhead
- Removed unused progress callback functionality
- Streamlined intermediate state updates for better performance
- Improved concurrent task execution efficiency
- Enhanced logging integration throughout the codebase
- Better separation of concerns in task management components

### Deprecated
- N/A

### Removed
- Unused progress callback field from TaskInfo struct
- Intermediate state updates in executeTaskWithMetrics method
- Unnecessary status updates in processMediaPlaylistOptimized method
- Progress callback examples from documentation

### Fixed
- Task state synchronization issues
- Memory overhead from unused state tracking
- Performance bottlenecks in task management

### Security
- N/A

## [1.1.0] - 2025-07-25

### Added
- Advanced logging system with multiple levels and categories
- Comprehensive logging configuration with production, development, and verbose modes
- Log categories for better organization (Network, FileSystem, Parsing, Processing, etc.)
- Colored output support for better readability
- Timestamp and emoji support in log messages
- Thread-safe logging operations using Swift 6 concurrency
- Legacy compatibility with existing vprintf function
- Detailed logging documentation and usage examples

### Changed
- Updated debug information handling to use new Logger system
- Enhanced verbose output mode with structured logging
- Improved CLI output formatting with categorized log messages
- Refactored logging integration throughout the codebase

### Deprecated
- N/A

### Removed
- N/A

### Fixed
- Build system cache issues with missing LoggingExample.swift file
- Logger configuration integration in TFM3U8Utility.download method

### Security
- N/A

## [1.0.0] - 2025-07-21

### Added
- Initial release
- Swift 6+ support
- High-performance M3U8 processing
- CLI tool with download and info commands
- Comprehensive error handling
- Dependency injection architecture
- Cross-platform macOS support
- Concurrent download support
- Video processing with FFmpeg
- Encryption support for M3U8 streams 