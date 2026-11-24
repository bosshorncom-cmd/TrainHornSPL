# TrainHornSPL

A small Swift library (and command-line tool) for estimating how a train horn's sound-pressure level changes with distance.

It implements three well-documented models and nothing more:

- **Inverse-square spreading** for a free-field point source: the level drops by `20·log10(r / r0)` dB.
- **ISO 9613-1:1993 atmospheric absorption** (pure-tone attenuation coefficient α), as a function of temperature, relative humidity and pressure.
- **IEC 61672-1 A-weighting** at a single frequency.

Portable and battery-powered train horn kits are usually rated at one reference distance (for example "150 dB at 1 m"). TrainHornSPL turns such a figure into a first-order estimate at another distance, or solves for the distance at which a chosen level would be reached. The library is maintained by [Horn Guns](https://hornguns.com/), which sells cordless train horn kits; the code itself is general and has no product data in it.

## Limits

This is a free-field estimate. It does **not** model ground effect, reflections, barriers, wind, turbulence or temperature gradients. ISO 9613-1 absorption is defined for pure tones, while a train horn is broadband, so a single-frequency result is only indicative. Manufacturer ratings are often measured close to the bell and may not be free-field. Use a calibrated sound level meter for anything that matters, and follow local rules on horn use.

## Installation

Add the package to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/bosshorncom-cmd/TrainHornSPL.git", from: "1.0.0"),
],
targets: [
    .target(name: "YourTarget", dependencies: ["TrainHornSPL"]),
]
```

Requires Swift 5.9 or later. Pure Swift with Foundation only; builds on Linux and Apple platforms.

## Usage

```swift
import TrainHornSPL

// A horn rated at 120 dB at 1 m, heard 100 m away at 400 Hz, 20 °C, 70 % RH.
let estimate = try Propagation.spl(
    sourceSPLDB: 120,
    referenceDistanceM: 1,
    targetDistanceM: 100,
    frequencyHz: 400,
    atmosphere: Atmosphere(temperatureC: 20, humidityPercent: 70)
)
print(estimate.splDB)                  // ≈ 79.8 dB
print(estimate.geometricAttenuationDB) // 40.0 dB
print(estimate.atmosphericAbsorptionDB)// ≈ 0.2 dB

// How far until the estimate falls to 90 dB?
let d = try Propagation.distance(forTargetSPLDB: 90, sourceSPLDB: 120, referenceDistanceM: 1, frequencyHz: 400)
print(d.distanceM)                     // ≈ 31.4 m

// ISO 9613-1 α and IEC 61672-1 A-weighting on their own.
let alpha = try ISO9613.alphaDBPerKilometre(frequencyHz: 1000, atmosphere: Atmosphere(humidityPercent: 50)) // ≈ 4.66 dB/km
let a = try AWeighting.decibels(atFrequencyHz: 400)  // ≈ -4.8 dB

// Energetic sum of separately measured chimes.
let total = Propagation.combinedLevelDB([112, 110, 109])
```

Invalid inputs (non-positive distances or frequencies, humidity outside 0–100 %) throw `TrainHornSPLError`.

## Command-line tool

```
swift run train-horn-spl spl --source 120 --ref 1 --at 100 --freq 400
distance_m=100.000 spl_db=79.78 geometric_db=40.00 absorption_db=0.215
alpha_db_per_km=2.173

swift run train-horn-spl distance --source 120 --ref 1 --target 90 --freq 400
swift run train-horn-spl aweight --freq 400
```

Optional atmosphere flags: `--temp C`, `--rh PCT`, `--kpa KPA` (defaults 20 °C, 70 %, 101.325 kPa).

## Tests

```
swift test
```

The test suite checks α against ISO 9613-1 formula checkpoints (within 1 %), A-weighting against the IEC 61672-1 nominal table (within 0.15 dB), the inverse-square identities, and that the distance solver round-trips with the forward model.

## References

- ISO 9613-1:1993, *Acoustics — Attenuation of sound during propagation outdoors — Part 1: Calculation of the absorption of sound by the atmosphere*.
- IEC 61672-1:2013, *Electroacoustics — Sound level meters — Part 1: Specifications*.

## License

MIT. See [LICENSE](LICENSE).
