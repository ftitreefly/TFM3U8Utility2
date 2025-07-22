# TFM3U8Utility2 API 参考文档

## 概述

本文档提供了 TFM3U8Utility2 库的完整 API 参考，包含所有公共接口、类型和方法的详细说明。

## 核心 API

### TFM3U8Utility

主要的公共 API 接口，提供高级的 M3U8 处理功能。

#### 初始化

```swift
@MainActor public static func initialize(with configuration: DIConfiguration = DIConfiguration.performanceOptimized())
```

**描述**: 初始化依赖注入容器并配置服务。

**参数**:
- `configuration`: 依赖注入配置对象，默认为性能优化配置

**示例**:
```swift
// 使用默认配置
await TFM3U8Utility.initialize()

// 使用自定义配置
let config = DIConfiguration()
config.maxConcurrentDownloads = 10
await TFM3U8Utility.initialize(with: config)
```

#### 下载功能

```swift
public static func download(
    _ method: Method = .web,
    url: URL,
    savedDirectory: String = "\(NSHomeDirectory())/Downloads/",
    name: String? = nil,
    configuration: DIConfiguration = DIConfiguration.performanceOptimized(),
    verbose: Bool = false
) async throws
```

**描述**: 下载 M3U8 内容并处理所有相关的视频片段。

**参数**:
- `method`: 下载方法，支持 `.web`（网络）和 `.local`（本地文件）
- `url`: 要下载的 M3U8 文件 URL
- `savedDirectory`: 保存目录路径，默认为用户下载文件夹
- `name`: 自定义输出文件名，可选
- `configuration`: 下载配置
- `verbose`: 是否启用详细输出

**抛出**:
- `FileSystemError.failedToCreateDirectory`: 目录创建失败
- `NetworkError`: 网络请求失败
- `ParsingError`: M3U8 解析失败
- `ProcessingError`: 任务创建失败

**示例**:
```swift
do {
    try await TFM3U8Utility.download(
        .web,
        url: URL(string: "https://example.com/video.m3u8")!,
        savedDirectory: "/Users/username/Downloads/videos/",
        name: "my-video",
        verbose: true
    )
    print("下载完成")
} catch {
    print("下载失败: \(error)")
}
```

#### 解析功能

```swift
public static func parse(
    url: URL,
    method: Method = .web,
    configuration: DIConfiguration = DIConfiguration.performanceOptimized()
) async throws -> M3U8Parser.ParserResult
```

**描述**: 解析 M3U8 文件并返回结构化的播放列表数据。

**参数**:
- `url`: 要解析的 M3U8 文件 URL
- `method`: 解析方法，支持 `.web` 和 `.local`
- `configuration`: 解析配置

**返回值**: `M3U8Parser.ParserResult` - 解析结果，包含主播放列表或媒体播放列表

**抛出**:
- `ParsingError`: M3U8 内容解析失败
- `NetworkError`: 网络请求失败
- `FileSystemError.failedToReadFromFile`: 本地文件读取失败

**示例**:
```swift
do {
    let result = try await TFM3U8Utility.parse(
        url: URL(string: "https://example.com/video.m3u8")!
    )
    
    switch result {
    case .master(let masterPlaylist):
        print("主播放列表，包含 \(masterPlaylist.tags.streamTags.count) 个流")
        for stream in masterPlaylist.tags.streamTags {
            print("流: \(stream.uri), 带宽: \(stream.bandwidth)")
        }
    case .media(let mediaPlaylist):
        print("媒体播放列表，包含 \(mediaPlaylist.tags.mediaSegments.count) 个片段")
        for segment in mediaPlaylist.tags.mediaSegments {
            print("片段: \(segment.uri), 时长: \(segment.duration)")
        }
    case .cancelled:
        print("解析被取消")
    }
} catch {
    print("解析失败: \(error)")
}
```

## 配置 API

### DIConfiguration

配置依赖注入和服务行为的结构体。

#### 属性

