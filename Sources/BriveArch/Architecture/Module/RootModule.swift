import UIKit

open class RootModule {
    
    public let name: String = "root"
    
    /// An object that logs messages of all modules that grow from this root module.
    ///
    /// You can set your own logger, just implement a new class that subclasses  the `ModuleLogger` class.
    public var logger = ModuleLogger()
    
    /// An initial child module from which the module tree begins.
    private let child: Module
    
    
    public final func launch(from window: UIWindow) -> Void {
        
    }
    
    
    // MARK: - Init
    
    public init(builder: RootBuilderProtocol) {
        child = builder.createInitialModule()
        child.logger = logger
        child.load()
    }
    
}
