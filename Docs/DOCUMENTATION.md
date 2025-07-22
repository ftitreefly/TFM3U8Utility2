# TFM3U8Utility2 项目文档

## 项目概述

TFM3U8Utility2 是一个高性能的 Swift 库和命令行工具，专门用于下载、解析和处理 M3U8 视频文件。该项目采用 Swift 6+ 的现代并发特性，使用依赖注入架构，提供模块化和可测试的代码结构。

### 主要特性

- 🚀 **高性能**: 使用 Swift 6 并发特性优化性能
- 🔧 **依赖注入**: 完整的依赖注入架构支持
- 📱 **跨平台**: 支持 macOS 12.0+，提供 CLI 和库接口
- 🛡️ **错误处理**: 全面的错误处理机制，详细的错误类型
- 🔄 **并发下载**: 可配置的并发下载支持
- 📊 **进度跟踪**: 实时进度监控和状态更新
- 🎯 **多源支持**: 支持网络 URL 和本地文件
- 🎬 **视频处理**: 集成 FFmpeg 进行视频片段合并
- 🔐 **加密支持**: 内置加密 M3U8 流支持

## 系统要求

- **操作系统**: macOS 12.0 或更高版本
- **Swift**: 6.0 或更高版本
- **Xcode**: 15.0 或更高版本（开发用）
- **外部依赖**: FFmpeg（推荐安装）

## 安装指南

### 1. 克隆项目

```bash
git clone https://github.com/ftitreefly/TFM3U8Utility2.git
cd TFM3U8Utility2
```

### 2. 安装外部依赖

```bash
# 安装 FFmpeg（用于视频处理）
brew install ffmpeg

# 验证安装
ffmpeg -version
```

### 3. 构建项目

```bash
# 构建库和可执行文件
swift build

# 运行测试
swift test

# 构建发布版本
swift build -c release
```

### 4. 安装 CLI 工具

```bash
# 构建并安装到系统路径
swift build -c release
cp .build/release/m3u8-utility /usr/local/bin/

# 验证安装
m3u8-utility --help
```

## 项目架构

### 目录结构

```
TFM3U8Utility2/
├── Package.swift                 # Swift Package Manager 配置
├── README.md                     # 项目说明
├── Docs/DOCUMENTATION.md         # 详细文档（本文件）
├── Sources/
│   ├── TFM3U8Utility/            # 核心库
│   │   ├── TFM3U8Utility.swift   # 主公共 API
│   │   ├── Core/                 # 核心组件
│   │   │   ├── DependencyInjection/  # 依赖注入
│   │   │   ├── Parsers/          # M3U8 解析器
│   │   │   ├── Protocols/        # 协议定义
│   │   │   └── Types/            # 类型定义
│   │   ├── Services/             # 服务实现
│   │   │   ├── Default/          # 默认服务实现
│   │   │   └── Optimized/        # 优化服务实现
│   │   └── Utilities/            # 工具类
│   │       ├── Debug.swift       # 调试工具
│   │       ├── Errors/           # 错误处理
│   │       └── Extensions/       # 扩展方法
│   └── M3U8CLI/                  # 命令行工具
│       ├── Main.swift            # CLI 入口
│       ├── DownloadCommand.swift # 下载命令
│       └── InfoCommand.swift     # 信息命令
├── Tests/                        # 测试代码
│   └── TFM3U8UtilityTests/       # 单元测试
└── Scripts/                      # 构建和测试脚本
```

### 核心组件

#### 1. TFM3U8Utility (主公共 API)
- **文件**: `Sources/TFM3U8Utility/TFM3U8Utility.swift`
- **功能**: 提供高级 API 接口，封装复杂的下载和解析逻辑
- **主要方法**:
  - `initialize(with:)`: 初始化依赖注入容器
  - `download(_:url:savedDirectory:name:configuration:verbose:)`: 下载 M3U8 内容
  - `parse(url:method:configuration:)`: 解析 M3U8 文件

#### 2. 依赖注入系统
- **文件**: `Sources/TFM3U8Utility/Core/DependencyInjection/`
- **组件**:
  - `DependencyContainer.swift`: 依赖容器实现
  - `DependencyInjection.swift`: 依赖注入协议
  - `DIConfiguration.swift`: 配置管理
- **功能**: 提供模块化和可测试的架构

#### 3. M3U8 解析器
- **文件**: `Sources/TFM3U8Utility/Core/Parsers/M3U8Parser/`
- **组件**:
  - `M3U8Parser.swift`: 主解析器
  - `Models/`: 数据模型
    - `Playlist/`: 播放列表模型
    - `Tags/`: 标签模型
- **功能**: 高性能解析 M3U8 播放列表

#### 4. 服务层
- **文件**: `Sources/TFM3U8Utility/Services/`
- **组件**:
  - `Default/`: 默认服务实现
  - `Optimized/`: 优化服务实现
