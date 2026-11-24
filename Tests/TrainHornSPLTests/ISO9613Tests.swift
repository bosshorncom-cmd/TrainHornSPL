import XCTest
@testable import TrainHornSPL

final class ISO9613Tests: XCTestCase {
    // (temperature °C, RH %, pressure kPa, frequency Hz, α dB/km) — ISO 9613-1 formula checkpoints.
    let checkpoints: [(Double, Double, Double, Double, Double)] = [
        (20, 50, 101.325, 100, 0.294),
        (20, 50, 101.325, 1000, 4.66),
        (20, 50, 101.325, 10000, 158.8),
        (20, 50, 101.325, 100000, 3280),
        (20, 70, 101.325, 1000, 4.98),
        (20, 70, 101.325, 10000, 117.5),
        (0, 50, 101.325, 1000, 6.83),
        (0, 50, 101.325, 10000, 172.1),
        (30, 80, 101.325, 1000, 7.41),
        (30, 80, 101.325, 10000, 80.70),
        (20, 50, 80, 1000, 4.62),
        (20, 5, 101.325, 1000, 26.51),
        (20, 5, 101.325, 4000, 64.48),
        (-20, 50, 101.325, 1000, 9.14),
    ]

    func testAlphaCheckpoints() throws {
        for (t, rh, p, f, expected) in checkpoints {
            let got = try ISO9613.alphaDBPerKilometre(frequencyHz: f, atmosphere: Atmosphere(temperatureC: t, humidityPercent: rh, pressureKPa: p))
            XCTAssertEqual(got, expected, accuracy: max(0.01, 0.01 * expected), "T=\(t) RH=\(rh) p=\(p) f=\(f)")
        }
    }

    func testUnitsAreConsistent() throws {
        let km = try ISO9613.alphaDBPerKilometre(frequencyHz: 1000)
        let m = try ISO9613.alphaDBPerMetre(frequencyHz: 1000)
        XCTAssertEqual(km, 1000 * m, accuracy: 1e-12)
    }

    func testRelaxationFrequencies() throws {
        let a = try ISO9613.relaxationFrequencies(Atmosphere(temperatureC: 20, humidityPercent: 50))
        XCTAssertEqual(a.oxygen, 35413.9, accuracy: 35413.9 * 0.002)
        XCTAssertEqual(a.nitrogen, 331.9, accuracy: 331.9 * 0.002)
        let b = try ISO9613.relaxationFrequencies(Atmosphere(temperatureC: 20, humidityPercent: 70))
        XCTAssertEqual(b.oxygen, 53174.0, accuracy: 53174.0 * 0.002)
        XCTAssertEqual(b.nitrogen, 461.0, accuracy: 461.0 * 0.002)
    }

    func testRejectsBadInputs() {
        XCTAssertThrowsError(try ISO9613.alphaDBPerMetre(frequencyHz: 0))
        XCTAssertThrowsError(try ISO9613.alphaDBPerMetre(frequencyHz: 1000, atmosphere: Atmosphere(humidityPercent: 120))) { error in
            XCTAssertEqual(error as? TrainHornSPLError, .outOfRange(name: "humidityPercent", value: 120, lower: 0, upper: 100))
        }
        XCTAssertThrowsError(try ISO9613.alphaDBPerMetre(frequencyHz: 1000, atmosphere: Atmosphere(pressureKPa: 0)))
    }
}
