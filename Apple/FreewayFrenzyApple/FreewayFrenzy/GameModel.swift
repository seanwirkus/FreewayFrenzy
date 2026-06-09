import CoreGraphics
import Foundation

enum GamePhase: Sendable {
    case menu
    case playing
    case crash
    case gameOver
}

struct CarStyle: Equatable {
    let name: String
    let bodyHex: UInt32
    let roofHex: UInt32

    static let catalog = [
        CarStyle(name: "Crimson", bodyHex: 0xD90429, roofHex: 0xA3031F),
        CarStyle(name: "Ocean Blue", bodyHex: 0x1E90FF, roofHex: 0x1565C0),
        CarStyle(name: "Lime", bodyHex: 0x32CD32, roofHex: 0x228B22),
        CarStyle(name: "Gold", bodyHex: 0xFFD700, roofHex: 0xDAA520),
        CarStyle(name: "Purple", bodyHex: 0x9B59B6, roofHex: 0x7D3C98),
        CarStyle(name: "Hot Pink", bodyHex: 0xFF69B4, roofHex: 0xDB2777),
        CarStyle(name: "Orange", bodyHex: 0xFF8C00, roofHex: 0xCC7000),
        CarStyle(name: "Silver", bodyHex: 0xC0C0C0, roofHex: 0x909090),
        CarStyle(name: "Mint", bodyHex: 0x2EE6A6, roofHex: 0x168C68),
        CarStyle(name: "Sky", bodyHex: 0x73D2FF, roofHex: 0x2E86B8),
        CarStyle(name: "Grape", bodyHex: 0x6C5CE7, roofHex: 0x3D348B),
        CarStyle(name: "Taxi", bodyHex: 0xFFC300, roofHex: 0x2B2B2B)
    ]
}

struct Obstacle {
    var active = false
    var y: CGFloat = 0
    var lane = 0
    var type = 0
}

struct Collectible {
    var active = false
    var y: CGFloat = 0
    var lane = 0
    var rot: CGFloat = 0
}

struct Debris {
    var active = true
    var position: CGPoint
    var velocity: CGVector
    var size: CGFloat
    var colorHex: UInt32
}

struct GameInput {
    var steer: CGFloat = 0
    var throttle: CGFloat = 0
    var startPressed = false
    var menuPressed = false
}

final class GameModel {
    static let logicSize = CGSize(width: 300, height: 512)
    static let renderSize = CGSize(width: 600, height: 1024)

    let laneCount = 5
    let laneWidth: CGFloat = 50
    let shoulderWidth: CGFloat = 15
    let carSize = CGSize(width: 28, height: 45)
    let obstacleSize = CGSize(width: 26, height: 42)
    let maxObstacles = 12
    let maxCoins = 15
    let crashDuration: TimeInterval = 1.2
    let spawnY: CGFloat = -96

    let carStyles = CarStyle.catalog
    let obstacleColors: [UInt32] = [0x1E90FF, 0xFFD700, 0x32CD32, 0xFF6347, 0x9370DB, 0xE0E0E0]

    var phase: GamePhase = .menu
    var selectedCarIndex = 0
    var carX: CGFloat = 0
    var targetLane = 2
    var speed: CGFloat = 0
    var baseSpeed: CGFloat = 75
    var roadScroll: CGFloat = 0
    var distance: CGFloat = 0
    var score = 0
    var coinsCollected = 0
    var highScore = UserDefaults.standard.integer(forKey: "FreewayFrenzyHighScore")
    var obstacles: [Obstacle]
    var coins: [Collectible]
    var debris: [Debris] = []
    var lastSpawnDistance: CGFloat = 0
    var spawnSerial = 0
    var crashStartTime: TimeInterval = 0
    var crashObstacleLane = -1
    var crashObstacleY: CGFloat = 0
    var crashSpeed: CGFloat = 0
    var lastLaneChangeTime: TimeInterval = 0
    var boostHold: TimeInterval = 0
    var playerCrashOffset = CGVector.zero
    var obstacleCrashOffset = CGVector.zero
    var cameraShake = CGVector.zero

    private var rng: UInt32 = 12_345
    private var previousStart = false
    private var previousMenu = false
    private var menuColorDebounce: TimeInterval = 0

    init() {
        obstacles = Array(repeating: Obstacle(), count: maxObstacles)
        coins = Array(repeating: Collectible(), count: maxCoins)
        reset(keepPhase: true)
        phase = .menu
    }

    var roadLeft: CGFloat {
        (Self.logicSize.width - (CGFloat(laneCount) * laneWidth + shoulderWidth * 2)) / 2
    }

