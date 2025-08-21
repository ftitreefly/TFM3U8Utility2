//
//  DependencyContainer.swift
//  TFM3U8Utility
//
//  Created by tree_fly on 2025/7/13.
//

import Foundation
// MARK: - Dependency Container

/// Thread-safe dependency injection container for M3U8 utility services
/// 
/// This container provides a thread-safe way to register and resolve dependencies
/// for the M3U8 utility library. It supports both transient and singleton service
/// registration with automatic dependency resolution.
/// 
/// ## Features
/// - Thread-safe service registration and resolution
/// - Support for both transient and singleton services
/// - Automatic dependency resolution
/// - Performance-optimized service configuration
/// - Global shared instance for convenience
/// 
/// ## Usage Example
/// ```swift
/// // Create a new container
/// let container = DependencyContainer()
/// 
/// // Configure with performance-optimized services
/// container.configurePerformanceOptimized()
/// 
/// // Resolve services
/// let downloader = container.resolve(M3U8DownloaderProtocol.self)
/// let parser = container.resolve(M3U8ParserServiceProtocol.self)
/// 
/// // Use the global shared instance
/// let taskManager = Dependencies.resolve(TaskManagerProtocol.self)
/// ```
public final class DependencyContainer: Sendable {
    
    /// Thread-safe storage for registered services
    private let storage: Storage
    
    /// Shared instance for convenience (can be replaced for testing)
    /// 
    /// This shared instance provides global access to the dependency container.
    /// It can be replaced for testing purposes to inject mock services.
    @MainActor public static var shared = DependencyContainer()
    
    /// Initializes a new dependency container
    /// 
    /// Creates a fresh container instance with thread-safe storage.
    public init() {
        self.storage = Storage()
    }
    
    /// Registers a transient service with the container
    /// 
    /// Transient services are created fresh each time they are resolved.
    /// This is useful for services that should not maintain state between uses.
    /// 
    /// - Parameters:
    ///   - type: The protocol type to register
    ///   - factory: A closure that creates the service instance
    /// 
    /// ## Usage Example
    /// ```swift
    /// container.register(M3U8DownloaderProtocol.self) {
    ///     OptimizedM3U8Downloader(
    ///         commandExecutor: commandExecutor,
    ///         configuration: configuration
    ///     )
    /// }
    /// ```
    public func register<T>(_ type: T.Type, factory: @escaping @Sendable () -> T) {
        storage.register(type, factory: factory)
    }
    
    /// Registers a singleton service with the container
    /// 
    /// Singleton services are created once and reused for all subsequent resolutions.
    /// This is useful for services that maintain state or are expensive to create.
    /// 
    /// - Parameters:
    ///   - type: The protocol type to register
    ///   - factory: A closure that creates the service instance
    /// 
    /// ## Usage Example
    /// ```swift
    /// container.registerSingleton(FileSystemServiceProtocol.self) {
    ///     DefaultFileSystemService()
    /// }
    /// ```
    public func registerSingleton<T>(_ type: T.Type, factory: @escaping @Sendable () -> T) {
        storage.registerSingleton(type, factory: factory)
    }
    
    /// Resolves a service from the container
    /// 
    /// This method creates or retrieves a service instance based on its registration.
    /// For transient services, a new instance is created each time. For singletons,
    /// the same instance is returned.
    /// 
    /// - Parameter type: The protocol type to resolve
    /// 
    /// - Returns: An instance of the requested service
    /// 
    /// - Throws: Fatal error if the service is not registered
    /// 
    /// ## Usage Example
    /// ```swift
    /// let downloader = container.resolve(M3U8DownloaderProtocol.self)
    /// let content = try await downloader.downloadContent(from: url)
    /// ```
    public func resolve<T>(_ type: T.Type) -> T {
        return storage.resolve(type)
    }
    