```swift
public struct DIConfiguration: Sendable {
    /// FFmpeg 可执行文件路径
    public let ffmpegPath: String?
    
    /// curl 可执行文件路径
    public let curlPath: String?
    
    /// 默认 HTTP 请求头
    public let defaultHeaders: [String: String]
    
    /// 最大并发下载数
    public let maxConcurrentDownloads: Int
    
    /// 下载超时时间（秒）
    public let downloadTimeout: TimeInterval
}
```

#### 初始化方法

```swift
public init(
    ffmpegPath: String? = nil,
    curlPath: String? = nil,
    defaultHeaders: [String: String] = ["User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"],
    maxConcurrentDownloads: Int = 16,
    downloadTimeout: TimeInterval = 300
)
```

**参数**:
- `ffmpegPath`: FFmpeg 可执行文件路径，可选
- `curlPath`: curl 可执行文件路径，可选
- `defaultHeaders`: 默认 HTTP 请求头，默认为标准浏览器请求头
- `maxConcurrentDownloads`: 最大并发下载数，默认 16
- `downloadTimeout`: 下载超时时间，默认 300 秒

#### 预定义配置

```swift
public static func performanceOptimized() -> DIConfiguration
```

**描述**: 返回性能优化的预定义配置。

**配置详情**:
- FFmpeg 路径: `/opt/homebrew/bin/ffmpeg`
- curl 路径: `/usr/bin/curl`
- 并发下载数: 20
- 超时时间: 60 秒
- 请求头: 完整的浏览器兼容请求头

**示例**:
```swift
let config = DIConfiguration.performanceOptimized()
await TFM3U8Utility.initialize(with: config)
```

## 类型定义

### Method

下载和解析方法的枚举。

```swift
public enum Method {
    case web
    case local
}
```

**用例**:
- `.web`: 用于网络 URL 的下载和解析
- `.local`: 用于本地文件的处理

### M3U8Parser.ParserResult

M3U8 解析结果的联合类型。

```swift
public enum ParserResult {
    case master(MasterPlaylist)
    case media(MediaPlaylist)
    case cancelled
}
```

**用例**:
- `.master(MasterPlaylist)`: 主播放列表，包含多个流
- `.media(MediaPlaylist)`: 媒体播放列表，包含视频片段
- `.cancelled`: 解析被取消

## 错误类型

### NetworkError

网络相关错误。

```swift
public enum NetworkError: Error, LocalizedError {
    case invalidURL(String)
    case requestFailed(Error)
    case timeout(TimeInterval)
    case invalidResponse(Int)
}
```

**错误类型**:
- `invalidURL(String)`: URL 格式无效
- `requestFailed(Error)`: 网络请求失败
- `timeout(TimeInterval)`: 请求超时
- `invalidResponse(Int)`: 无效的 HTTP 响应

### ParsingError

M3U8 解析错误。

```swift
public struct ParsingError: Error, LocalizedError {
    public let code: Int
    public let underlyingError: Error?
    public let message: String
    public let context: String
}
```

**属性**:
- `code`: 错误代码
- `underlyingError`: 底层错误
- `message`: 错误消息
- `context`: 错误上下文

### FileSystemError

文件系统操作错误。

```swift
public enum FileSystemError: Error, LocalizedError {
    case failedToCreateDirectory(String)
    case failedToReadFromFile(String)
    case failedToWriteToFile(String)
    case fileNotFound(String)
}
```

**错误类型**:
- `failedToCreateDirectory(String)`: 目录创建失败
- `failedToReadFromFile(String)`: 文件读取失败
- `failedToWriteToFile(String)`: 文件写入失败
- `fileNotFound(String)`: 文件未找到

### ProcessingError

视频处理错误。

```swift
public enum ProcessingError: Error, LocalizedError {
    case ffmpegNotFound
    case ffmpegExecutionFailed(String)
    case invalidVideoFormat(String)
}
```