    var roadSurfaceLeft: CGFloat {
        roadLeft + shoulderWidth
    }

    var carY: CGFloat {
        Self.logicSize.height - carSize.height - 15
    }

    func laneCenter(_ lane: Int) -> CGFloat {
        roadSurfaceLeft + laneWidth / 2 + CGFloat(clampedLane(lane)) * laneWidth
    }

    var selectedCarStyle: CarStyle {
        guard !carStyles.isEmpty else {
            return CarStyle(name: "Crimson", bodyHex: 0xD90429, roofHex: 0xA3031F)
        }
        selectedCarIndex = selectedCarIndex.clamped(to: 0...(carStyles.count - 1))
        return carStyles[selectedCarIndex]
    }

    func obstacleColorHex(for type: Int) -> UInt32 {
        guard !obstacleColors.isEmpty else { return 0x1E90FF }
        return obstacleColors[type.positiveModulo(obstacleColors.count)]
    }

    func clampedLane(_ lane: Int) -> Int {
        lane.clamped(to: 0...(laneCount - 1))
    }

    func nudgeLane(_ direction: Int, now: TimeInterval) {
        let debounce: TimeInterval = phase == .menu ? 0.18 : 0.045
        guard direction != 0, now - lastLaneChangeTime >= debounce else { return }

        if phase == .menu {
            if direction < 0 {
                selectedCarIndex = (selectedCarIndex + carStyles.count - 1).positiveModulo(carStyles.count)
            } else {
                selectedCarIndex = (selectedCarIndex + 1).positiveModulo(carStyles.count)
            }
            lastLaneChangeTime = now
            return
        }

        guard phase == .playing else { return }
        let newLane = max(0, min(laneCount - 1, targetLane + direction))
        guard newLane != targetLane else { return }
        targetLane = newLane
        lastLaneChangeTime = now
    }

    func selectCar(_ index: Int) {
        guard phase == .menu, !carStyles.isEmpty else { return }
        selectedCarIndex = index.clamped(to: 0...(carStyles.count - 1))
    }

    func update(deltaTime rawDelta: TimeInterval, now: TimeInterval, input: GameInput) {
        let deltaTime = min(max(rawDelta, 0), 0.1)
        let startEdge = input.startPressed && !previousStart
        let menuEdge = input.menuPressed && !previousMenu
        previousStart = input.startPressed
        previousMenu = input.menuPressed

        if startEdge, (phase == .menu || phase == .gameOver) {
            reset(keepPhase: false)
            phase = .playing
        }

        if menuEdge, phase == .gameOver {
            phase = .menu
        }

        if phase == .menu {
            roadScroll = wrapRoadScroll(roadScroll + 40 * deltaTime)
            speed = 0
            carX = laneCenter(2)
            updateMenuColor(now: now, steer: input.steer)
            return
        }

        if phase == .gameOver {
            return
        }

        if phase == .crash {
            updateCrash(deltaTime: deltaTime, now: now)
            return
        }

        updatePlaying(deltaTime: deltaTime, now: now, input: input)
    }

    func reset(keepPhase: Bool) {
        let currentPhase = phase
        carX = laneCenter(2)
        targetLane = 2
        speed = 0
        baseSpeed = 75
        distance = 0
        score = 0
        coinsCollected = 0
        obstacles = Array(repeating: Obstacle(), count: maxObstacles)
        coins = Array(repeating: Collectible(), count: maxCoins)
        debris.removeAll()
        lastSpawnDistance = 0
        spawnSerial = 0
        crashStartTime = 0
        crashObstacleLane = -1
        crashObstacleY = 0
        crashSpeed = 0
        lastLaneChangeTime = 0
        boostHold = 0
        playerCrashOffset = .zero
        obstacleCrashOffset = .zero
        cameraShake = .zero
        phase = keepPhase ? currentPhase : .playing
    }

    private func updateMenuColor(now: TimeInterval, steer: CGFloat) {
        guard now - menuColorDebounce > 0.28 else { return }
        if steer < -40 {
            selectedCarIndex = (selectedCarIndex + carStyles.count - 1).positiveModulo(carStyles.count)
            menuColorDebounce = now
        } else if steer > 40 {
            selectedCarIndex = (selectedCarIndex + 1).positiveModulo(carStyles.count)
            menuColorDebounce = now
        }
    }