- **服务类型**:
  - `M3U8DownloaderProtocol`: 内容下载
  - `M3U8ParserServiceProtocol`: 播放列表解析
  - `VideoProcessorProtocol`: 视频处理
  - `TaskManagerProtocol`: 任务协调
  - `FileSystemServiceProtocol`: 文件操作
  - `CommandExecutorProtocol`: 外部命令执行

## API 参考

### 核心 API

#### TFM3U8Utility.initialize(with:)

初始化依赖注入容器。

```swift
@MainActor public static func initialize(with configuration: DIConfiguration = DIConfiguration.performanceOptimized())
```

**参数**:
- `configuration`: 依赖注入配置，默认为性能优化配置

**示例**:
```swift
// 使用默认配置
await TFM3U8Utility.initialize()

// 使用自定义配置
let config = DIConfiguration()
config.maxConcurrentDownloads = 10
await TFM3U8Utility.initialize(with: config)
```

#### TFM3U8Utility.download(_:url:savedDirectory:name:configuration:verbose:)

下载 M3U8 内容并处理。

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

**参数**:
- `method`: 下载方法 (`.web` 或 `.local`)
- `url`: 要下载的 URL
- `savedDirectory`: 保存目录，默认为用户下载文件夹
- `name`: 输出文件名（可选）
- `configuration`: 下载配置
- `verbose`: 是否输出详细信息

**示例**:
```swift
try await TFM3U8Utility.download(
    .web,
    url: URL(string: "https://example.com/video.m3u8")!,
    savedDirectory: "/Users/username/Downloads/videos/",
    name: "my-video",
    verbose: true
)
```

#### TFM3U8Utility.parse(url:method:configuration:)

解析 M3U8 文件并返回结构化数据。

```swift
public static func parse(
    url: URL,
    method: Method = .web,
    configuration: DIConfiguration = DIConfiguration.performanceOptimized()
) async throws -> M3U8Parser.ParserResult
```

**参数**:
- `url`: 要解析的 URL
- `method`: 解析方法 (`.web` 或 `.local`)
- `configuration`: 解析配置

**返回值**: `M3U8Parser.ParserResult` - 解析结果

**示例**:
```swift
let result = try await TFM3U8Utility.parse(
    url: URL(string: "https://example.com/video.m3u8")!
)

switch result {
case .master(let masterPlaylist):
    print("主播放列表，包含 \(masterPlaylist.tags.streamTags.count) 个流")
case .media(let mediaPlaylist):
    print("媒体播放列表，包含 \(mediaPlaylist.tags.mediaSegments.count) 个片段")
case .cancelled:
    print("解析被取消")
}
```

### 配置 API

#### DIConfiguration

配置依赖注入和服务行为。

```swift
public struct DIConfiguration: Sendable {
    public let ffmpegPath: String?
    public let curlPath: String?
    public let defaultHeaders: [String: String]
    public let maxConcurrentDownloads: Int
    public let downloadTimeout: TimeInterval
    
    public init(
        ffmpegPath: String? = nil,
        curlPath: String? = nil,
        defaultHeaders: [String: String] = ["User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"],
        maxConcurrentDownloads: Int = 16,
        downloadTimeout: TimeInterval = 300
    )
}
```

**预定义配置**:
```swift
// 性能优化配置
let config = DIConfiguration.performanceOptimized()
// 包含:
// - FFmpeg 路径: /opt/homebrew/bin/ffmpeg
// - curl 路径: /usr/bin/curl
// - 并发下载数: 20
// - 超时时间: 60 秒
// - 完整的浏览器请求头
```

## 命令行工具使用

### 基本命令

#### 下载命令

```bash
m3u8-utility download <URL> [选项]
```

**选项**:
- `--name, -n`: 自定义输出文件名
- `--verbose, -v`: 启用详细输出
- `--help, -h`: 显示帮助信息

**示例**:
```bash
# 基本下载
m3u8-utility download https://example.com/video.m3u8

# 自定义文件名下载
m3u8-utility download https://example.com/video.m3u8 --name my-video

# 详细输出下载
m3u8-utility download https://example.com/video.m3u8 -v
```

#### 信息命令

```bash
m3u8-utility info
```

显示工具信息、版本和可用功能。

### 高级用法

#### 批量下载

```bash
# 使用脚本批量下载
for url in $(cat urls.txt); do
    m3u8-utility download "$url" --name "$(basename $url .m3u8)"
done
```

#### 自定义配置

```bash
# 设置环境变量
export FFMPEG_PATH="/custom/path/ffmpeg"
export CURL_PATH="/custom/path/curl"

# 运行下载
m3u8-utility download https://example.com/video.m3u8
```

## 错误处理

### 错误类型

项目定义了完整的错误类型体系：

#### NetworkError
网络相关错误
```swift
public enum NetworkError: Error, LocalizedError {
    case invalidURL(String)
    case requestFailed(Error)
    case timeout(TimeInterval)
    case invalidResponse(Int)
}
```

#### ParsingError
M3U8 解析错误
```swift
public struct ParsingError: Error, LocalizedError {
    public let code: Int
    public let underlyingError: Error?
    public let message: String
    public let context: String
}
```

