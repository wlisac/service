import Mapper

public enum Config {
    case string(String)
    case int(Int)
    case double(Double)
    case array([Config])
    case dictionary([String: Config])
    case bool(Bool)
    case null
}

// MARK: protocols

public protocol ConfigInitializable {
    init(config: Config) throws
}

public protocol ConfigRepresentable {
    func makeConfig() throws -> Config
}

public typealias ConfigConvertible = ConfigInitializable & ConfigRepresentable

// MARK: convenience inits

extension Config {
    public init() {
        self = .dictionary([:])
    }

    public init(_ config: ConfigRepresentable) throws {
        try self.init(config: config.makeConfig())
    }
}

// MARK: conform self

extension Config: ConfigConvertible {
    public init(config: Config) throws {
        self = config
    }

    public func makeConfig() throws -> Config {
        return self
    }
}


// MARK: map

extension Config: MapConvertible {
    public init(map: Map) throws {
        switch map {
        case .array(let array):
            let array = try array.map { try Config(map: $0) }
            self = .array(array)
        case .dictionary(let dict):
            let obj = try dict.mapValues { try Config(map: $0) }
            self = .dictionary(obj)
        case .double(let double):
            self = .double(double)
        case .int(let int):
            self = .int(int)
        case .string(let string):
            self = .string(string)
        case .bool(let bool):
            self = .bool(bool)
        case .null:
            self = .null
        }
    }

    public func makeMap() throws -> Map {
        switch self {
        case .array(let array):
            let array = try array.map { try $0.makeMap() }
            return .array(array)
        case .dictionary(let obj):
            var dict: [String: Map] = [:]
            for (key, val) in obj {
                dict[key] = try val.makeMap()
            }
            return .dictionary(dict)
        case .double(let double):
            return .double(double)
        case .int(let int):
            return .int(int)
        case .string(let string):
            return .string(string)
        case .bool(let bool):
            return .bool(bool)
        case .null:
            return .null
        }
    }
}

extension Map: ConfigConvertible {
    public init(config: Config) throws {
        self = try config.makeMap()
    }

    public func makeConfig() throws -> Config {
        return try Config(map: self)
    }
}

// MARK: convenience access

extension Config: Polymorphic {}

// MARK: keyed

extension Config: Keyed {
    public static var empty: Config { return .dictionary([:]) }

    public mutating func set(key: PathComponent, to value: Config?) {
        switch key {
        case .index(let int):
            var array = self.array ?? []
            array[safe: int] = value ?? .null
            self = .array(array)
        case .key(let string):
            var dict = dictionary ?? [:]
            dict[string] = value ?? .null
            self = .dictionary(dict)
        }
    }

    public func get(key: PathComponent) -> Config? {
        switch key {
        case .index(let int):
            return array?[safe: int]
        case .key(let string):
            return dictionary?[string]
        }
    }
}

// MARK: keyed convenience

extension Config {
    public mutating func set<T: ConfigRepresentable>(_ path: String..., to config: T) throws {
        try set(path, to: config) { try $0.makeConfig() }
    }

    public func get<T: ConfigInitializable>(_ path: String...) throws -> T {
        return try get(path) { try T(config: $0) }
    }
}

// MARK: compatible types

extension ConfigRepresentable where Self: MapRepresentable {
    public func makeConfig() throws -> Config { return try converted() }
}

extension ConfigInitializable where Self: MapInitializable {
    public init(config: Config) throws { self = try config.converted() }
}

extension Array: ConfigConvertible {}
extension Dictionary: ConfigConvertible {}
extension Optional: ConfigConvertible {}
extension String: ConfigConvertible {}
extension Int: ConfigConvertible {}
extension Double: ConfigConvertible {}

// MARK: Literal

extension Config: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension Config: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Config...) {
        self = .array(elements)
    }
}

extension Config: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}

extension Config: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}

extension Config: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension Config: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension Config: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, Config)...) {
        self = .dictionary(Dictionary(uniqueKeysWithValues: elements))
    }
}
