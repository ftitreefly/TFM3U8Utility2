# 贡献指南

感谢您对 TFM3U8Utility2 项目的关注！我们欢迎所有形式的贡献，包括但不限于：

- 🐛 报告 Bug
- 💡 提出新功能建议
- 📝 改进文档
- 🔧 提交代码修复
- 🧪 添加测试用例

## 开发环境设置

### 1. 克隆项目

```bash
git clone https://github.com/ftitreefly/TFM3U8Utility2.git
cd TFM3U8Utility2
```

### 2. 安装依赖

```bash
# 安装 Swift 依赖
swift package resolve

# 安装外部工具（推荐）
brew install ffmpeg
```

### 3. 构建项目

```bash
# 构建项目
swift build

# 运行测试
swift test

# 构建发布版本
swift build -c release
```

### 4. 运行 CLI 工具

```bash
# 运行 CLI 工具
swift run m3u8-utility --help

# 测试下载功能
swift run m3u8-utility download https://example.com/video.m3u8
```

## 代码规范

### Swift 代码规范

我们遵循 Swift API 设计指南和以下规范：

#### 1. 命名规范

```swift
// ✅ 正确：使用驼峰命名法
public struct TFM3U8Utility {
    public static func download(_ method: Method) async throws
}

// ❌ 错误：使用下划线
public struct TFM3U8_Utility {
    public static func download_method(_ method: Method) async throws
}
```

#### 2. 文档注释

所有公共 API 必须包含完整的文档注释：

```swift
/// Downloads M3U8 content from a URL and processes it
/// 
/// This method downloads an M3U8 playlist file and all its associated video segments,
/// saving them to the specified directory.
/// 
/// - Parameters:
///   - method: The download method to use (`.web` for HTTP/HTTPS, `.local` for local files)
///   - url: The URL to download from (must be a valid M3U8 playlist URL)
///   - savedDirectory: Directory to save the downloaded content
///   - name: Optional name for the output file
/// 
/// - Throws: 
///   - `FileSystemError.failedToCreateDirectory` if directory creation fails
///   - `NetworkError` if network requests fail
///   - `ParsingError` if M3U8 parsing fails
/// 
/// ## Usage Example
/// ```swift
/// try await TFM3U8Utility.download(
///     .web,
///     url: URL(string: "https://example.com/video.m3u8")!,
///     savedDirectory: "/path/to/save",
///     name: "my-video"
/// )
/// ```
public static func download(
    _ method: Method = .web,
    url: URL,
    savedDirectory: String = "\(NSHomeDirectory())/Downloads/",
    name: String? = nil
) async throws
```

#### 3. 错误处理

使用强类型的错误枚举：

```swift
// ✅ 正确：使用强类型错误
public enum NetworkError: Error, LocalizedError {
    case invalidURL(String)
    case requestFailed(Error)
    case timeout(TimeInterval)
    case invalidResponse(Int)
}

// ❌ 错误：使用通用错误
public enum NetworkError: Error {
    case generic(String)
}
```

#### 4. 并发安全

使用 `Sendable` 协议确保并发安全：

```swift
// ✅ 正确：实现 Sendable
public struct DIConfiguration: Sendable {
    public let maxConcurrentDownloads: Int
    public let downloadTimeout: TimeInterval
}

// ✅ 正确：协议继承 Sendable
public protocol M3U8DownloaderProtocol: Sendable {
    func downloadContent(from url: URL) async throws -> String
}
```

#### 5. 依赖注入

使用协议和依赖注入：

```swift
// ✅ 正确：使用协议
public protocol M3U8DownloaderProtocol: Sendable {
    func downloadContent(from url: URL) async throws -> String
}

