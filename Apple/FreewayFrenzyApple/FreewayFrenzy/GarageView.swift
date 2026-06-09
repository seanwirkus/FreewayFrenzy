import SwiftUI

struct GarageView: View {
    @ObservedObject var state: GameHUDState
    let viewport: CGSize
    let safeArea: EdgeInsets

    var body: some View {
        let layout = Layout(size: viewport, safeArea: safeArea)

        ZStack(alignment: .top) {
            garageBackdrop

            if layout.wide {
                wideLayout(layout)
            } else {
                phoneLayout(layout)
            }
        }
        .frame(width: viewport.width, height: viewport.height, alignment: .top)
        .ignoresSafeArea(.all)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Layout metrics

    private struct Layout {
        let size: CGSize
        let safeArea: EdgeInsets

        var wide: Bool { size.width >= 560 }
        var compact: Bool { size.width < 390 || size.height < 760 }
        var cramped: Bool { size.height < 670 }

        var horizontalPadding: CGFloat {
            #if os(macOS)
            44
            #else
            0
            #endif
        }

        var edgePadding: CGFloat {
            #if os(macOS)
            0
            #else
            12
            #endif
        }

        var contentGap: CGFloat { cramped ? 6 : 8 }

        var topInset: CGFloat { safeArea.top + 6 }
        var bottomInset: CGFloat { safeArea.bottom + 8 }

        var showcaseHeight: CGFloat {
            if wide { return 190 }
            return cramped ? 128 : (compact ? 148 : 168)
        }

        var carScale: CGFloat {
            if wide { return 1.05 }
            return cramped ? 0.78 : (compact ? 0.88 : 0.96)
        }

        var paintColumns: Int {
            let usable = size.width - edgePadding * 2 - 28
            return max(5, min(10, Int(usable / 36)))
        }

        var leftPanelWidth: CGFloat { min(280, size.width * 0.34) }
    }

    // MARK: - Backdrop

    private var garageBackdrop: some View {
        ZStack {
            FreewayFrenzyUI.garageBackground
            RadialGradient(
                colors: [FreewayFrenzyUI.garageAccent.opacity(0.08), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 480
            )
            RadialGradient(
                colors: [FreewayFrenzyUI.garageAccentAlt.opacity(0.05), .clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 560
            )
            gridOverlay
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all)
    }

    private var gridOverlay: some View {
        Canvas { context, size in
            let step: CGFloat = 32
            var path = Path()
            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += step
            }
            var x: CGFloat = 0
            while x <= size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += step
            }
            context.stroke(path, with: .color(FreewayFrenzyUI.garageAccent.opacity(0.04)), lineWidth: 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Phone layout

    private func phoneLayout(_ layout: Layout) -> some View {
        VStack(spacing: layout.contentGap) {
            garageHeader(layout)
                .padding(.horizontal, layout.edgePadding)
                .padding(.top, layout.topInset)

            tabBar
                .padding(.horizontal, layout.edgePadding)

            showcasePanel(layout)
                .padding(.horizontal, layout.edgePadding)

            ScrollView(.vertical, showsIndicators: false) {
                tabContent(layout)
                    .padding(14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .garagePanel()
            .padding(.horizontal, layout.edgePadding)

            configBar
                .padding(.horizontal, layout.edgePadding)

            raceButton
                .padding(.horizontal, layout.edgePadding)
                .padding(.bottom, layout.bottomInset)
        }
        .padding(.horizontal, layout.horizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Wide layout

    private func wideLayout(_ layout: Layout) -> some View {
        VStack(spacing: layout.contentGap) {
            garageHeader(layout)
                .padding(.horizontal, layout.horizontalPadding)
                .padding(.top, layout.topInset)

            HStack(alignment: .top, spacing: layout.contentGap) {
                VStack(spacing: layout.contentGap) {
                    tabBar
                    ScrollView(.vertical, showsIndicators: false) {
                        tabContent(layout)
                            .padding(14)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .garagePanel()
                }
                .frame(width: layout.leftPanelWidth)

                VStack(spacing: layout.contentGap) {
                    showcasePanel(layout)
                    configBar
                    Spacer(minLength: 0)
                    raceButton
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, layout.horizontalPadding)
            .padding(.bottom, layout.bottomInset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    // MARK: - Header

    private func garageHeader(_ layout: Layout) -> some View {
        HStack(alignment: .center) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: FreewayFrenzyUI.garageBlockRadius, style: .continuous)
                    .fill(FreewayFrenzyUI.garageAccent.opacity(0.12))
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: FreewayFrenzyUI.garageBlockRadius, style: .continuous)
                            .stroke(FreewayFrenzyUI.garageAccent.opacity(0.4), lineWidth: 2)
                    )
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .black))
                            .foregroundStyle(FreewayFrenzyUI.garageAccent)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text("FreewayFrenzy")
                        .font(.system(size: layout.compact ? 20 : 22, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [FreewayFrenzyUI.garageAccent, FreewayFrenzyUI.garageAccentAlt],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("CUSTOMIZE · RACE · WIN")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(FreewayFrenzyUI.garageLabel)
                }
            }

            Spacer(minLength: 8)

            if state.highScore > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(FreewayFrenzyUI.garageAccent)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("BEST")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(FreewayFrenzyUI.garageLabel)
                        Text("\(state.highScore)")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(FreewayFrenzyUI.garageAccent)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .garagePanel()
            }
        }
    }

    // MARK: - Tabs

    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(GarageTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeOut(duration: 0.15)) {
                        state.garageTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                        Text(tab.label)
                    }
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(state.garageTab == tab ? FreewayFrenzyUI.garageAccent : FreewayFrenzyUI.garageLabel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(FreewayFrenzyUI.GarageButtonStyle(selected: state.garageTab == tab))
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.3))
        .overlay(
            RoundedRectangle(cornerRadius: FreewayFrenzyUI.garageBlockRadius, style: .continuous)
                .stroke(FreewayFrenzyUI.garageBorder.opacity(0.55), lineWidth: 2)
        )
    }

    @ViewBuilder
    private func tabContent(_ layout: Layout) -> some View {
        switch state.garageTab {
        case .vehicle:
            vehicleTab(layout)
        case .route:
            routeTab
        case .settings:
            settingsTab
        }
    }

    // MARK: - Vehicle tab

    private func vehicleTab(_ layout: Layout) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            FreewayFrenzyUI.SectionHeading(icon: "car.fill", title: "Choose Your Ride")

            ForEach(Array(VehicleDefinition.catalog.enumerated()), id: \.element.id) { index, vehicle in
                vehicleRow(index: index, vehicle: vehicle)
            }

            FreewayFrenzyUI.SectionHeading(icon: "paintbrush.fill", title: "Paint Job")
            paintGrid(columns: layout.paintColumns)

            FreewayFrenzyUI.SectionHeading(icon: "bolt.fill", title: "Nitro Boosts")
            nitroPicker
        }
    }

    private func vehicleRow(index: Int, vehicle: VehicleDefinition) -> some View {
        let selected = state.selectedVehicleIndex == index
        let displayColor = selected ? state.paintColor : Color(hex: vehicle.defaultColorHex)
        return Button {
            state.inputHandler?.selectVehicle(index)
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    IsoCarView(type: vehicle.type, color: displayColor, scale: 0.55)
                        .frame(width: 78, height: 56)
                        .clipped()
                }
                .frame(width: 78, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(vehicle.name)
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(selected ? FreewayFrenzyUI.garageAccent : FreewayFrenzyUI.garageText)
                            Text(vehicle.subtitle)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(FreewayFrenzyUI.garageLabel)
                        }
                        Spacer()
                        if selected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(Color(red: 0.10, green: 0.07, blue: 0.03))
                                .frame(width: 18, height: 18)
                                .background(FreewayFrenzyUI.garageAccent, in: RoundedRectangle(cornerRadius: FreewayFrenzyUI.garageBlockRadius))
                        }
                    }
                    FreewayFrenzyUI.StatBar(label: "SPD", value: vehicle.speed, color: Color(red: 0.90, green: 0.22, blue: 0.27))
                    FreewayFrenzyUI.StatBar(label: "HND", value: vehicle.handling, color: FreewayFrenzyUI.garageAccent)
                    FreewayFrenzyUI.StatBar(label: "DUR", value: vehicle.durability, color: Color(red: 0.18, green: 0.78, blue: 0.33))
                }
            }
            .padding(10)
            .contentShape(Rectangle())
        }
        .buttonStyle(FreewayFrenzyUI.GarageButtonStyle(selected: selected))
    }

    private func paintGrid(columns: Int) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(28), spacing: 8), count: columns), spacing: 8) {
            ForEach(Array(PaintOption.catalog.enumerated()), id: \.element.id) { index, paint in
                Button {
                    state.inputHandler?.selectPaint(index)
                } label: {
                    RoundedRectangle(cornerRadius: FreewayFrenzyUI.garageBlockRadius, style: .continuous)
                        .fill(paint.color)
                        .frame(width: 28, height: 28)
                        .overlay(
                            RoundedRectangle(cornerRadius: FreewayFrenzyUI.garageBlockRadius, style: .continuous)
                                .stroke(state.selectedPaintIndex == index ? FreewayFrenzyUI.garageText : Color.black.opacity(0.4), lineWidth: 2)
                        )
                        .shadow(color: state.selectedPaintIndex == index ? paint.color.opacity(0.6) : .clear, radius: 6)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var nitroPicker: some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { level in
                Button {
                    state.inputHandler?.setNitroBoosts(level)
                } label: {
                    Text("\(level)")
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .foregroundStyle(level <= state.nitroBoosts ? FreewayFrenzyUI.garageAccentAlt : FreewayFrenzyUI.garageLabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(FreewayFrenzyUI.GarageButtonStyle(selected: level <= state.nitroBoosts))
            }
        }
    }

    // MARK: - Route tab

    private var routeTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            FreewayFrenzyUI.SectionHeading(icon: "map.fill", title: "Pick a Route")

            ForEach(Array(RouteDefinition.catalog.enumerated()), id: \.element.id) { index, route in
                let selected = state.selectedRouteIndex == index
                Button {
                    state.inputHandler?.selectRoute(index)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(route.name)
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(selected ? FreewayFrenzyUI.garageAccent : FreewayFrenzyUI.garageText)
                            Spacer()
                            Text(route.difficultyTag)
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .tracking(1)
                                .foregroundStyle(route.tagColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(route.tagColor.opacity(0.13), in: RoundedRectangle(cornerRadius: FreewayFrenzyUI.garageBlockRadius))
                                .overlay(
                                    RoundedRectangle(cornerRadius: FreewayFrenzyUI.garageBlockRadius, style: .continuous)
                                        .stroke(route.tagColor.opacity(0.33), lineWidth: 2)
                                )
                        }
                        HStack(spacing: 16) {
                            Label("\(route.laps) Laps", systemImage: "arrow.triangle.2.circlepath")
                            Label("\(route.km) km", systemImage: "ruler")
                        }
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(FreewayFrenzyUI.garageLabel)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(FreewayFrenzyUI.GarageButtonStyle(selected: selected))
            }

            FreewayFrenzyUI.SectionHeading(icon: "sun.max.fill", title: "Time of Day")
            timeOfDayGrid
        }
    }

    private var timeOfDayGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(TimeOfDay.allCases, id: \.self) { tod in
                Button {
                    state.inputHandler?.setTimeOfDay(tod)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tod.icon)
                        Text(tod.label)
                    }
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(state.timeOfDay == tod ? FreewayFrenzyUI.garageAccent : FreewayFrenzyUI.garageLabel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(FreewayFrenzyUI.GarageButtonStyle(selected: state.timeOfDay == tod))
            }
        }
    }

    // MARK: - Settings tab

    private var settingsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            FreewayFrenzyUI.SectionHeading(icon: "flag.fill", title: "Difficulty")
            difficultyGrid

            FreewayFrenzyUI.SectionHeading(icon: "car.2.fill", title: "Traffic")
            FreewayFrenzyUI.BlockySlider(label: "Density", value: trafficBinding, icon: "car.fill")
            FreewayFrenzyUI.BlockySlider(label: "Aggression", value: aggressionBinding, color: FreewayFrenzyUI.garageAccentAlt, icon: "flame.fill")

            FreewayFrenzyUI.SectionHeading(icon: "gamecontroller.fill", title: "Game Rules")
            FreewayFrenzyUI.BlockyToggle(label: "Police Chase", icon: "light.beacon.max.fill", isOn: policeBinding)
            FreewayFrenzyUI.BlockyToggle(label: "Wet Roads", icon: "cloud.rain.fill", isOn: wetRoadsBinding)
            FreewayFrenzyUI.BlockyToggle(label: "Ghost Mode", icon: "shield.fill", isOn: ghostBinding)
        }
    }

    private var difficultyGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(DifficultyLevel.allCases, id: \.self) { level in
                Button {
                    state.inputHandler?.setDifficulty(level)
                } label: {
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: FreewayFrenzyUI.garageBlockRadius, style: .continuous)
                            .fill(state.difficulty == level ? level.color : Color.white.opacity(0.15))
                            .frame(width: 12, height: 12)
                        Text(level.label)
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(state.difficulty == level ? level.color : FreewayFrenzyUI.garageLabel)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(FreewayFrenzyUI.GarageButtonStyle(selected: state.difficulty == level))
            }
        }
    }

    // MARK: - Showcase + config

    private var selectedVehicle: VehicleDefinition {
        VehicleDefinition.catalog[state.selectedVehicleIndex.clamped(to: 0...(VehicleDefinition.catalog.count - 1))]
    }

    private var selectedRoute: RouteDefinition {
        RouteDefinition.catalog[state.selectedRouteIndex.clamped(to: 0...(RouteDefinition.catalog.count - 1))]
    }

    private func showcasePanel(_ layout: Layout) -> some View {
        VStack(spacing: 0) {
            ZStack {
                Ellipse()
                    .fill(state.paintColor.opacity(0.18))
                    .frame(width: min(layout.size.width * 0.72, 300), height: layout.showcaseHeight * 0.65)
                    .offset(y: layout.showcaseHeight * 0.22)

                if layout.wide {
                    HStack(alignment: .bottom, spacing: 12) {
                        IsoCarView(type: selectedVehicle.type, color: state.paintColor, scale: layout.carScale)
                            .frame(maxWidth: .infinity)
                            .frame(height: layout.showcaseHeight - 20)
                        showcaseStats
                            .frame(width: 170, alignment: .leading)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                } else {
                    VStack(spacing: 8) {
                        IsoCarView(type: selectedVehicle.type, color: state.paintColor, scale: layout.carScale)
                            .frame(height: layout.showcaseHeight * 0.55)
                        showcaseStats
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }
            .frame(height: layout.showcaseHeight)
        }
        .garagePanel()
    }

    private var showcaseStats: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(selectedVehicle.name)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(FreewayFrenzyUI.garageText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text("\(selectedVehicle.subtitle) Class")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(FreewayFrenzyUI.garageLabel)
            FreewayFrenzyUI.StatBar(label: "SPD", value: selectedVehicle.speed, color: Color(red: 0.90, green: 0.22, blue: 0.27))
            FreewayFrenzyUI.StatBar(label: "HND", value: selectedVehicle.handling, color: FreewayFrenzyUI.garageAccent)
            FreewayFrenzyUI.StatBar(label: "DUR", value: selectedVehicle.durability, color: Color(red: 0.18, green: 0.78, blue: 0.33))
            FreewayFrenzyUI.StatBar(label: "NOS", value: selectedVehicle.nitro, color: Color(red: 0.27, green: 0.48, blue: 0.61))
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: FreewayFrenzyUI.garageBlockRadius, style: .continuous)
                    .fill(state.paintColor)
                    .frame(width: 20, height: 20)
                    .overlay(RoundedRectangle(cornerRadius: FreewayFrenzyUI.garageBlockRadius).stroke(.white.opacity(0.5), lineWidth: 2))
                Text(GarageCatalog.hexString(state.paintHex).uppercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(FreewayFrenzyUI.garageLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var configBar: some View {
        HStack(spacing: 0) {
            configItem(icon: "map.fill", label: "ROUTE", value: selectedRoute.name)
            configItem(icon: "arrow.triangle.2.circlepath", label: "LAPS", value: "\(selectedRoute.laps)x")
            configItem(icon: "ruler", label: "DIST", value: "\(selectedRoute.km) km")
            configItem(icon: "flag.fill", label: "DIFF", value: state.difficulty.label, tint: state.difficulty.color)
            configItem(icon: "bolt.fill", label: "NITRO", value: "x\(state.nitroBoosts)")
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .garagePanel()
    }

    private func configItem(icon: String, label: String, value: String, tint: Color = FreewayFrenzyUI.garageText) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(FreewayFrenzyUI.garageAccent)
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(FreewayFrenzyUI.garageLabel)
            Text(value)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity)
    }

    private var raceButton: some View {
        Button {
            state.inputHandler?.tap()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                Text("RACE")
            }
            .font(.system(size: 20, weight: .black, design: .rounded))
            .tracking(1)
            .foregroundStyle(Color(red: 0.10, green: 0.07, blue: 0.03))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [FreewayFrenzyUI.garageAccent, FreewayFrenzyUI.garageAccentAlt],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: FreewayFrenzyUI.garageBlockRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: FreewayFrenzyUI.garageBlockRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 2)
            )
            .shadow(color: FreewayFrenzyUI.garageAccent.opacity(0.45), radius: 12, y: 4)
        }
        .buttonStyle(FreewayFrenzyUI.PressableButtonStyle())
    }

    // MARK: - Bindings (optimistic UI + model sync)

    private var trafficBinding: Binding<Int> {
        Binding(
            get: { state.trafficLevel },
            set: { newValue in
                state.trafficLevel = newValue
                state.inputHandler?.setTraffic(newValue)
            }
        )
    }

    private var aggressionBinding: Binding<Int> {
        Binding(
            get: { state.aggressionLevel },
            set: { newValue in
                state.aggressionLevel = newValue
                state.inputHandler?.setAggression(newValue)
            }
        )
    }

    private var policeBinding: Binding<Bool> {
        Binding(
            get: { state.policeChase },
            set: { newValue in
                state.policeChase = newValue
                state.inputHandler?.setPoliceChase(newValue)
            }
        )
    }

    private var wetRoadsBinding: Binding<Bool> {
        Binding(
            get: { state.wetRoads },
            set: { newValue in
                state.wetRoads = newValue
                state.inputHandler?.setWetRoads(newValue)
            }
        )
    }

    private var ghostBinding: Binding<Bool> {
        Binding(
            get: { state.ghostMode },
            set: { newValue in
                state.ghostMode = newValue
                state.inputHandler?.setGhostMode(newValue)
            }
        )
    }
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
