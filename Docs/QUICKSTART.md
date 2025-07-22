# TFM3U8Utility2 快速开始指南

## 5分钟快速上手

本指南将帮助您在5分钟内开始使用 TFM3U8Utility2 下载和处理 M3U8 视频文件。

## 前置要求

确保您的系统满足以下要求：

- macOS 12.0 或更高版本
- Swift 6.0 或更高版本
- FFmpeg（推荐安装）

### 安装 FFmpeg

```bash
# 使用 Homebrew 安装 FFmpeg
brew install ffmpeg

# 验证安装
ffmpeg -version
```

## 方式一：使用命令行工具（推荐新手）

### 1. 构建项目

```bash
# 克隆项目
git clone https://github.com/ftitreefly/TFM3U8Utility2.git
cd TFM3U8Utility2

# 构建项目
swift build -c release
```

### 2. 安装 CLI 工具

```bash
# 复制到系统路径
sudo cp .build/release/m3u8-utility /usr/local/bin/

# 验证安装
m3u8-utility --help
```

### 3. 下载第一个视频

```bash
# 基本下载
m3u8-utility download https://example.com/video.m3u8

# 自定义文件名下载
m3u8-utility download https://example.com/video.m3u8 --name my-video

# 详细输出下载
m3u8-utility download https://example.com/video.m3u8 -v
```

### 4. 查看工具信息

```bash
m3u8-utility info
```

## 方式二：在 Swift 项目中使用

### 1. 添加依赖

在您的 `Package.swift` 中添加依赖：

```swift
dependencies: [
    .package(url: "https://github.com/ftitreefly/TFM3U8Utility2.git", from: "1.0.0")
]
```

### 2. 基本使用示例

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
            print("✅ 下载完成！")
        } catch {
            print("❌ 下载失败: \(error)")
        }
    }
}
```

### 3. 解析播放列表

```swift
import TFM3U8Utility

@main
struct ParserApp {
    static func main() async {
        await TFM3U8Utility.initialize()
        
        do {
            let result = try await TFM3U8Utility.parse(
                url: URL(string: "https://example.com/playlist.m3u8")!
            )
            
            switch result {
            case .master(let masterPlaylist):
                print("📺 主播放列表")
                print("流数量: \(masterPlaylist.tags.streamTags.count)")
            case .media(let mediaPlaylist):
                print("🎬 媒体播放列表")
                print("片段数量: \(mediaPlaylist.tags.mediaSegments.count)")
            case .cancelled:
                print("❌ 解析被取消")
            }
        } catch {
            print("❌ 解析失败: \(error)")
        }
    }
}
```

## 常见使用场景

### 场景1：批量下载

```bash
# 创建 URL 列表文件
echo "https://example.com/video1.m3u8" > urls.txt
echo "https://example.com/video2.m3u8" >> urls.txt
echo "https://example.com/video3.m3u8" >> urls.txt

# 批量下载
while IFS= read -r url; do
    filename=$(basename "$url" .m3u8)
    m3u8-utility download "$url" --name "$filename"
done < urls.txt
```

### 场景2：自定义配置

```swift
import TFM3U8Utility

@main
struct CustomConfigApp {
    static func main() async {
        // 自定义配置
        let config = DIConfiguration(
            ffmpegPath: "/usr/local/bin/ffmpeg",
            maxConcurrentDownloads: 5,
            downloadTimeout: 120
        )
        
        // 初始化
        await TFM3U8Utility.initialize(with: config)
        
        // 下载
        try await TFM3U8Utility.download(
            .web,
            url: URL(string: "https://example.com/video.m3u8")!
        )
    }
}
```

### 场景3：错误处理

```swift
import TFM3U8Utility

func downloadWithErrorHandling() async {
    do {
        try await TFM3U8Utility.download(.web, url: videoURL)
    } catch let error as FileSystemError {
        print("📁 文件系统错误: \(error.localizedDescription)")
    } catch let error as NetworkError {
        print("🌐 网络错误: \(error.localizedDescription)")
    } catch let error as ParsingError {
        print("📝 解析错误: \(error.message)")
    } catch let error as ProcessingError {
        print("🎬 处理错误: \(error.localizedDescription)")
    } catch {
        print("❓ 未知错误: \(error)")
    }
}
```

## 性能优化建议

### 1. 调整并发数

```swift
let config = DIConfiguration.performanceOptimized()
config.maxConcurrentDownloads = 20  // 根据网络情况调整
```

### 2. 设置合适的超时

```swift
let config = DIConfiguration()
config.downloadTimeout = 60  // 60秒超时
```

### 3. 使用性能优化配置

```swift
// 使用预定义的性能优化配置
await TFM3U8Utility.initialize(with: DIConfiguration.performanceOptimized())
```

## 故障排除

### 问题1：FFmpeg 未找到

**错误信息**: `ProcessingError.ffmpegNotFound`

**解决方案**:
```bash
# 安装 FFmpeg
brew install ffmpeg

# 验证安装
which ffmpeg
```

### 问题2：权限错误

**错误信息**: `FileSystemError.failedToCreateDirectory`

**解决方案**:
```bash
# 检查目录权限
ls -la /path/to/directory

# 创建目录并设置权限
mkdir -p /path/to/directory
chmod 755 /path/to/directory
```

### 问题3：网络超时

**错误信息**: `NetworkError.timeout`

**解决方案**:
```swift
// 增加超时时间
let config = DIConfiguration()
config.downloadTimeout = 300  // 5分钟
```

### 问题4：下载速度慢

**解决方案**:
```swift
// 减少并发数
let config = DIConfiguration()
config.maxConcurrentDownloads = 5
```

## 下一步

现在您已经成功开始使用 TFM3U8Utility2！接下来可以：

1. **阅读完整文档**: 查看 [DOCUMENTATION.md](DOCUMENTATION.md) 了解详细信息
2. **查看 API 参考**: 参考 [API_REFERENCE.md](API_REFERENCE.md) 了解所有可用接口
3. **运行测试**: 执行 `swift test` 验证功能
4. **贡献代码**: 查看 [CONTRIBUTING.md](CONTRIBUTING.md) 了解如何贡献

## 获取帮助

如果您遇到问题：

- 📖 查看 [故障排除](#故障排除) 部分
- 🐛 在 [GitHub Issues](https://github.com/ftitreefly/TFM3U8Utility2/issues) 报告问题
- 💬 在 [GitHub Discussions](https://github.com/ftitreefly/TFM3U8Utility2/discussions) 讨论

---

*快速开始指南最后更新于 2025年7月* 