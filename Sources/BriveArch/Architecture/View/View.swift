open class View<InteractorInterface>: AnyView {
    
    public final var interactor: InteractorInterface? { _interactor as? InteractorInterface }
    
}