// ✅ 正确：实现协议
public struct DefaultM3U8Downloader: M3U8DownloaderProtocol {
    public func downloadContent(from url: URL) async throws -> String {
        // 实现
    }
}
```

### 文件组织

#### 目录结构

```
Sources/TFM3U8Utility/
├── TFM3U8Utility.swift          # 主公共 API
├── Core/                        # 核心组件
│   ├── DependencyInjection/     # 依赖注入
│   ├── Parsers/                 # 解析器
│   ├── Protocols/               # 协议定义
│   └── Types/                   # 类型定义
├── Services/                    # 服务实现
│   ├── Default/                 # 默认实现
│   └── Optimized/               # 优化实现
└── Utilities/                   # 工具类
    ├── Debug.swift              # 调试工具
    ├── Errors/                  # 错误处理
    └── Extensions/              # 扩展方法
```

#### 文件命名

- 使用 PascalCase 命名文件
- 文件名应与主要类型名称一致
- 使用有意义的文件名

```swift
// ✅ 正确
M3U8Parser.swift
DIConfiguration.swift
NetworkError.swift

// ❌ 错误
m3u8_parser.swift
di_configuration.swift
network_error.swift
```

## 测试规范

### 测试文件组织

```
Tests/TFM3U8UtilityTests/
├── DownloadTests.swift          # 下载功能测试
├── ParseTests.swift             # 解析功能测试
├── NetworkTests.swift           # 网络功能测试
├── IntegrationTests.swift       # 集成测试
├── PerformanceOptimizedTests.swift  # 性能测试
└── TestData/                    # 测试数据
    └── ts_segments/             # TS 片段文件
```

### 测试编写规范

#### 1. 测试命名

```swift
// ✅ 正确：描述性测试名称
func testDownloadM3U8FileFromURL() async throws {
    // 测试实现
}

func testParseMasterPlaylist() throws {
    // 测试实现
}

// ❌ 错误：不清晰的测试名称
func test1() async throws {
    // 测试实现
}
```

#### 2. 测试结构

```swift
final class DownloadTests: XCTestCase {
    
    // MARK: - Setup and Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        await TFM3U8Utility.initialize()
    }
    
    override func tearDown() async throws {
        // 清理测试数据
        try await super.tearDown()
    }
    
    // MARK: - Download Tests
    
    func testDownloadM3U8FileFromURL() async throws {
        // Given
        let url = URL(string: "https://example.com/video.m3u8")!
        let savedDirectory = "/tmp/test-download"
        
        // When
        try await TFM3U8Utility.download(
            .web,
            url: url,
            savedDirectory: savedDirectory,
            name: "test-video"
        )
        
        // Then
        let fileManager = FileManager.default
        XCTAssertTrue(fileManager.fileExists(atPath: "\(savedDirectory)/test-video.mp4"))
    }
    
    func testDownloadWithInvalidURL() async throws {
        // Given
        let invalidURL = URL(string: "https://invalid-url-that-does-not-exist.com/video.m3u8")!
        
        // When & Then
        do {
            try await TFM3U8Utility.download(.web, url: invalidURL)
            XCTFail("Expected download to fail with invalid URL")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .requestFailed(error))
        }
    }
}
```

#### 3. 异步测试

```swift
func testAsyncDownload() async throws {
    // 使用 async/await 进行异步测试
    let expectation = XCTestExpectation(description: "Download completion")
    
    Task {
        do {
            try await TFM3U8Utility.download(.web, url: testURL)
            expectation.fulfill()
        } catch {
            XCTFail("Download failed: \(error)")
        }
    }
    
    await fulfillment(of: [expectation], timeout: 30.0)
}
```

#### 4. 性能测试

```swift
func testDownloadPerformance() throws {
    measure {
        // 测量下载性能
        let expectation = XCTestExpectation(description: "Performance test")
        
        Task {
            try await TFM3U8Utility.download(.web, url: testURL)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 60.0)
    }
}
```

## 提交规范

### 提交信息格式

使用 [Conventional Commits](https://www.conventionalcommits.org/) 格式：

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

#### 类型

- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式调整
- `refactor`: 代码重构
- `test`: 测试相关
- `chore`: 构建过程或辅助工具的变动

#### 示例

```bash
# 新功能
git commit -m "feat: add support for encrypted M3U8 streams"