    /// Resolves a service and throws typed configuration errors instead of terminating the process
    ///
    /// - Parameter type: The protocol type to resolve
    /// - Returns: The resolved instance
    /// - Throws: `ConfigurationError` when service is not registered or cast fails
    public func tryResolve<T>(_ type: T.Type) throws -> T {
        return try storage.tryResolve(type)
    }
    
    /// Configures the container with the specified configuration
    /// 
    /// This method registers all the default services used by the M3U8 utility
    /// with the provided configuration. It sets up the complete dependency graph
    /// for the library.
    /// 
    /// - Parameter configuration: Configuration settings for the services
    /// 
    /// ## Usage Example
    /// ```swift
    /// let container = DependencyContainer()
    /// let config = DIConfiguration.performanceOptimized()
    /// container.configure(with: config)
    /// 
    /// // Now all services are available
    /// let taskManager = container.resolve(TaskManagerProtocol.self)
    /// ```
    public func configure(with configuration: DIConfiguration) {
        registerSingleton(DIConfiguration.self) { configuration }
        registerSingleton(FileSystemServiceProtocol.self) { DefaultFileSystemService() }
        registerSingleton(CommandExecutorProtocol.self) { DefaultCommandExecutor() }
        
        register(M3U8DownloaderProtocol.self) { [weak self] in
            guard let self = self else {
                fatalError("Container deallocated during service creation")
            }
            let commandExecutor = self.resolve(CommandExecutorProtocol.self)
            let configuration = self.resolve(DIConfiguration.self)
            return OptimizedM3U8Downloader(
                commandExecutor: commandExecutor,
                configuration: configuration
            )
        }
        
        register(M3U8ParserServiceProtocol.self) { DefaultM3U8ParserService() }
        
        register(VideoProcessorProtocol.self) { [weak self] in
            guard let self = self else {
                fatalError("Container deallocated during service creation")
            }
            let commandExecutor = self.resolve(CommandExecutorProtocol.self)
            let configuration = self.resolve(DIConfiguration.self)
            return OptimizedVideoProcessor(
                commandExecutor: commandExecutor,
                configuration: configuration
            )
        }
        
        register(TaskManagerProtocol.self) { [weak self] in
            guard let self = self else {
                fatalError("Container deallocated during service creation")
            }
            return OptimizedTaskManager(
                downloader: self.resolve(M3U8DownloaderProtocol.self),
                parser: self.resolve(M3U8ParserServiceProtocol.self),
                processor: self.resolve(VideoProcessorProtocol.self),
                fileSystem: self.resolve(FileSystemServiceProtocol.self),
                configuration: self.resolve(DIConfiguration.self),
                maxConcurrentTasks: self.resolve(DIConfiguration.self).maxConcurrentDownloads / 4
            )
        }
    }

    /// Clears all registrations and singletons. Use with caution.
    public func reset() {
        storage.reset()
    }
}

// MARK: - Thread-Safe Storage

/// Thread-safe storage for registered services
/// 
/// This private class provides thread-safe storage for service factories and
/// singleton instances. It uses recursive locks to ensure thread safety.
private final class Storage: @unchecked Sendable {
    /// Lock for thread-safe access to storage
    private let lock = NSRecursiveLock()
    
    /// Registered service factories (keyed by ObjectIdentifier)
    private var factories: [ObjectIdentifier: () -> Any] = [:]
    
    /// Cached singleton instances
    private var singletons: [ObjectIdentifier: Any] = [:]
    
    /// Registers a transient service factory
    /// 
    /// - Parameters:
    ///   - type: The service type to register
    ///   - factory: Factory closure that creates the service
    func register<T>(_ type: T.Type, factory: @escaping @Sendable () -> T) {
        let key = ObjectIdentifier(type)
        lock.lock()
        defer { lock.unlock() }
        factories[key] = factory
    }
    
