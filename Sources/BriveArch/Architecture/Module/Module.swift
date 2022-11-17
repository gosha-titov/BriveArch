open class Module {
    
    public enum State {
        case inactive, loaded, active, suspended, stopped
    }
    
    public enum RevokeAction {
        case stop, suspend
    }
    
    public enum Relative: Equatable {
        case child(String)
        case parent
    }
    
    /// A type that all modules can send-to and receive-from each other.
    struct Signal: CustomStringConvertible {
        enum SignalType {
            case context
            case input(String), output(String)
            case other(String)
        }
        var value: Any
        var type: SignalType
        var description: String {
            switch self.type {
            case .context: return "context"
            case .input (let label): return "input with label: '\(label)'"
            case .output(let label): return "output with label: '\(label)'"
            case .other (let label): return "value with label: '\(label)'"
            }
        }
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
    public var canBecomeActive: Bool = true
    
    /// A `String` value that represents a path from the root module to this.
    ///
    /// A path consists of the module names that you have specified, for example:
    ///
    ///     "root/Settings/Appearance"
    ///
    public internal(set) var path: String?
    
    
    // MARK: - Logging
    
    /// An object that logs messages, it is set by a parent module.
    internal weak var logger: ModuleLogger?
    
    /// An object that logs all module messages.
    private lazy var log = ModuleLog(name: name, logger: logger)
    
    
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
    
    
    // MARK: - Related Modules
    
    /// Returns an interactor of a specific related module if exists.
    internal final func interactor(of relative: Relative) -> AnyInteractor? {
        let relativeInteractor: AnyInteractor
        switch relative {
        case .child(let name):
            guard let child = children[name] else {
                log.interactorFailure0(name); return nil
            }
            relativeInteractor = child.interactor
        case .parent:
            guard let parent else {
                log.interactorFailure1(); return nil
            }
            relativeInteractor = parent.interactor
        }
        return relativeInteractor
    }
    
    
    // MARK: - Signal Management
    
    /// Sends a `Signal` value that is any named data to a specific related module.
    ///
    /// This method is called when an interactor of this module passes some named data to a specific related module.
    internal final func send(_ signal: Signal, to receiver: Relative) -> Void {
        let receivingModule: Module
        let sender: Relative
        switch receiver {
        case .child(let name):
            guard let child = children[name] else {
                log.sendFailure0(name, signal.description)
                return
            }
            receivingModule = child
            sender = .parent
        case .parent:
            guard let parent else {
                log.sendFailure1(signal.description)
                return
            }
            receivingModule = parent
            sender = .child(name)
        }
        log.sended(receivingModule.name, signal.description)
        receivingModule.receive(signal, from: sender)
    }
    
    /// Receives a `Signal` value that is any named data from a specific related module.
    ///
    /// This method processes a signal from a specific related module and calls associated method of an interactor of this module.
    internal final func receive(_ signal: Signal, from sender: Relative) -> Void {
        let data = signal.value
        switch sender {
        case .child(let name):
            guard children.hasKey(name) else {
                log.receiveFailure0(name, signal.description); return
            }
            switch signal.type {
            case .output(let label): interactor.child(name, didPassOutput: data, with: label)
            case .other (let label): interactor.child(name, didPassValue: data, with: label)
            case .input, .context: return
            }
            log.received(name, signal.description)
        case .parent:
            guard let parent else {
                log.receiveFailure1(signal.description); return
            }
            switch signal.type {
            case .input(let label): interactor.parent(didPassInput: data, with: label)
            case .other(let label): interactor.parent(didPassValue: data, with: label)
            case .context: interactor.parent(didPassContext: data)
            case .output: return
            }
            log.received(parent.name, signal.description)
        }
    }
    
    
    // MARK: - Child Management
    
    /// Invokes a specific child module.
    ///
    /// This method transfers control to a specific child module, if possible.
    /// That is, this module becomes suspended, and a child module becomes active.
    ///
    /// It ensures that only one module is active at any time.
    /// - Returns: `True` if control has been transferred to a child module; otherwise, `False`.
    internal final func invoke(by childName: String) -> Bool {
        guard isActive else {
            log.invokeFailure0(childName); return false
        }
        let invokeChild: () -> Void
        let invokedChild: Module
        
        // If child module exists -> start() or resume()
        if let child = children[childName] {
            switch child.state {
            case .suspended: invokeChild = { child.resume() }
            case .loaded: invokeChild = { child.start() }
            case .active: log.invokeFailure1(childName); return false
            default: log.invokeFailure2(childName, child.state); return false
            }
            invokedChild = child
            
        // If child module doesn't exist -> create(), load() and start()
        } else {
            guard let builder else {
                log.invokeFailure3(childName); return false
            }
            guard let child = builder.create(by: childName) else {
                log.invokeFailure4(childName); return false
            }
            attach(child)
            invokeChild = { child.start() }
            invokedChild = child
        }
        guard invokedChild.canBecomeActive else {
            log.invokeFailure5(childName); return false
        }
        suspend()
        log.invoking(childName)
        invokeChild()
        return true
    }
    
    /// Revokes a specific child module.
    ///
    /// This method takes control from a specific child module, if possible.
    /// That is, a child module becomes suspended or stopped, and this module becomes active.
    ///
    /// It ensures that only one module is active at any time.
    /// - Returns: `True` if control has been taken from a child module; otherwise, `False`.
    internal final func revoke(by childName: String, with action: RevokeAction) -> Bool {
        guard state == .suspended else {
            log.revokeFailure0(childName, action, state); return false
        }
        guard let child = children[childName] else {
            log.revokeFailure1(childName, action); return false
        }
        guard child.isActive else {
            log.revokeFailure2(childName, action); return false
        }
        switch action {
        case .suspend: child.suspend()
        case .stop: child.stop()
        }
        log.revoking(childName)
        resume()
        return true
    }
    
    /// Preloads a specific child module.
    internal func preload(by childName: String) -> Bool {
        guard children[childName].isNil else {
            log.preloadFailure0(childName); return false
        }
        guard let builder else {
            log.preloadFailure1(childName); return false
        }
        guard let child = builder.create(by: childName) else {
            log.preloadFailure2(childName); return false
        }
        attach(child)
        log.preloaded(childName)
        return true
    }
    
    /// Adds the given module to children by its name.
    private func attach(_ child: Module) -> Void {
        children[child.name] = child
        child.parent = self
        if let path {
            child.path = path + "/" + child.name
        }
        child.load()
    }
    
    /// Removes the given module from children by its name.
    private func detach(_ child: Module) -> Void {
        child.unload()
        children.removeValue(forKey: child.name)
        child.parent = nil
        child.path = nil
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
        log.lifecycleLoaded()
        interactor.moduleDidLoad()
    }
    
    /// Called when this module should start working.
    internal func start() -> Void {
        state = .active
        log.lifecycleStarted()
        interactor.moduleDidStart()
    }
    
    /// Called when a parent module suspends working of this module, or when a child module of this becomes active.
    internal func suspend() -> Void {
        interactor.moduleWillSuspend()
        state = .suspended
        log.lifecycleSuspended()
    }
    
    /// Called when this module should resume working.
    internal func resume() -> Void {
        state = .active
        log.lifecycleResumed()
        interactor.moduleDidResume()
    }
    
    /// Called when a parent module stops working of this module, or when this module completes.
    internal func stop() -> Void {
        interactor.moduleWillStop()
        state = .stopped
        log.lifecycleStopped()
    }
    
    /// Called when a parent module is about to detach this module from its children.
    internal func unload() -> Void {
        interactor.moduleWillUnload()
        detachAllChildren()
        unbindComponents()
        state = .inactive
        isLoaded = false
        parent = nil
        log.lifecycleUnloaded()
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


// MARK: - Logging

extension Module {
    
    private final class ModuleLog {
        
        func sended(_ relatedName: String, _ description: String) { log("sended \(description) to the '\(relatedName)' related module", level: .debug) }
        func sendFailure0(_ childName: String, _ description: String) { log("cannot send \(description) to the '\(childName)' child module that is not created", level: .error) }
        func sendFailure1(_ description: String) { log("cannot send \(description) to a non-existent parent module", level: .error) }
        
        func received(_ relatedName: String, _ description: String) { log("received \(description) from the '\(relatedName)' related module", level: .debug) }
        func receiveFailure0(_ childName: String,  _ description: String) { log("cannot receive \(description) from the '\(childName)' child module because it's not a child of this", level: .error) }
        func receiveFailure1(_ description: String) { log("cannot receive \(description) from the parent module because this module has no parent", level: .error) }

        func interactorFailure0(_ childName: String) { log("cannot take an interactor of an uncreated child module with name: '\(name)'", level: .error) }
        func interactorFailure1() { log("cannot take an interactor of a non-existent parent module", level: .error) }
        
        func invoking(_ childName: String) { log("transfers control to the '\(childName)' child module", level: .debug) }
        func invokeFailure0(_ childName: String) { log("cannot start/resume the '\(childName)' child module because this module is not active", level: .error) }
        func invokeFailure1(_ childName: String) { log("cannot start/resume the '\(childName)' child module because it is already active", level: .warning) }
        func invokeFailure2(_ childName: String, _ childState: State) { log("cannot start/resume the '\(childName)' child module because it is \(childState)", level: .error) }
        func invokeFailure3(_ childName: String) { log("cannot start/resume the '\(childName)' child module because this module has no builder to create it", level: .error) }
        func invokeFailure4(_ childName: String) { log("cannot start/resume the '\(childName)' child module because a builder of this module cannot create it by its name", level: .error) }
        func invokeFailure5(_ childName: String) { log("cannot start/resume the '\(childName)' child module because its 'canBecomeActive' property is false", level: .error) }
        
        func revoking(_ childName: String) { log("takes control from the '\(childName)' child module", level: .debug) }
        func revokeFailure0(_ childName: String, _ action: RevokeAction, _ state: State) { log("cannot \(action) the '\(childName)' child module because this module is \(state)", level: .error) }
        func revokeFailure1(_ childName: String, _ action: RevokeAction) { log("cannot \(action) the '\(childName)' child module because there is no created child module with that name", level: .error) }
        func revokeFailure2(_ childName: String, _ action: RevokeAction) { log("cannot \(action) the '\(childName)' child module because it is not active", level: .warning) }
        
        func preloaded(_ childName: String) { log("preloaded the \(childName) child module",   level: .debug) }
        func preloadFailure0(_ childName: String) { log("cannot preload the '\(childName)' child module because it is already loaded", level: .warning) }
        func preloadFailure1(_ childName: String) { log("cannot preload the '\(childName)' child module because this module has no builder to create it", level: .error) }
        func preloadFailure2(_ childName: String) { log("cannot preload the '\(childName)' child module because a builder of this module cannot create it by its name", level: .error) }
        
        func lifecycleLoaded()    { log("loaded into memory",   level: .debug) }
        func lifecycleStarted()   { log("started working",      level: .debug) }
        func lifecycleSuspended() { log("suspended working",    level: .debug) }
        func lifecycleResumed()   { log("resumed working",      level: .debug) }
        func lifecycleStopped()   { log("stopped working",      level: .debug) }
        func lifecycleUnloaded()  { log("unloaded from memory", level: .debug) }
        
        let name: String
        let logger: ModuleLogger?
        
        private func log(_ message: String, level: ModuleLogger.LogLevel) -> Void {
            logger?.log(message, level: level, from: name)
        }
        
        init(name: String, logger: ModuleLogger?) {
            self.name = name
            self.logger = logger
        }
        
    }
    
}
