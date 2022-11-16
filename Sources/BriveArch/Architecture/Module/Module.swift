open class Module {
    
    public enum State {
        case inactive, loaded, active, suspended, stopped
    }
    
    public enum RevokeAction {
        case stop, suspend
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
    
    /// A `Boolean` value that indicates whether this module can start or resume working.
    ///
    /// You usually use this property when you need to get some context data
    /// in order its interactor to perform additional initialization.
    ///
    /// Set `False` if this module cannot start or resume for some reasons.
    public var canStartOrResume: Bool = true
    
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
    
    
    // MARK: - Related Modules
    
    /// A parent module that owns this module.
    internal weak var parent: Module?
    
    /// A dictionary that contains created and loaded child modules.
    private var children = [String: Module]()
    
    
    // MARK: - Child Management
    
    /// Invokes a specific child module.
    ///
    /// This method transfers control to a specific child module, if possible.
    /// That is, this module becomes suspended, and a child module becomes active.
    ///
    /// It ensures that only one module is active at any time.
    /// - Returns: `True` if control has been transferred to a child module; otherwise, `False`.
    internal final func invoke(by name: String) -> Bool {
        let failureMessage = "cannot start/resume the \(name) child module because "
        guard isActive else {
            log(failureMessage + "this module is not active", level: .error)
            return false
        }
        let invoke: () -> Void
        let invokedChild: Module
        if let child = children[name] {
            switch child.state {
            case .suspended: invoke = { child.resume() }
            case .loaded: invoke = { child.start() }
            case .active:
                log(failureMessage + "it is already active", level: .warning)
                return false
            default:
                log(failureMessage + "it is \(child.state)", level: .error)
                return false
            }
            invokedChild = child
        } else {
            guard let builder else {
                log(failureMessage + "this module has no builder to create it", level: .error)
                return false
            }
            guard let child = builder.create(by: name) else {
                log(failureMessage + "a builder of this module cannot create it by its name", level: .error)
                return false
            }
            attach(child)
            invoke = { child.start() }
            invokedChild = child
        }
        guard invokedChild.canStartOrResume else {
            log(failureMessage + "its 'canStartOrResume' property is false", level: .error)
            return false
        }
        suspend()
        log("transfers control to the '\(name)' child module", level: .debug)
        invoke()
        return true
    }
    
    /// Revokes a specific child module.
    ///
    /// This method takes control from a specific child module, if possible.
    /// That is, a child module becomes suspended or stopped, and this module becomes active.
    ///
    /// It ensures that only one module is active at any time.
    /// - Returns: `True` if control has been taken from a child module; otherwise, `False`.
    internal final func revoke(by name: String, with action: RevokeAction) -> Bool {
        let failureMessage = "cannot \(action) the \(name) child module because "
        guard state == .suspended else {
            log(failureMessage + "this module is \(state)", level: .error)
            return false
        }
        guard let child = children[name] else {
            log(failureMessage + "there is no created child module with '\(name)' name", level: .error)
            return false
        }
        guard child.isActive else {
            log(failureMessage + "it is not active", level: .warning)
            return false
        }
        switch action {
        case .suspend: child.suspend()
        case .stop: child.stop()
        }
        log("takes control from the '\(name)' child module", level: .debug)
        resume()
        return true
    }
    
    /// Preloads a specific child module.
    internal func preload(by name: String) -> Bool {
        let failureMessage = "cannot preload the '\(name)' child module because "
        guard children[name].isNil else {
            log(failureMessage + "it is already loaded", level: .warning)
            return false
        }
        guard let builder else {
            log(failureMessage + "this module has no builder to create it", level: .error)
            return false
        }
        guard let child = builder.create(by: name) else {
            log(failureMessage + "a builder of this module cannot create it by its name", level: .error)
            return false
        }
        attach(child)
        return true
    }
    
    /// Adds the given module to children by its name.
    private func attach(_ child: Module) -> Void {
        children[child.name] = child
        child.parent = self
        guard let path else {
            log("does not belong to any module tree", level: .error)
            return
        }
        child.path = path + "/" + child.name
        log("created the \(child.name) child module and attached it to self", level: .debug)
        child.load()
    }
    
    /// Removes the given module from children by its name.
    private func detach(_ child: Module) -> Void {
        child.unload()
        children.removeValue(forKey: child.name)
        child.parent = nil
        child.path = nil
        log("detached the \(child.name) child module from self and removed it", level: .debug)
    }
    
    /// Removes all child modules by calling `detach(_:)` method for each.
    private func detachAllChildren() -> Void {
        children.values.forEach { detach($0) }
    }
    
    
    // MARK: - Lifecycle
    
    /// Called when a parent module has attached this module to its children.
    internal func load() -> Void {
        state = .loaded
        isLoaded = true
        bindComponents()
        log("loaded into memory", level: .debug)
        interactor.moduleDidLoad()
    }
    
    /// Called when this module should start working.
    internal func start() -> Void {
        state = .active
        log("started working", level: .debug)
        interactor.moduleDidStart()
    }
    
    /// Called when a parent module suspends working of this module, or when a child module of this becomes active.
    internal func suspend() -> Void {
        interactor.moduleWillSuspend()
        state = .suspended
        log("suspended working", level: .debug)
    }
    
    /// Called when this module should resume working.
    internal func resume() -> Void {
        state = .active
        log("resumed working", level: .debug)
        interactor.moduleDidResume()
    }
    
    /// Called when a parent module stops working of this module, or when this module completes.
    internal func stop() -> Void {
        interactor.moduleWillStop()
        state = .stopped
        log("stopped working", level: .debug)
    }
    
    /// Called when a parent module is about to detach this module from its children.
    internal func unload() -> Void {
        interactor.moduleWillUnload()
        detachAllChildren()
        unbindComponents()
        state = .inactive
        isLoaded = false
        parent = nil
        log("unloaded from memory", level: .debug)
    }
    
    
    // MARK: - Bind and Unbind Components
    
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