    /// Registers a singleton service factory
    /// 
    /// - Parameters:
    ///   - type: The service type to register
    ///   - factory: Factory closure that creates the service
    func registerSingleton<T>(_ type: T.Type, factory: @escaping @Sendable () -> T) {
        let key = ObjectIdentifier(type)
        lock.lock()
        defer { lock.unlock() }
        factories[key] = { [weak self] in
            guard let self else { return factory() }
            if let existing = self.singletons[key] as? T {
                return existing
            }
            let instance = factory()
            self.singletons[key] = instance
            return instance
        }
    }
    
    /// Resolves a service instance
    /// 
    /// - Parameter type: The service type to resolve
    /// 
    /// - Returns: An instance of the requested service
    /// 
    /// - Throws: Fatal error if service is not registered or cast fails
    func resolve<T>(_ type: T.Type) -> T {
        let key = ObjectIdentifier(type)
        lock.lock()
        defer { lock.unlock() }
        
        guard let factory = factories[key] else {
            fatalError("Service \(type) not registered. Call configureDefaults() or register the service manually.")
        }
        
        guard let instance = factory() as? T else {
            fatalError("Failed to cast service to expected type \(type)")
        }
        
        return instance
    }
    
    /// Throwing variant that returns typed configuration errors instead of terminating the process
    func tryResolve<T>(_ type: T.Type) throws -> T {
        let key = ObjectIdentifier(type)
        lock.lock()
        defer { lock.unlock() }
        
        guard let factory = factories[key] else {
            throw ConfigurationError.missingParameter("Service: \(type)")
        }
        
        guard let instance = factory() as? T else {
            throw ConfigurationError.invalidParameterValue("Service: \(type)", value: "Type cast failed")
        }
        
        return instance
    }
    
    /// Remove all registrations and singletons
    func reset() {
        lock.lock()
        factories.removeAll(keepingCapacity: false)
        singletons.removeAll(keepingCapacity: false)
        lock.unlock()
    }
}

// MARK: - Convenience Extensions

public extension DependencyContainer {
    /// Convenience method for resolving services
    /// 
    /// This is a shorthand for the `resolve` method, providing a more
    /// concise syntax for service resolution.
    /// 
    /// - Parameter type: The service type to resolve
    /// 
    /// - Returns: An instance of the requested service
    /// 
    /// ## Usage Example
    /// ```swift
    /// let downloader = container.get(M3U8DownloaderProtocol.self)
    /// ```
    func get<T>(_ type: T.Type) -> T {
        return resolve(type)
    }
}

// MARK: - Global Access (Optional)

/// Global dependency resolver for convenience
/// 
/// This global property provides easy access to the shared dependency container.
/// It can be replaced for testing purposes to inject mock services.
/// 
/// ## Usage Example
/// ```swift
/// // Use the global container
/// let taskManager = Dependencies.resolve(TaskManagerProtocol.self)
/// 
/// // Configure the global container
/// await Dependencies.configure(with: DIConfiguration.performanceOptimized())
/// 
/// // Replace for testing
/// Dependencies = mockContainer
/// ```
@MainActor public var Dependencies: DependencyContainer { // swiftlint:disable:this identifier_name
    get { DependencyContainer.shared }
    set { DependencyContainer.shared = newValue }
}

// MARK: - Global Dependencies Extension

@MainActor public extension DependencyContainer {
    /// Configures the global dependency container
    /// 
    /// This method configures the shared dependency container with the specified
    /// configuration. It should be called once at the start of the application.
    /// 
    /// - Parameter configuration: Configuration settings for the services
    /// 
    /// ## Usage Example
    /// ```swift
    /// // Configure with performance-optimized settings
    /// await Dependencies.configure(with: DIConfiguration.performanceOptimized())
    /// 
    /// // Now use the configured services
    /// let downloader = await Dependencies.resolve(M3U8DownloaderProtocol.self)
    /// ```
    func configureGlobal(with configuration: DIConfiguration) {
        self.configure(with: configuration)
    }
}