# Bug 修复
git commit -m "fix: resolve memory leak in download manager"

# 文档更新
git commit -m "docs: update API documentation with examples"

# 测试
git commit -m "test: add integration tests for download functionality"

# 重构
git commit -m "refactor: improve error handling in parser"
```

### 分支命名

- `feature/feature-name`: 新功能分支
- `fix/bug-description`: Bug 修复分支
- `docs/documentation-update`: 文档更新分支
- `test/test-description`: 测试相关分支

## 提交流程

### 1. Fork 项目

1. 访问 [GitHub 项目页面](https://github.com/ftitreefly/TFM3U8Utility2)
2. 点击 "Fork" 按钮
3. 克隆您的 Fork 到本地

### 2. 创建功能分支

```bash
git checkout -b feature/your-feature-name
```

### 3. 开发功能

1. 编写代码
2. 添加测试
3. 更新文档
4. 运行测试确保通过

```bash
# 运行所有测试
swift test

# 运行特定测试
swift test --filter DownloadTests

# 检查代码格式
swift format --in-place Sources/
```

### 4. 提交更改

```bash
# 添加更改
git add .

# 提交更改
git commit -m "feat: add new feature description"

# 推送到远程分支
git push origin feature/your-feature-name
```

### 5. 创建 Pull Request

1. 访问您的 GitHub Fork 页面
2. 点击 "Compare & pull request"
3. 填写 PR 描述，包含：
   - 功能描述
   - 测试情况
   - 相关 Issue 链接
   - 截图（如果适用）

### 6. PR 模板

```markdown
## 描述

简要描述此 PR 的功能或修复。

## 类型

- [ ] Bug 修复
- [ ] 新功能
- [ ] 文档更新
- [ ] 测试更新
- [ ] 重构

## 测试

- [ ] 运行了所有测试
- [ ] 添加了新测试
- [ ] 测试覆盖率达到要求

## 检查清单

- [ ] 代码遵循项目规范
- [ ] 添加了必要的文档注释
- [ ] 更新了相关文档
- [ ] 所有测试通过
- [ ] 没有引入新的警告

## 相关 Issue

Closes #123
```

## 代码审查

### 审查要点

1. **功能正确性**: 代码是否按预期工作
2. **代码质量**: 是否遵循项目规范
3. **测试覆盖**: 是否有足够的测试
4. **文档更新**: 是否更新了相关文档
5. **性能影响**: 是否影响性能
6. **安全性**: 是否有安全风险

### 审查流程

1. 自动检查（CI/CD）
2. 代码审查者审查
3. 维护者最终审查
4. 合并到主分支

## 发布流程

### 版本号规范

使用 [语义化版本](https://semver.org/)：

- `MAJOR.MINOR.PATCH`
- `MAJOR`: 不兼容的 API 修改
- `MINOR`: 向下兼容的功能性新增
- `PATCH`: 向下兼容的问题修正

### 发布步骤

1. 更新版本号
2. 更新版本号和文档
3. 创建发布标签
4. 发布到 GitHub

```bash
# 更新版本号（在 Package.swift 中）
# 创建标签
git tag v1.0.0
git push origin v1.0.0

# 在 GitHub 上创建 Release
```

## 获取帮助

如果您在贡献过程中遇到问题：

- 📖 查看 [快速开始指南](QUICKSTART.md)
- 📚 阅读 [完整文档](DOCUMENTATION.md)
- 🐛 在 [GitHub Issues](https://github.com/ftitreefly/TFM3U8Utility2/issues) 提问
- 💬 在 [GitHub Discussions](https://github.com/ftitreefly/TFM3U8Utility2/discussions) 讨论

## 行为准则

我们致力于为每个人提供友好、安全和欢迎的环境。

---

感谢您的贡献！🎉

*贡献指南最后更新于 2025年7月* 