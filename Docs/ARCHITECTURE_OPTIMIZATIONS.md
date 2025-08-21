# TFM3U8Utility2 架构优化提案

本文档汇总对当前代码库的架构级优化建议，旨在提升解耦度、并发一致性、可测试性与扩展性。建议按优先级分批落地，尽量做到对外 API 无破坏或提供平滑迁移路径。

## 1. 依赖注入（DI）
- 强类型键替代字符串键：用 `ObjectIdentifier(T.self)` 作为注册/解析字典的 key，避免 `String(describing:)` 带来的命名冲突与重构风险。
- 失败路径避免 fatalError：`resolve` 未注册时返回类型化错误（如 `ConfigurationError.missingParameter`），由 CLI 层统一呈现给用户。
- 全局隔离策略：去除对 `@MainActor` 的依赖，容器内部用锁保证线程安全；提供测试专用的安全替换 API（如 `replaceShared(forTesting:)`）。
- 生命周期与作用域：引入 `singleton / transient / perTask` 三种作用域，`TaskManagerProtocol` 推荐使用 `perTask`。
- 配置幂等与覆盖策略：增加 `reset()` 与幂等检测，支持热更新项（headers、timeouts、log level）在运行期调整。

## 2. 并发与取消
- 任务取消可传播：`TaskManager` 保存子任务引用，`cancelTask` 深度取消下载、处理与 IO。
- 统一并发控制：抽象 `ConcurrencyLimiter`（令牌/AsyncSemaphore），由上层统一注入，避免多层限流不一致。

## 3. 日志与可观测性
- 日志注入化：将 `Logger` 抽象为 `LoggerProtocol` 注入，移除全局静态单例依赖；初始化放在应用启动而非每次业务调用。
- 指标采集：对外暴露只读的任务指标与事件钩子（进度、吞吐、失败率、重试次数）。

## 4. 错误模型与边界
- 类型化错误贯穿：库层统一抛出 `TFM3U8Error` 家族错误，CLI 层做聚合输出（domain/code/suggestion）。
- 配置验证：启动阶段集中校验工具路径、权限与网络策略，聚合为 `ConfigurationError`。

## 5. 网络与外部工具解耦
- 标准 HTTP 客户端：引入 `NetworkClientProtocol`（基于 `URLSession`），`curl` 作为可选后备，通过 `CommandExecutorProtocol` 注入。
- 策略化重试/超时/限速：`RetryPolicy` 与 `RateLimitPolicy` 通过 `DIConfiguration` 配置。

## 6. 文件系统边界
- URL 优先：`FileSystemServiceProtocol` 优先使用 `URL` API，字符串仅在边界转换；统一展开 `~` 与相对路径。
- 路径提供者：引入 `PathProviderProtocol` 统一管理 Downloads/临时目录，移除散落的 `NSHomeDirectory()` 调用。

## 7. 解析器分层
- 纯函数化：解析与 IO 完全分离；模型不可变并完善 URL 行关联；移除解析期副作用。
- 可扩展 Tag 系统：对多行/新 tag 采用注册式扩展点，降低 `handleTags` 分支复杂度。

## 8. 插件式提取器
- 注册中心模块化：`DefaultM3U8ExtractorRegistry` 支持从配置加载规则表与优先级；对第三方提供静态注册接口。
- 统一链接模型：`M3U8Link` 增加置信度、来源方法、权重，便于排序与去重。

## 9. API 设计
- 初始化约束：强制 `initialize` → 业务 API；避免在业务 API 中重复 `configure`。
- 一致性与选项容器：通过 `Options` 容器合并零散参数，配置通过 `DIConfiguration` 传递。

## 10. 模块/包组织
- 建议拆分为 `TFM3U8Core`（错误/模型/解析/协议）、`TFM3U8Services`（Downloader/Processor/FS/Executor/Registry）、`TFM3U8CLI`（命令行）、`TFM3U8TestKit`（测试替身）。

---

落地顺序建议：
1) DI：强类型键 → 非 fatalError → 全局隔离与重置；
2) 日志注入化；
3) 并发与取消统一；
4) 网络客户端与重试策略；
5) 解析器与提取器扩展点。


