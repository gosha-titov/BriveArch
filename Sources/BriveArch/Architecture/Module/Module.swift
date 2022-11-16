open class Module {
    
    public enum State {
        case inactive, loaded, active, suspended, stopped
    }
    
    
    // MARK: - About
    
    /// A `String` value associated with this module.
    public let name: String
    
    /// A `State` value that is the current state of this module.
    public private(set) var state: State = .inactive
    
    /// A `Boolean` value that indicates whether this module is currently active.
    public final var isActive: Bool { state == .active }
    
    /// A `Boolean` value that indicates whether this module is currently loaded into memory.
    public private(set) var isLoaded: Bool = false
    
    /// A `Boolean` value that indicates whether this module can start working.
    ///
    /// You usually use this property when you need to get some context data
    /// in order its interactor to perform additional initialization.
    ///
    /// Set `False` if this module cannot start for some reasons.
    public var canStart: Bool = true
    
    /// A `String` value that represents a path from the root module to this.
    ///
    /// A path consists of the module names that you have specified, for example:
    ///
    ///     "root/Settings/Appearance"
    ///
    public internal(set) var path: String?
    
    
    // MARK: - Shared Properties
    
    /// An object that logs messages, it is set by a parent module.
    internal weak var logger: ModuleLoggerProtocol?
    
    
    // MARK: - Components
    
    internal var interactor: AnyInteractor
    internal var router: Router
    internal var view: AnyView?
    
    /// A builder that can create child modules.
    private var builder: BuilderProtocol?
    
    
    // MARK: - Bind-Unbind Components
    
    /// Binds module components to each other.
    private func bindComponents() -> Void {
        view?._interactor = interactor
        interactor._router = router
        interactor._view = view
    }
    
    /// Unbinds module components from each other by setting `nil`.
    private func unbindComponents() -> Void {
        interactor._router = nil
        interactor._view = nil
        view?._interactor = nil
    }
    
    // MARK: - Other
    
    /// Logs messages from this module.
    private func log(_ message: String, level: RootModule.LogLevel) -> Void {
        logger?.log(message, level: level, from: name)
    }
    
    
    // MARK: - Lifecycle
    
    /// Called when a parent module has attached this module to its children.
    internal func load() -> Void {
        state = .loaded
        isLoaded = true
        bindComponents()
        log("loaded into memory", level: .info)
        interactor.moduleDidLoad()
    }
    
    /// Called when this module should start working.
    internal func start() -> Void {
        state = .active
        log("started working", level: .info)
        interactor.moduleDidStart()
    }
    
    /// Called when a parent module suspends working of this module, or when a child module of this becomes active.
    internal func suspend() -> Void {
        interactor.moduleWillSuspend()
        state = .suspended
        log("suspended working", level: .info)
    }
    
    /// Called when this module should resume working.
    internal func resume() -> Void {
        state = .active
        log("resumed working", level: .info)
        interactor.moduleDidResume()
    }
    
    /// Called when a parent module stops working of this module, or when this module completes.
    internal func stop() -> Void {
        interactor.moduleWillStop()
        state = .stopped
        log("stopped working", level: .info)
    }
    
    /// Called when a parent module is about to detach this module from its children.
    internal func unload() -> Void {
        interactor.moduleWillUnload()
        state = .inactive
        log("unloaded from memory", level: .info)
    }
    
    
    // MARK: - Init
    
    /// Creates a named module with the given components.
    public init(name: String, router: Router, interactor: AnyInteractor, view: AnyView? = nil, builder: BuilderProtocol? = nil) {
        self.name = name
        self.interactor = interactor
        self.builder = builder
        self.router = router
        self.view = view
        interactor._module = self
        router._module = self
    }
    
}
