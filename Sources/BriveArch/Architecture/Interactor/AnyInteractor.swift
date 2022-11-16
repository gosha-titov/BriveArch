open class AnyInteractor {
    
    // MARK: - Internal Properties
    
    /// An internal module to that this interactor belongs.
    internal weak var _module: Module?
    
    /// An internal manager that is set by a module.
    internal weak var _router: Router?
    
    /// An internal view that is set by a module.
    internal weak var _view: AnyView?
    
    
    // MARK: - Module Lifecycle
    
    /// Called after a module is loaded into the parent memory.
    ///
    /// One of the operations that a module performs during loading is to connect its components to each other.
    /// Аfter the loading is done, you can interact with a router and a view.
    ///
    /// You usually override this method to perform additional initialization on your private properties;
    /// or to fetch some data from network services.
    ///
    /// If you expect to get some data to perform additional initialization, then use
    /// the `parent(didPassContext:)` method that is called immediately after this method ends.
    ///
    /// You don't need to call the `super` method.
    open func moduleDidLoad() -> Void {}
    
    open func moduleDidStart() -> Void {}
    
    open func moduleWillSuspend() -> Void {}
    
    open func moduleDidResume() -> Void {}
    
    open func moduleWillStop() -> Void {}
    
    open func moduleWillUnload() -> Void {}
    
    
    // MARK: - Internal Init
    
    internal init() {}
    
}
