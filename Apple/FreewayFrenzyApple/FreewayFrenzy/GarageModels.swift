import SwiftUI

enum CarBodyType: String, CaseIterable, Sendable {
    case sedan, sports, suv, truck
}

enum GarageTab: String, CaseIterable, Sendable {
    case vehicle, route, settings

    var label: String {
        switch self {
        case .vehicle: return "Garage"
        case .route: return "Route"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .vehicle: return "car.fill"
        case .route: return "map.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

enum TimeOfDay: String, CaseIterable, Sendable {
    case day, dusk, night, rain

    var label: String {
        switch self {
        case .day: return "Day"
        case .dusk: return "Dusk"
        case .night: return "Night"
        case .rain: return "Rain"
        }
    }

    var icon: String {
        switch self {
        case .day: return "sun.max.fill"
        case .dusk: return "sunset.fill"
        case .night: return "moon.fill"
        case .rain: return "cloud.rain.fill"
        }
    }
}

enum DifficultyLevel: String, CaseIterable, Sendable {
    case rookie, street, pro, legend

    var label: String {
        switch self {
        case .rookie: return "Rookie"
        case .street: return "Street"
        case .pro: return "Pro"
        case .legend: return "Legend"
        }
    }

    var color: Color {
        switch self {
        case .rookie: return Color(red: 0.18, green: 0.78, blue: 0.33)
        case .street: return Color(red: 1.0, green: 0.62, blue: 0.04)
        case .pro: return Color(red: 1.0, green: 0.42, blue: 0.21)
        case .legend: return Color(red: 0.90, green: 0.22, blue: 0.27)
        }
    }

    var speedMultiplier: CGFloat {
        switch self {
        case .rookie: return 0.82
        case .street: return 1.0
        case .pro: return 1.18
        case .legend: return 1.35
        }
    }

    var spawnMultiplier: CGFloat {
        switch self {
        case .rookie: return 1.35
        case .street: return 1.0
        case .pro: return 0.82
        case .legend: return 0.68
        }
    }
}

struct VehicleDefinition: Identifiable, Sendable, Equatable {
    let id: String
    let name: String
    let subtitle: String
    let type: CarBodyType
    let defaultColorHex: UInt32
    let speed: Int
    let handling: Int
    let durability: Int
    let nitro: Int

    static let catalog: [VehicleDefinition] = [
        VehicleDefinition(id: "v1", name: "APEX RUNNER", subtitle: "Sports", type: .sports,
                          defaultColorHex: 0xE63946, speed: 95, handling: 88, durability: 50, nitro: 80),
        VehicleDefinition(id: "v2", name: "DELTA CRUISER", subtitle: "Sedan", type: .sedan,
                          defaultColorHex: 0x457B9D, speed: 65, handling: 75, durability: 80, nitro: 55),
        VehicleDefinition(id: "v3", name: "TITAN BLOCK", subtitle: "SUV", type: .suv,
                          defaultColorHex: 0x2DC653, speed: 52, handling: 58, durability: 97, nitro: 40),
        VehicleDefinition(id: "v4", name: "HAULER X9", subtitle: "Truck", type: .truck,
                          defaultColorHex: 0xF4A261, speed: 42, handling: 44, durability: 100, nitro: 30),
    ]
}

struct PaintOption: Identifiable, Sendable, Equatable {
    let id: String
    let hex: UInt32

    var color: Color { Color(hex: hex) }

    static let catalog: [PaintOption] = [
        PaintOption(id: "p1", hex: 0xE63946),
        PaintOption(id: "p2", hex: 0xFF6B35),
        PaintOption(id: "p3", hex: 0xFF9F0A),
        PaintOption(id: "p4", hex: 0xF4D35E),
        PaintOption(id: "p5", hex: 0x2DC653),
        PaintOption(id: "p6", hex: 0x00C2A0),
        PaintOption(id: "p7", hex: 0x457B9D),
        PaintOption(id: "p8", hex: 0x6A4C93),
        PaintOption(id: "p9", hex: 0xE8E8E8),
        PaintOption(id: "p10", hex: 0x2C2C2C),
    ]
}

struct RouteDefinition: Identifiable, Sendable, Equatable {
    let id: String
    let name: String
    let laps: Int
    let km: String
    let difficultyTag: String
    let tagColorHex: UInt32

    var tagColor: Color { Color(hex: tagColorHex) }

    static let catalog: [RouteDefinition] = [
        RouteDefinition(id: "r1", name: "Downtown Grid", laps: 3, km: "4.2", difficultyTag: "MEDIUM", tagColorHex: 0xFF9F0A),
        RouteDefinition(id: "r2", name: "Harbor Loop", laps: 2, km: "7.8", difficultyTag: "HARD", tagColorHex: 0xE63946),
        RouteDefinition(id: "r3", name: "Industrial Cut", laps: 5, km: "2.1", difficultyTag: "EASY", tagColorHex: 0x2DC653),
        RouteDefinition(id: "r4", name: "Midnight Express", laps: 1, km: "12.4", difficultyTag: "EXTREME", tagColorHex: 0x9B2226),
    ]
}

struct GarageSettings: Sendable, Equatable {
    var timeOfDay: TimeOfDay = .day
    var difficulty: DifficultyLevel = .street
    var traffic: Int = 40
    var aggression: Int = 55
    var nitroBoosts: Int = 3
    var policeChase: Bool = false
    var wetRoads: Bool = false
    var ghostMode: Bool = false
}

enum GarageCatalog {
    static func darken(_ hex: UInt32, factor: Double) -> UInt32 {
        let r = Int(Double((hex >> 16) & 0xFF) * factor)
        let g = Int(Double((hex >> 8) & 0xFF) * factor)
        let b = Int(Double(hex & 0xFF) * factor)
        return UInt32((r << 16) | (g << 8) | b)
    }

    static func hexString(_ hex: UInt32) -> String {
        String(format: "#%06X", hex)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}