**错误类型**:
- `ffmpegNotFound`: FFmpeg 未找到
- `ffmpegExecutionFailed(String)`: FFmpeg 执行失败
- `invalidVideoFormat(String)`: 无效的视频格式

## 服务协议

### M3U8DownloaderProtocol

M3U8 内容下载协议。

```swift
public protocol M3U8DownloaderProtocol: Sendable {
    func downloadContent(from url: URL) async throws -> String
}
```

**方法**:
- `downloadContent(from:)`: 从指定 URL 下载内容

### M3U8ParserServiceProtocol

M3U8 解析服务协议。

```swift
public protocol M3U8ParserServiceProtocol: Sendable {
    func parseContent(_ content: String, baseURL: URL, type: M3U8Parser.PlaylistType) throws -> M3U8Parser.ParserResult
}
```

**方法**:
- `parseContent(_:baseURL:type:)`: 解析 M3U8 内容

### VideoProcessorProtocol

视频处理协议。

```swift
public protocol VideoProcessorProtocol: Sendable {
    func combineSegments(_ segments: [String], outputPath: String) async throws
}
```

**方法**:
- `combineSegments(_:outputPath:)`: 合并视频片段

### TaskRequest

任务请求参数结构体。

```swift
public struct TaskRequest: Sendable {
    public let url: URL
    public let baseUrl: URL?
    public let savedDirectory: String
    public let fileName: String?
    public let method: Method
    public let verbose: Bool
    
    public init(
        url: URL,
        baseUrl: URL? = nil,
        savedDirectory: String,
        fileName: String? = nil,
        method: Method,
        verbose: Bool = false
    )
}
```

**参数**:
- `url`: 要下载的 M3U8 文件 URL
- `baseUrl`: 解析相对 URL 的可选基础 URL
- `savedDirectory`: 最终视频文件保存目录
- `fileName`: 输出视频的自定义文件名（可选）
- `method`: 下载方法（web 或 local）
- `verbose`: 是否输出详细信息

### TaskManagerProtocol

任务管理协议。

```swift
public protocol TaskManagerProtocol: Sendable {
    func createTask(_ request: TaskRequest) async throws
    func getTaskStatus(for taskId: String) async -> TaskStatus?
    func cancelTask(taskId: String) async throws
}
```

**方法**:
- `createTask(_:)`: 创建下载任务
- `getTaskStatus(for:)`: 获取任务状态
- `cancelTask(taskId:)`: 取消任务

### FileSystemServiceProtocol

文件系统服务协议。

```swift
public protocol FileSystemServiceProtocol: Sendable {
    func fileExists(at path: String) -> Bool
    func createDirectory(at path: String, withIntermediateDirectories: Bool) throws
    func write(_ data: Data, to path: String) throws
    func read(from path: String) throws -> Data
}
```

**方法**:
- `fileExists(at:)`: 检查文件是否存在
- `createDirectory(at:withIntermediateDirectories:)`: 创建目录
- `write(_:to:)`: 写入数据到文件
- `read(from:)`: 从文件读取数据

### CommandExecutorProtocol

外部命令执行协议。

```swift
public protocol CommandExecutorProtocol: Sendable {
    func execute(_ command: String, arguments: [String]) async throws -> String
}
```

**方法**:
- `execute(_:arguments:)`: 执行外部命令

## 工具函数

### vprintf

调试输出函数。

```swift
public func vprintf(_ verbose: Bool, _ format: String, _ arguments: CVarArg...)
```

**描述**: 根据 verbose 标志输出调试信息。

**参数**:
- `verbose`: 是否启用详细输出
- `format`: 格式化字符串
- `arguments`: 格式化参数

**示例**:
```swift
vprintf(verbose, "下载进度: %d%%", progress)
```

## 扩展方法

### Array 扩展

```swift
extension Array where Element == String {
    func chunked(into size: Int) -> [[Element]]
}
```

**方法**:
- `chunked(into:)`: 将数组分块

### String 扩展