#### FileSystemError
文件系统操作错误
```swift
public enum FileSystemError: Error, LocalizedError {
    case failedToCreateDirectory(String)
    case failedToReadFromFile(String)
    case failedToWriteToFile(String)
    case fileNotFound(String)
}
```

#### ProcessingError
视频处理错误
```swift
public enum ProcessingError: Error, LocalizedError {
    case ffmpegNotFound
    case ffmpegExecutionFailed(String)
    case invalidVideoFormat(String)
}
```

### 错误处理示例

```swift
do {
    try await TFM3U8Utility.download(.web, url: videoURL)
} catch let error as FileSystemError {
    print("文件系统错误: \(error.localizedDescription)")
} catch let error as NetworkError {
    print("网络错误: \(error.localizedDescription)")
} catch let error as ParsingError {
    print("解析错误: \(error.message)")
    print("错误代码: \(error.code)")
    print("上下文: \(error.context)")
} catch let error as ProcessingError {
    print("处理错误: \(error.localizedDescription)")
} catch {
    print("未知错误: \(error)")
}
```

## 性能优化

### 并发下载

项目支持可配置的并发下载：

```swift
let config = DIConfiguration.performanceOptimized()
config.maxConcurrentDownloads = 20  // 根据需求调整
```

### 内存管理

- 高效的流式解析器，适用于大型播放列表
- 内存映射文件操作
- 自动清理临时文件

### 硬件加速

视频处理自动检测并使用可用的硬件加速。

## 测试

### 运行测试

```bash
# 运行所有测试
swift test

# 运行特定测试
swift test --filter DownloadTests

# 运行性能测试
swift test --filter PerformanceOptimizedTests
```

### 测试覆盖

项目包含全面的测试套件：

- **DownloadTests**: 下载功能测试
- **ParseTests**: 解析准确性测试
- **NetworkTests**: 网络功能测试
- **IntegrationTests**: 集成测试
- **PerformanceOptimizedTests**: 性能优化测试
- **TaskManagerTests**: 任务管理测试
- **CombineTests**: 组合功能测试

### 测试数据

测试使用真实的 M3U8 文件和 TS 片段进行验证。

## 开发指南

### 开发环境设置

```bash
# 克隆项目
git clone https://github.com/ftitreefly/TFM3U8Utility2.git
cd TFM3U8Utility2

# 安装依赖
swift package resolve

# 构建项目
swift build

# 运行测试
swift test

# 构建并运行 CLI
swift run m3u8-utility --help
```

### 代码规范

- 使用 Swift 6+ 语法
- 遵循 Swift API 设计指南
- 使用 `StrictConcurrency` 实验性特性
- 完整的文档注释
- 全面的错误处理

### 贡献指南

1. Fork 项目
2. 创建功能分支
3. 实现功能
4. 添加测试
5. 确保所有测试通过
6. 提交 Pull Request

### 发布流程

```bash
# 更新版本号
# 编辑 Package.swift 中的版本

# 构建发布版本
swift build -c release

# 运行测试
swift test

# 创建标签
git tag v1.0.0
git push origin v1.0.0
```

## 故障排除

### 常见问题

#### 1. FFmpeg 未找到

**错误**: `ProcessingError.ffmpegNotFound`

**解决方案**:
```bash
# 安装 FFmpeg
brew install ffmpeg

# 验证安装
which ffmpeg
ffmpeg -version
```

#### 2. 网络超时

**错误**: `NetworkError.timeout`

**解决方案**:
```swift
// 增加超时时间
let config = DIConfiguration()
config.downloadTimeout = 300  // 5 分钟
```

#### 3. 并发下载失败

**错误**: 下载速度慢或失败

**解决方案**:
```swift
// 减少并发数
let config = DIConfiguration()
config.maxConcurrentDownloads = 5
```

#### 4. 权限问题

**错误**: `FileSystemError.failedToCreateDirectory`

**解决方案**:
```bash
# 检查目录权限
ls -la /path/to/directory

# 创建目录
mkdir -p /path/to/directory
chmod 755 /path/to/directory
```

### 调试模式

启用详细输出进行调试：

```swift
// 在代码中
try await TFM3U8Utility.download(
    .web,
    url: videoURL,
    verbose: true
)

// 在命令行中
m3u8-utility download https://example.com/video.m3u8 -v
```

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

## 支持

- **问题报告**: [GitHub Issues](https://github.com/ftitreefly/TFM3U8Utility2/issues)
- **讨论**: [GitHub Discussions](https://github.com/ftitreefly/TFM3U8Utility2/discussions)
- **文档**: [API 文档](https://ftitreefly.github.io/TFM3U8Utility2)

## 更新日志

### 版本 1.0.0
- 初始发布
- Swift 6+ 支持
- 高性能 M3U8 处理
- CLI 工具，包含下载和信息命令
- 全面的错误处理
- 依赖注入架构
- 并发下载支持
- FFmpeg 集成
- 完整的测试套件

---

*本文档最后更新于 2025年7月* 