    private func updatePlaying(deltaTime: TimeInterval, now: TimeInterval, input: GameInput) {
        let dt = CGFloat(deltaTime)

        let targetX = laneCenter(targetLane)
        carX += (targetX - carX) * min(22 * dt, 1)

        baseSpeed = min(75 + distance * 0.045, 250)
        let speedModifier = input.throttle * 0.01
        let boosting = speedModifier > 0.1
        boostHold = boosting ? min(boostHold + deltaTime, 4) : max(boostHold - deltaTime * 2.4, 0)

        let boostRamp = min(boostHold / 4, 1)
        let boostCurve = normalizedExpRamp(CGFloat(boostRamp))
        let targetSpeed: CGFloat
        if boosting {
            targetSpeed = min(baseSpeed * (1 + speedModifier * (0.55 + boostCurve * 1.75)), 820)
        } else if speedModifier < -0.1 {
            targetSpeed = max(baseSpeed * (1 + speedModifier * 0.75), 15)
        } else {
            targetSpeed = baseSpeed
        }

        let speedLerp: CGFloat = speedModifier < -0.1 ? 5 : (boosting ? 3.2 + boostCurve * 2.4 : 3)
        speed += (targetSpeed - speed) * speedLerp * dt
        speed = max(speed, 0)

        roadScroll = wrapRoadScroll(roadScroll + speed * 2.5 * dt)
        distance += speed * dt * 0.3
        score = Int(distance / 10)

        lastSpawnDistance += speed * 2 * dt
        let spawnGap = max(140 - CGFloat(score) * 0.8, 70)
        var spawnsThisFrame = 0
        while lastSpawnDistance >= spawnGap, spawnsThisFrame < 2 {
            lastSpawnDistance -= spawnGap
            spawnOne()
            spawnsThisFrame += 1
        }
        if lastSpawnDistance >= spawnGap {
            lastSpawnDistance = spawnGap * 0.5
        }

        let obstacleSpeed = speed * 1.8 + 30
        for index in obstacles.indices where obstacles[index].active {
            obstacles[index].y += obstacleSpeed * dt
            if obstacles[index].y > Self.logicSize.height + 50 {
                obstacles[index].active = false
            }
        }

        let coinSpeed = speed * 1.8 + 30
        for index in coins.indices where coins[index].active {
            coins[index].y += coinSpeed * dt
            coins[index].rot += dt * 4.0
            if coins[index].y > Self.logicSize.height + 50 {
                coins[index].active = false
            }
        }

        detectCollision(now: now)
    }

    private func updateCrash(deltaTime: TimeInterval, now: TimeInterval) {
        let dt = CGFloat(deltaTime)
        speed *= max(0, 1 - 3 * dt)
        if speed < 5 { speed = 0 }
        roadScroll = wrapRoadScroll(roadScroll + speed * 2.5 * dt)

        let elapsed = min(CGFloat((now - crashStartTime) / crashDuration), 1)
        let push = crashSpeed * 0.5
        playerCrashOffset.dy += push * 0.3 * dt
        playerCrashOffset.dx += push * 0.1 * dt
        obstacleCrashOffset.dy -= push * 0.4 * dt
        obstacleCrashOffset.dx -= push * 0.05 * dt
        let shake = min((1 - elapsed) * (crashSpeed / 40), 8)
        cameraShake = CGVector(dx: CGFloat.random(in: -shake...shake), dy: CGFloat.random(in: -shake...shake))
        updateDebris(deltaTime: dt)

        if now - crashStartTime >= crashDuration {
            if score > highScore {
                highScore = score
                UserDefaults.standard.set(highScore, forKey: "FreewayFrenzyHighScore")
            }
            phase = .gameOver
            cameraShake = .zero
        }
    }

    func crashProgress(now: TimeInterval) -> CGFloat {
        guard phase == .crash else { return 0 }
        return min(max(CGFloat((now - crashStartTime) / crashDuration), 0), 1)
    }

    private func detectCollision(now: TimeInterval) {
        let carRect = CGRect(x: carX - carSize.width / 2, y: carY, width: carSize.width, height: carSize.height)
        
        for index in coins.indices where coins[index].active {
            let cx = laneCenter(coins[index].lane)
            let coinRect = CGRect(x: cx - 12, y: coins[index].y - 12, width: 24, height: 24)
            if carRect.intersects(coinRect) {
                coins[index].active = false
                coinsCollected += 1
                score += 5
                // Sound will be played by view controller via an action or we can just observe score jump
            }
        }

        for obstacle in obstacles where obstacle.active {
            let ox = laneCenter(obstacle.lane)
            let obstacleRect = CGRect(x: ox - obstacleSize.width / 2, y: obstacle.y, width: obstacleSize.width, height: obstacleSize.height)
            if carRect.intersects(obstacleRect) {
                phase = .crash
                crashStartTime = now
                crashSpeed = speed
                crashObstacleLane = obstacle.lane
                crashObstacleY = obstacle.y
                playerCrashOffset = .zero
                obstacleCrashOffset = .zero
                spawnDebris(at: CGPoint(x: (carX + ox) * 0.5, y: (carY + obstacle.y) * 0.5), speed: speed)
                return
            }
        }
    }

