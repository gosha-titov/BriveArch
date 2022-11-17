internal extension Dictionary {
    
    /// Returns a Boolean value indicating whether the given key exists in this dictionary.
    ///
    ///     let dict = [0: "a", 1: "b", 2: "c"]
    ///     dict.hasKey(2) // true
    ///     dict.hasKey(3) // false
    ///
    func hasKey(_ key: Key) -> Bool { self[key] != nil }
    
}
