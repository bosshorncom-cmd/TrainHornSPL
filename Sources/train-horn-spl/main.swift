import Foundation
import TrainHornSPL

let usage = """
usage:
  train-horn-spl spl      --source DB --ref M --at M [--freq HZ] [--temp C] [--rh PCT] [--kpa KPA]
  train-horn-spl distance --source DB --ref M --target DB [--freq HZ] [--temp C] [--rh PCT] [--kpa KPA]
  train-horn-spl aweight  --freq HZ

Free-field estimate only (inverse-square + optional ISO 9613-1 absorption).
Not a substitute for a calibrated sound level meter.
"""

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(2)
}

var args = Array(CommandLine.arguments.dropFirst())
guard let command = args.first else { fail(usage) }
args.removeFirst()

var options: [String: Double] = [:]
var i = 0
while i < args.count {
    let key = args[i]
    guard key.hasPrefix("--"), i + 1 < args.count, let value = Double(args[i + 1]) else {
        fail("bad argument near '\(key)'\n\n" + usage)
    }
    options[String(key.dropFirst(2))] = value
    i += 2
}

func need(_ key: String) -> Double {
    guard let v = options[key] else { fail("missing --\(key)\n\n" + usage) }
    return v
}

let atmosphere = Atmosphere(
    temperatureC: options["temp"] ?? 20,
    humidityPercent: options["rh"] ?? 70,
    pressureKPa: options["kpa"] ?? Atmosphere.referencePressureKPa
)

func show(_ e: SPLEstimate) {
    print(String(format: "distance_m=%.3f spl_db=%.2f geometric_db=%.2f absorption_db=%.3f", e.distanceM, e.splDB, e.geometricAttenuationDB, e.atmosphericAbsorptionDB))
    if let a = e.alphaDBPerKm { print(String(format: "alpha_db_per_km=%.3f", a)) }
}

do {
    switch command {
    case "spl":
        show(try Propagation.spl(sourceSPLDB: need("source"), referenceDistanceM: need("ref"),
                                 targetDistanceM: need("at"), frequencyHz: options["freq"], atmosphere: atmosphere))
    case "distance":
        show(try Propagation.distance(forTargetSPLDB: need("target"), sourceSPLDB: need("source"),
                                      referenceDistanceM: need("ref"), frequencyHz: options["freq"], atmosphere: atmosphere))
    case "aweight":
        print(String(format: "a_weighting_db=%.2f", try AWeighting.decibels(atFrequencyHz: need("freq"))))
    case "-h", "--help", "help":
        print(usage)
    default:
        fail(usage)
    }
} catch {
    fail("error: \(error)")
}
