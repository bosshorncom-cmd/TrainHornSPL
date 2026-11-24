import Foundation

/// Atmospheric conditions used by the ISO 9613-1 absorption model.
public struct Atmosphere: Equatable, Sendable {
    /// Standard atmospheric pressure, 101.325 kPa (ISO 9613-1 clause 4.2).
    public static let referencePressureKPa = 101.325
    /// Reference temperature T0 = 293.15 K (20 °C).
    public static let referenceTemperatureK = 293.15
    /// Triple-point isotherm of water T01 = 273.16 K.
    public static let triplePointK = 273.16

    /// Air temperature in degrees Celsius.
    public var temperatureC: Double
    /// Relative humidity in percent (0...100).
    public var humidityPercent: Double
    /// Ambient pressure in kilopascals.
    public var pressureKPa: Double

    /// Creates an atmosphere. Defaults are 20 °C, 70 % RH and 101.325 kPa.
    public init(temperatureC: Double = 20, humidityPercent: Double = 70, pressureKPa: Double = Atmosphere.referencePressureKPa) {
        self.temperatureC = temperatureC
        self.humidityPercent = humidityPercent
        self.pressureKPa = pressureKPa
    }

    /// Temperature in kelvin.
    public var temperatureK: Double { temperatureC + 273.15 }

    func validate() throws {
        _ = try requirePositive("temperatureK", temperatureK)
        _ = try requirePositive("pressureKPa", pressureKPa)
        guard (0...100).contains(humidityPercent) else {
            throw TrainHornSPLError.outOfRange(name: "humidityPercent", value: humidityPercent, lower: 0, upper: 100)
        }
    }
}

/// ISO 9613-1:1993 pure-tone atmospheric absorption.
///
/// Implements clause 6: the oxygen and nitrogen relaxation frequencies and the
/// attenuation coefficient α. This is a free-field, pure-tone model; it does not
/// include ground effect, barriers, wind, turbulence or temperature gradients.
public enum ISO9613 {
    /// Molar concentration of water vapour, h, in percent.
    public static func waterVapourMoleFractionPercent(_ atmosphere: Atmosphere) throws -> Double {
        try atmosphere.validate()
        let exponent = -6.8346 * pow(Atmosphere.triplePointK / atmosphere.temperatureK, 1.261) + 4.6151
        let pSatOverPRef = pow(10.0, exponent)
        return atmosphere.humidityPercent * pSatOverPRef / (atmosphere.pressureKPa / Atmosphere.referencePressureKPa)
    }

    /// Oxygen and nitrogen vibrational relaxation frequencies, in hertz.
    public static func relaxationFrequencies(_ atmosphere: Atmosphere) throws -> (oxygen: Double, nitrogen: Double) {
        let h = try waterVapourMoleFractionPercent(atmosphere)
        let pRatio = atmosphere.pressureKPa / Atmosphere.referencePressureKPa
        let tRatio = atmosphere.temperatureK / Atmosphere.referenceTemperatureK
        let fO = pRatio * (24.0 + 4.04e4 * h * (0.02 + h) / (0.391 + h))
        let fN = pRatio * pow(tRatio, -0.5) * (9.0 + 280.0 * h * exp(-4.170 * (pow(tRatio, -1.0 / 3.0) - 1.0)))
        return (fO, fN)
    }

    /// Pure-tone attenuation coefficient α in dB per metre.
    public static func alphaDBPerMetre(frequencyHz: Double, atmosphere: Atmosphere = Atmosphere()) throws -> Double {
        let f = try requirePositive("frequencyHz", frequencyHz)
        let (fO, fN) = try relaxationFrequencies(atmosphere)
        let t = atmosphere.temperatureK
        let pRatio = atmosphere.pressureKPa / Atmosphere.referencePressureKPa
        let tRatio = t / Atmosphere.referenceTemperatureK
        let classical = 1.84e-11 / pRatio * tRatio.squareRoot()
        let relaxation = pow(tRatio, -2.5) * (
            0.01275 * exp(-2239.1 / t) * (fO / (fO * fO + f * f))
                + 0.1068 * exp(-3352.0 / t) * (fN / (fN * fN + f * f))
        )
        return 8.686 * f * f * (classical + relaxation)
    }

    /// Pure-tone attenuation coefficient α in dB per kilometre (the unit of ISO 9613-1 Table 1).
    public static func alphaDBPerKilometre(frequencyHz: Double, atmosphere: Atmosphere = Atmosphere()) throws -> Double {
        1000.0 * (try alphaDBPerMetre(frequencyHz: frequencyHz, atmosphere: atmosphere))
    }
}
