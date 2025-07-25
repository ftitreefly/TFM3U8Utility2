# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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