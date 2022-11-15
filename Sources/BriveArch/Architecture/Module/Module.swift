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
    public var isActive: Bool { state == .active }
    
    /// A `String` value that represents a path from the root module to this.
    ///
    /// A path consists of the module names that you have specified, for example:
    ///
    ///     "root/Settings/Appearance"
    ///
    public internal(set) var path: String?
    
    
    // MARK: - Components
    
    internal var interactor: AnyInteractor
    internal var router: Router
    internal var view: AnyView?
    
    private var builder: BuilderProtocol?
    
    
    // MARK: Bind-Unbind Components
    
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
