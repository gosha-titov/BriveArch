open class AnyInteractor {
    
    // MARK: - Internal Properties
    
    /// An internal module to that this interactor belongs.
    internal weak var _module: Module?
    
    /// An internal manager that is set by a module.
    internal weak var _router: Router?
    
    /// An internal view that is set by a module.
    internal weak var _view: AnyView?
    
    
    // MARK: Internal Init
    
    internal init() {}
    
}
