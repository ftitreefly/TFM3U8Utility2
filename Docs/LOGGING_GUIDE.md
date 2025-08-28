# TFM3U8Utility2 日志系统使用指南

## 概述

TFM3U8Utility2 提供了一个统一的日志管理系统，用于优雅地控制应用程序中的日志输出。这个系统支持多种日志级别、分类、时间戳和彩色输出。

## 特性

- **多级日志**: 支持 none、error、info、debug、verbose、trace 六个级别
- **分类日志**: 按功能模块分类（网络、文件系统、解析等）
- **可配置输出**: 支持时间戳、分类信息、emoji 和彩色输出
- **线程安全**: 使用 Swift 6 并发特性确保线程安全
- **向后兼容**: 保持与现有 vprintf 函数的兼容性

## 日志级别

### LogLevel

```swift
public enum LogLevel: Int, CaseIterable, Comparable, Sendable {
    case none = 0      // 无日志输出
    case error = 1     // 仅关键错误和警告
    case info = 2      // 重要信息和错误
    case debug = 3     // 详细调试信息
    case verbose = 4   // 非常详细的调试信息
    case trace = 5     // 所有可能的信息，包括跟踪数据
}
```

### 日志分类

```swift
public enum LogCategory: String, CaseIterable {
    case general = "General"       // 📋 通用信息
    case network = "Network"       // 🌐 网络相关
    case fileSystem = "FileSystem" // 📁 文件系统操作
    case parsing = "Parsing"       // 📝 解析操作
    case processing = "Processing" // ⚙️ 处理操作
    case taskManager = "TaskManager" // 🎯 任务管理
    case download = "Download"     // ⬇️ 下载操作
    case cli = "CLI"              // 💻 命令行界面
}
```

## 配置

### LoggerConfiguration

```swift
public struct LoggerConfiguration: Sendable {
    public let minimumLevel: LogLevel        // 最小日志级别
    public let includeTimestamps: Bool       // 是否包含时间戳
    public let includeCategories: Bool       // 是否包含分类信息
    public let includeEmoji: Bool           // 是否包含 emoji
    public let enableColors: Bool           // 是否启用彩色输出
}
```

### 预设配置

```swift
// 生产环境配置 - 只显示错误信息
Logger.configure(.production())

// 开发环境配置 - 显示调试信息
Logger.configure(.development())

// 详细调试配置 - 显示所有信息
Logger.configure(.verbose())

// 自定义配置
let customConfig = LoggerConfiguration(
    minimumLevel: .debug,
    includeTimestamps: true,
    includeCategories: true,
    includeEmoji: false,
    enableColors: true
)
Logger.configure(customConfig)
```

## 使用方法

### 基本日志记录

```swift
import TFM3U8Utility

// 配置日志系统
Logger.configure(.development())

// 不同级别的日志
Logger.error("网络连接失败", category: .network)
Logger.info("开始下载文件", category: .download)
Logger.debug("解析 M3U8 内容", category: .parsing)
Logger.verbose("详细的调试信息", category: .processing)
Logger.trace("函数调用跟踪", category: .general)

// 特殊格式的日志
Logger.success("下载完成！", category: .download)
Logger.warning("文件已存在，将重命名", category: .fileSystem)
Logger.progress("下载进度: 75%", category: .download)
```

### 在任务管理器中使用

```swift
// 在 DefaultTaskManager 中
Logger.debug("当前活动任务: \(activeTasksCount)/\(maxConcurrentTasks)", category: .taskManager)
Logger.info("创建临时目录: \(tempDir.path)", category: .fileSystem)
Logger.progress("已处理: \(formatBytes(totalBytes)) 数据", category: .download)
Logger.success("文件已保存: \(outputPath.path)", category: .fileSystem)
```

### 在 CLI 命令中使用

```swift
// 在 DownloadCommand 中
Logger.info("开始下载 M3U8 文件...", category: .cli)
Logger.success("下载完成！", category: .cli)
Logger.error("下载失败: \(error.localizedDescription)", category: .cli)
```

