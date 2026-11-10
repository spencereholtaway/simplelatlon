import SwiftUI
import MapKit

struct ContentView: View {
    /// Apple Park, the iOS Simulator's own default location.
    private static let initialRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.334_900, longitude: -122.009_020),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )

    @State private var position: MapCameraPosition = .region(ContentView.initialRegion)
    @State private var center = ContentView.initialRegion.center

    var body: some View {
        ZStack(alignment: .bottom) {
            GeometryReader { geometry in
                MapReader { proxy in
                    Map(position: $position)
                        .mapControls {
                            MapCompass()
                            MapScaleView()
                        }
                        .overlay {
                            Crosshair()
                                .allowsHitTesting(false)
                        }
                        .onMapCameraChange(frequency: .continuous) {
                            updateCenter(in: geometry.size, using: proxy)
                        }
                        .onChange(of: geometry.size) { _, newSize in
                            updateCenter(in: newSize, using: proxy)
                        }
                }
            }
            .ignoresSafeArea()

            CoordinateCard(coordinate: center)
                .padding()
        }
    }

    /// Reads the coordinate under the exact point the crosshair is drawn at
    /// (the centre of the map's frame), so safe-area insets can't skew it.
    private func updateCenter(in size: CGSize, using proxy: MapProxy) {
        let point = CGPoint(x: size.width / 2, y: size.height / 2)
        if let coordinate = proxy.convert(point, from: .local) {
            center = coordinate
        }
    }
}

// MARK: - Crosshair

/// The only custom-drawn element: SF Symbols aren't guaranteed to be
/// pixel-centred in their frame, so two hairlines are used instead.
struct Crosshair: View {
    private let length: CGFloat = 32
    private let thickness: CGFloat = 1.5

    var body: some View {
        ZStack {
            Rectangle().frame(width: length, height: thickness)
            Rectangle().frame(width: thickness, height: length)
        }
        .foregroundStyle(.primary)
        .shadow(color: Color(uiColor: .systemBackground), radius: 1)
        .accessibilityHidden(true)
    }
}

// MARK: - Coordinate card

struct CoordinateCard: View {
    let coordinate: CLLocationCoordinate2D

    var body: some View {
        VStack(spacing: 0) {
            CoordinateRow(title: "Latitude", value: Self.format(coordinate.latitude))
            Divider()
                .padding(.vertical, 10)
            CoordinateRow(title: "Longitude", value: Self.format(Self.normalized(coordinate.longitude)))
        }
        .padding(16)
        .frame(maxWidth: 420)
        .cardBackground()
    }

    /// Always uses "." as the decimal separator, whatever the device locale,
    /// so the value pastes cleanly into Xcode's Custom Location fields.
    static func format(_ degrees: CLLocationDegrees) -> String {
        String(format: "%.6f", degrees)
    }

    /// Wraps longitude into -180...180 in case the map has been panned around the globe.
    static func normalized(_ longitude: CLLocationDegrees) -> CLLocationDegrees {
        var value = (longitude + 180).truncatingRemainder(dividingBy: 360)
        if value < 0 { value += 360 }
        return value - 180
    }
}

struct CoordinateRow: View {
    let title: String
    let value: String

    @State private var isCopied = false
    @State private var resetTask: Task<Void, Never>?

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(isCopied ? "Copied" : value)
                    .font(.title2.monospacedDigit())
                    .foregroundStyle(isCopied ? Color.green : Color.primary)
                    .contentTransition(.opacity)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)

            Spacer(minLength: 0)

            Button(action: copy) {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .controlSize(.large)
            .tint(isCopied ? .green : .accentColor)
            .accessibilityLabel("Copy \(title.lowercased())")
            .sensoryFeedback(.success, trigger: isCopied) { _, newValue in newValue }
        }
    }

    private func copy() {
        UIPasteboard.general.string = value
        withAnimation { isCopied = true }

        resetTask?.cancel()
        resetTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            withAnimation { isCopied = false }
        }
    }
}

// MARK: - Card background

private extension View {
    /// Liquid Glass on iOS 26+, the standard material on earlier versions.
    @ViewBuilder
    func cardBackground() -> some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: shape)
        } else {
            self.background(.regularMaterial, in: shape)
        }
        #else
        self.background(.regularMaterial, in: shape)
        #endif
    }
}

#Preview {
    ContentView()
}
