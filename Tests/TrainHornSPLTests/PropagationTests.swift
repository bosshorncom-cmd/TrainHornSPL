import XCTest
@testable import TrainHornSPL

final class PropagationTests: XCTestCase {
    func testDoublingDistanceIsAboutSixDB() throws {
        let e = try Propagation.spl(sourceSPLDB: 120, referenceDistanceM: 1, targetDistanceM: 2)
        XCTAssertEqual(e.geometricAttenuationDB, 20 * log10(2.0), accuracy: 1e-12)
        XCTAssertEqual(e.splDB, 120 - 20 * log10(2.0), accuracy: 1e-9)
        XCTAssertEqual(e.atmosphericAbsorptionDB, 0)
        XCTAssertNil(e.alphaDBPerKm)
    }

    func testTenfoldDistanceIsTwentyDB() throws {
        let e = try Propagation.spl(sourceSPLDB: 100, referenceDistanceM: 3, targetDistanceM: 30)
        XCTAssertEqual(e.splDB, 80, accuracy: 1e-9)
    }

    func testAbsorptionIsAlphaTimesPathDifference() throws {
        let atm = Atmosphere(temperatureC: 20, humidityPercent: 70)
        let e = try Propagation.spl(sourceSPLDB: 120, referenceDistanceM: 1, targetDistanceM: 101, frequencyHz: 1000, atmosphere: atm)
        let alpha = try ISO9613.alphaDBPerMetre(frequencyHz: 1000, atmosphere: atm)
        XCTAssertEqual(e.atmosphericAbsorptionDB, alpha * 100, accuracy: 1e-12)
        XCTAssertEqual(e.alphaDBPerKm ?? 0, 4.98, accuracy: 0.05)
        XCTAssertEqual(e.atmosphericAbsorptionDB, 0.498, accuracy: 0.01)
        XCTAssertEqual(e.splDB, 120 - 20 * log10(101.0) - alpha * 100, accuracy: 1e-9)
    }

    func testDistanceSolveWithoutAbsorptionIsExact() throws {
        let e = try Propagation.distance(forTargetSPLDB: 100, sourceSPLDB: 120, referenceDistanceM: 1)
        XCTAssertEqual(e.distanceM, 10, accuracy: 1e-8)
        XCTAssertEqual(e.splDB, 100, accuracy: 1e-6)
    }

    func testDistanceSolveRoundTripsWithAbsorption() throws {
        let atm = Atmosphere(temperatureC: 10, humidityPercent: 60)
        let forward = try Propagation.spl(sourceSPLDB: 118, referenceDistanceM: 2, targetDistanceM: 80, frequencyHz: 400, atmosphere: atm)
        let inverse = try Propagation.distance(forTargetSPLDB: forward.splDB, sourceSPLDB: 118, referenceDistanceM: 2, frequencyHz: 400, atmosphere: atm)
        XCTAssertEqual(inverse.distanceM, 80, accuracy: 80 * 1e-6)
        XCTAssertEqual(inverse.splDB, forward.splDB, accuracy: 1e-6)
    }

    func testDistanceCloserThanReference() throws {
        let e = try Propagation.distance(forTargetSPLDB: 120 + 20 * log10(2.0), sourceSPLDB: 120, referenceDistanceM: 10)
        XCTAssertEqual(e.distanceM, 5, accuracy: 5e-6)
    }

    func testRejectsNonPositiveDistances() {
        XCTAssertThrowsError(try Propagation.spl(sourceSPLDB: 100, referenceDistanceM: 0, targetDistanceM: 5))
        XCTAssertThrowsError(try Propagation.spl(sourceSPLDB: 100, referenceDistanceM: 1, targetDistanceM: -5))
        XCTAssertThrowsError(try Propagation.distance(forTargetSPLDB: 90, sourceSPLDB: 100, referenceDistanceM: 0))
    }

    func testCombinedLevels() {
        XCTAssertEqual(Propagation.combinedLevelDB([100, 100]), 100 + 10 * log10(2.0), accuracy: 1e-9)
        XCTAssertEqual(Propagation.combinedLevelDB([110]), 110, accuracy: 1e-12)
        XCTAssertEqual(Propagation.combinedLevelDB([]), -Double.infinity)
    }

    func testCaveatsAreHonest() {
        XCTAssertTrue(Propagation.caveats.contains("calibrated sound level meter"))
        XCTAssertTrue(Propagation.caveats.lowercased().contains("free-field"))
    }
}