### 向后兼容性

```swift
// 使用现有的 vprintf 函数（自动使用新的日志系统）
vprintf(verbose, "调试信息")
vprintf(verbose, tab: 2, "缩进的调试信息")

// 初始化日志系统
initializeLogger(verbose: true)  // 使用详细配置
initializeLogger(verbose: false) // 使用生产配置
```

## 输出示例

### 开发环境输出

```
14:30:25.123 [INFO] [📋General] 应用程序启动
14:30:25.124 [DEBUG] [🌐Network] 开始下载: https://example.com/video.m3u8
14:30:25.125 [INFO] [📊Download] 下载进度: 25%
14:30:25.126 [SUCCESS] [📁FileSystem] 文件已保存: /Users/user/Downloads/video.mp4
```

### 生产环境输出

```
14:30:25.123 [ERROR] [Network] 网络连接失败: 连接超时
14:30:25.124 [INFO] [FileSystem] 文件已保存: /Users/user/Downloads/video.mp4
```

### 详细调试输出

```
14:30:25.123 [TRACE] [📋General] 函数调用跟踪 (DownloadCommand.swift:45)
14:30:25.124 [VERBOSE] [🌐Network] 详细的网络请求信息
14:30:25.125 [DEBUG] [📝Parsing] 解析 M3U8 内容 (M3U8Parser.swift:123)
```

## 最佳实践

### 1. 选择合适的日志级别

- **error**: 仅用于错误和异常情况
- **info**: 用于重要的状态变化和用户可见的信息
- **debug**: 用于开发调试信息
- **verbose**: 用于详细的调试信息
- **trace**: 用于函数调用跟踪和性能分析

### 2. 使用适当的分类

```swift
// 好的做法
Logger.error("网络请求失败", category: .network)
Logger.info("文件保存成功", category: .fileSystem)
Logger.debug("解析完成", category: .parsing)

// 避免的做法
Logger.error("错误")  // 没有分类
Logger.info("信息", category: .general)  // 过度使用 general 分类
```

### 3. 配置管理

```swift
// 在应用程序启动时配置
func applicationDidFinishLaunching() {
    #if DEBUG
    Logger.configure(.development())
    #else
    Logger.configure(.production())
    #endif
}

// 根据命令行参数配置
if verbose {
    Logger.configure(.verbose())
} else {
    Logger.configure(.production())
}
```

### 4. 性能考虑

- 日志系统使用异步队列，不会阻塞主线程
- 在生产环境中，建议使用 `.production()` 配置以减少输出
- 避免在循环中频繁记录详细日志

## 迁移指南

### 从 print 迁移

```swift
// 旧代码
print("下载完成")

// 新代码
Logger.success("下载完成", category: .download)
```

## 故障排除

### 常见问题

1. **日志不显示**
   - 检查日志级别配置
   - 确保 Logger 已正确配置

2. **性能问题**
   - 在生产环境中使用 `.production()` 配置
   - 避免在热路径中记录详细日志

3. **颜色不显示**
   - 检查终端是否支持 ANSI 颜色
   - 确认 `enableColors` 设置为 true

### 调试技巧

```swift
// 临时启用详细日志
Logger.configure(.verbose())

// 检查当前配置
Logger.trace("当前日志配置", category: .general)

// 恢复生产配置
Logger.configure(.production())
```

## 总结

新的日志系统提供了：

1. **统一的接口**: 所有日志都通过 Logger 类处理
2. **灵活的配置**: 支持多种预设和自定义配置
3. **分类管理**: 按功能模块组织日志信息
4. **向后兼容**: 保持与现有代码的兼容性
5. **性能优化**: 异步处理，不阻塞主线程

通过使用这个日志系统，你可以更好地控制应用程序的日志输出，提高调试效率，并在生产环境中减少不必要的输出。 