    private func spawnOne() {
        spawnSerial += 1
        guard let lane = nextSpawnLane(spawnY: spawnY) else { return }
        let activeObstacles = obstacles.filter(\.active).count
        let activeCoins = coins.filter(\.active).count
        let laneHasRecentObstacle = obstacles.contains { $0.active && $0.lane == lane && abs($0.y - spawnY) < 260 }
        let isCoin = (fastRand() % 100) < (laneHasRecentObstacle ? 58 : 30)

        if isCoin {
            if activeCoins < maxCoins {
                for index in coins.indices where !coins[index].active {
                    coins[index] = Collectible(active: true, y: spawnY, lane: lane, rot: 0)
                    return
                }
            }
        } else {
            guard activeObstacles < min(2 + score / 18, 8) else { return }
            for index in obstacles.indices where !obstacles[index].active {
                obstacles[index] = Obstacle(active: true, y: spawnY, lane: lane, type: Int(fastRand() % 6))
                return
            }
        }
    }

    private func nextSpawnLane(spawnY: CGFloat) -> Int? {
        let start = Int(fastRand() % UInt32(max(laneCount, 1)))
        let preferredOffset = spawnSerial % laneCount
        for step in 0..<laneCount {
            let lane = (start + preferredOffset + step * 2).positiveModulo(laneCount)
            if laneClear(lane: lane, spawnY: spawnY) {
                return lane
            }
        }
        return nil
    }

    private func laneClear(lane: Int, spawnY: CGFloat) -> Bool {
        for obstacle in obstacles where obstacle.active && obstacle.lane == lane {
            if abs(obstacle.y - spawnY) < 230 {
                return false
            }
        }
        for coin in coins where coin.active && coin.lane == lane {
            if abs(coin.y - spawnY) < 110 {
                return false
            }
        }
        let activeAtSpawn = obstacles.filter { $0.active && abs($0.y - spawnY) < 150 }.count
        if activeAtSpawn >= 1 { return false }
        return true
    }

    private func spawnDebris(at point: CGPoint, speed: CGFloat) {
        let colors: [UInt32] = [0xFF4400, 0xFFAA00, 0xFF0000, 0xCCCCCC, 0x888888, 0xFFFF44]
        debris = (0..<10).map { _ in
            let angle = CGFloat.random(in: 0..<(CGFloat.pi * 2))
            let magnitude = CGFloat.random(in: 60...(speed * 1.2 + 100))
            return Debris(
                position: CGPoint(x: point.x + CGFloat.random(in: -15...15), y: point.y + CGFloat.random(in: -15...15)),
                velocity: CGVector(dx: cos(angle) * magnitude, dy: sin(angle) * magnitude),
                size: CGFloat.random(in: 2...8),
                colorHex: colors.randomElement() ?? 0xFFAA00
            )
        }
    }

    private func updateDebris(deltaTime dt: CGFloat) {
        for index in debris.indices where debris[index].active {
            debris[index].position.x += debris[index].velocity.dx * dt
            debris[index].position.y += debris[index].velocity.dy * dt
            debris[index].velocity.dy += 200 * dt
            debris[index].velocity.dx *= 0.97
            debris[index].size -= 2.5 * dt
            if debris[index].size <= 0.5 || debris[index].position.y > Self.logicSize.height + 20 {
                debris[index].active = false
            }
        }
    }

    private func normalizedExpRamp(_ t: CGFloat) -> CGFloat {
        guard t > 0 else { return 0 }
        guard t < 1 else { return 1 }
        let k: CGFloat = 2.35
        return (exp(k * t) - 1) / (exp(k) - 1)
    }

    private func wrapRoadScroll(_ value: CGFloat) -> CGFloat {
        value > 100_000 ? value - 100_000 : value
    }

    private func fastRand() -> UInt32 {
        rng ^= rng << 13
        rng ^= rng >> 17
        rng ^= rng << 5
        return rng
    }
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }

    func positiveModulo(_ divisor: Int) -> Int {
        guard divisor > 0 else { return 0 }
        let result = self % divisor
        return result >= 0 ? result : result + divisor
    }
}
