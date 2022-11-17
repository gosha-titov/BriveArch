open class AnyInteractor {
    
    // MARK: - Internal Properties
    
    /// An internal module to that this interactor belongs.
    internal weak var _module: Module?
    
    /// An internal manager that is set by a module.
    internal weak var _router: Router?
    
    /// An internal view that is set by a module.
    internal weak var _view: AnyView?
    
    
    // MARK: - Instances of Related Interactors
    
    /// Returns an instance of a parent interactor casted to the given interface.
    ///
    /// You usually call this method when it's not enough for you to simply pass/receive some data to/from a parent interactor,
    /// so you create an individual communication protocol(interface) to the parent interactor and implement it.
    /// And then you define a computed property as the example below:
    ///
    ///     var parent: SomeInterface? {
    ///         return parent(as: SomeInterface.self)
    ///     }
    ///
    /// - Returns: An instance of a parent interactor casted to the given interface; otherwise, `nil`.
    public final func parent<Interface>(as: Interface.Type) -> Interface? {
        return _module?.interactor(of: .parent) as? Interface
    }
    
    /// Returns an instance of a specific child interactor casted to the given interface.
    ///
    /// You usually call this method when it's not enough for you to simply pass/receive some data to/from a specific child interactor,
    /// so you create an individual communication protocol(interface) to this child interactor and implement it.
    /// And then you define a computed property as the example below:
    ///
    ///     var someChild: SomeInterface? {
    ///         return child("some", as: SomeInterface.self)
    ///     }
    ///
    /// - Returns: An instance of a specific child interactor casted to the given interface; otherwise, `nil`.
    public final func child<Interface>(_ name: String, as: Interface.Type) -> Interface? {
        return _module?.interactor(of: .child(name)) as? Interface
    }
    
    
    // MARK: - Process Passed Data
    
    /// Called when this module is loaded into memory and a parent interactor passes context data
    /// so that this module to be ready for use.
    ///
    /// If you need to get some data without that this module cannot be started, then use the `canBecomeActive` property as in the example below:
    ///
    ///     override func moduleDidLoad() -> Void {
    ///         ...
    ///         module?.canBecomeActive = false
    ///     }
    ///
    ///     override func parent(didPassContext context: Any) -> Void {
    ///         ...
    ///         module?.canBecomeActive = true
    ///     }
    ///
    /// Override this method to process the context data.
    /// You don't need to call the `super` method.
    open func parent(didPassContext context: Any) -> Void {}
    
    /// Called when this module is about to become active, and a parent interactor passes some named input data.
    ///
    /// Override this method to process the input data.
    /// You don't need to call the `super` method.
    open func parent(didPassInput input: Any, with label: String) -> Void {}
    
    /// Called when a parent interactor passes some named data.
    ///
    /// Override this method to process the passed data.
    /// You don't need to call the `super` method.
    open func parent(didPassValue value: Any, with label: String) -> Void {}
    
    /// Called when a child module is about to be completed and its interactor passes some named output data.
    ///
    /// Override this method to process the output data.
    /// You don't need to call the `super` method.
    open func child(_ child: String, didPassOutput output: Any, with label: String) -> Void {}
    
    /// Called when a child interactor passes some named data.
    ///
    /// Override this method to process the passed data.
    /// You don't need to call the `super` method.
    open func child(_ child: String, didPassValue value: Any, with label: String) -> Void {}
    
    
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
