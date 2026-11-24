/// Errors thrown when an input is outside the range the models accept.
public enum TrainHornSPLError: Error, Equatable, CustomStringConvertible {
    /// A value that must be strictly positive was zero or negative.
    case nonPositive(name: String, value: Double)
    /// A value was outside its allowed closed range.
    case outOfRange(name: String, value: Double, lower: Double, upper: Double)
    /// The distance solver could not bracket a root (should not happen for finite inputs).
    case noSolution

    public var description: String {
        switch self {
        case let .nonPositive(name, value):
            return "\(name) must be > 0 (got \(value))"
        case let .outOfRange(name, value, lower, upper):
            return "\(name) must be between \(lower) and \(upper) (got \(value))"
        case .noSolution:
            return "could not find a distance for the requested target SPL"
        }
    }
}

@inline(__always)
func requirePositive(_ name: String, _ value: Double) throws -> Double {
    guard value > 0, value.isFinite else { throw TrainHornSPLError.nonPositive(name: name, value: value) }
    return value
}
