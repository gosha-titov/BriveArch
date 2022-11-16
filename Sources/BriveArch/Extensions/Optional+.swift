internal extension Optional {
    
    /// A `Boolean` value indicating whether the optional object is `nil`.
    ///
    ///     var age: Int?
    ///     age.isNil // true
    ///
    var isNil: Bool { self == nil }
    
    /// A `Boolean` value indicating whether the optional object is not `nil`.
    ///
    ///     var name: String? = "gosha"
    ///     name.hasValue // true
    ///
    var hasValue: Bool { self != nil }
    
}
