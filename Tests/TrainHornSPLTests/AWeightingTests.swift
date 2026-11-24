import XCTest
@testable import TrainHornSPL

final class AWeightingTests: XCTestCase {
    // IEC 61672-1 nominal A-weighting values, given to 0.1 dB.
    let nominal: [(Double, Double)] = [
        (10, -70.4), (20, -50.5), (100, -19.1), (1000, 0.0), (2000, 1.2),
        (4000, 1.0), (8000, -1.1), (10000, -2.5), (20000, -9.3),
    ]

    func testNominalValues() throws {
        for (f, expected) in nominal {
            XCTAssertEqual(try AWeighting.decibels(atFrequencyHz: f), expected, accuracy: 0.15, "f=\(f)")
        }
    }

    func testZeroAtOneKilohertz() throws {
        XCTAssertEqual(try AWeighting.decibels(atFrequencyHz: 1000), 0, accuracy: 1e-3)
    }

    func testRejectsNonPositiveFrequency() {
        XCTAssertThrowsError(try AWeighting.decibels(atFrequencyHz: -1))
    }
}
