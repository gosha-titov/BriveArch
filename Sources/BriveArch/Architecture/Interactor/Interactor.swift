open class Interactor<RouterInterface, ViewInterface>: AnyInteractor {
    
    public final var router: RouterInterface? { _module as? RouterInterface }
    
    public final var view: ViewInterface? { _module as? ViewInterface }
    
    public override init() {
        super.init()
    }
    
}