```swift
extension String {
    func isURL() -> Bool
    func isLocalPath() -> Bool
}
```

**方法**:
- `isURL()`: 检查字符串是否为有效 URL
- `isLocalPath()`: 检查字符串是否为本地路径

## 使用示例

### 基本下载示例

```swift
import TFM3U8Utility

@main
struct MyApp {
    static func main() async {
        // 初始化
        await TFM3U8Utility.initialize()
        
        // 下载视频
        do {
            try await TFM3U8Utility.download(
                .web,
                url: URL(string: "https://example.com/video.m3u8")!,
                savedDirectory: "/Users/username/Downloads/",
                name: "my-video",
                verbose: true
            )
            print("下载完成")
        } catch {
            print("下载失败: \(error)")
        }
    }
}
```

### 高级配置示例

```swift
import TFM3U8Utility

@main
struct AdvancedApp {
    static func main() async {
        // 自定义配置
        let config = DIConfiguration(
            ffmpegPath: "/usr/local/bin/ffmpeg",
            curlPath: "/usr/bin/curl",
            defaultHeaders: [
                "User-Agent": "Custom User Agent",
                "Authorization": "Bearer token"
            ],
            maxConcurrentDownloads: 10,
            downloadTimeout: 120
        )
        
        // 初始化
        await TFM3U8Utility.initialize(with: config)
        
        // 解析播放列表
        do {
            let result = try await TFM3U8Utility.parse(
                url: URL(string: "https://example.com/playlist.m3u8")!
            )
            
            switch result {
            case .master(let masterPlaylist):
                print("主播放列表解析成功")
                for stream in masterPlaylist.tags.streamTags {
                    print("流: \(stream.uri)")
                }
            case .media(let mediaPlaylist):
                print("媒体播放列表解析成功")
                print("片段数量: \(mediaPlaylist.tags.mediaSegments.count)")
            case .cancelled:
                print("解析被取消")
            }
        } catch {
            print("解析失败: \(error)")
        }
    }
}
```

### 错误处理示例

```swift
import TFM3U8Utility

func downloadWithErrorHandling() async {
    do {
        try await TFM3U8Utility.download(.web, url: videoURL)
    } catch let error as FileSystemError {
        switch error {
        case .failedToCreateDirectory(let path):
            print("无法创建目录: \(path)")
        case .failedToReadFromFile(let path):
            print("无法读取文件: \(path)")
        case .failedToWriteToFile(let path):
            print("无法写入文件: \(path)")
        case .fileNotFound(let path):
            print("文件未找到: \(path)")
        }
    } catch let error as NetworkError {
        switch error {
        case .invalidURL(let url):
            print("无效的 URL: \(url)")
        case .requestFailed(let underlyingError):
            print("请求失败: \(underlyingError)")
        case .timeout(let timeout):
            print("请求超时: \(timeout) 秒")
        case .invalidResponse(let statusCode):
            print("无效响应: \(statusCode)")
        }
    } catch let error as ParsingError {
        print("解析错误: \(error.message)")
        print("错误代码: \(error.code)")
        print("上下文: \(error.context)")
    } catch let error as ProcessingError {
        switch error {
        case .ffmpegNotFound:
            print("FFmpeg 未找到，请安装 FFmpeg")
        case .ffmpegExecutionFailed(let command):
            print("FFmpeg 执行失败: \(command)")
        case .invalidVideoFormat(let format):
            print("无效的视频格式: \(format)")
        }
    } catch {
        print("未知错误: \(error)")
    }
}
```

## 版本兼容性

### Swift 版本要求

- **最低版本**: Swift 6.0
- **推荐版本**: Swift 6.0 或更高版本

### 平台支持

- **macOS**: 12.0 或更高版本
- **架构**: Intel 和 Apple Silicon

### 依赖项

- **ArgumentParser**: 1.0.0 或更高版本（仅 CLI 工具需要）

---

*API 参考文档最后更新于 2025年7月* 