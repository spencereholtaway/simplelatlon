import SwiftUI
import MapKit

struct ContentView: View {
    /// Apple Park, the iOS Simulator's own default location.
    private static let initialCamera = MapCamera(
        centerCoordinate: CLLocationCoordinate2D(latitude: 37.334_900, longitude: -122.009_020),
        distance: 3_000
    )

    @AppStorage("mapStyle") private var mapStyle = MapStyleOption.explore

    @State private var position: MapCameraPosition = .camera(ContentView.initialCamera)
    @State private var center = ContentView.initialCamera.centerCoordinate
    @State private var crosshairPoint: CGPoint?
    @State private var locationManager = CLLocationManager()

    @State private var search = PlaceSearch()
    @State private var query = ""
    @State private var isSearching = false
    @State private var places: [MKMapItem] = []
    @State private var selectedPlace: MKMapItem?

    var body: some View {
        NavigationStack {
            MapReader { proxy in
                Map(position: $position, selection: $selectedPlace) {
                    UserAnnotation()
                    ForEach(places, id: \.self) { place in
                        Marker(item: place)
                            .tag(place)
                    }
                }
                .mapStyle(mapStyle.style)
                .mapControls {
                    #if os(macOS)
                    MapUserLocationButton()
                    MapZoomStepper()
                    MapPitchSlider()
                    MapCompass()
                    MapScaleView()
                    #else
                    MapUserLocationButton()
                    MapPitchToggle()
                    MapCompass()
                    MapScaleView()
                    #endif
                }
                .overlay {
                    crosshair
                        .allowsHitTesting(false)
                }
                .onMapCameraChange(frequency: .continuous) { context in
                    // The crosshair is drawn wherever MapKit's camera centre lands on
                    // screen, so the readout, the crosshair and search results always
                    // agree, whatever the toolbar, card or keyboard are doing.
                    center = context.camera.centerCoordinate
                    crosshairPoint = proxy.convert(context.camera.centerCoordinate, to: .local)
                    search.region = context.region
                }
                .safeAreaInset(edge: .bottom) {
                    CoordinateCard(coordinate: center)
                        .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    MapStylePicker(selection: $mapStyle)
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #else
            .navigationTitle("Simple LatLon")
            #endif
            .searchable(text: $query, isPresented: $isSearching, prompt: "Search Maps")
            .searchSuggestions {
                ForEach(search.completions, id: \.self) { completion in
                    Button {
                        choose(completion)
                    } label: {
                        SuggestionRow(completion: completion)
                    }
                }
            }
            .onSubmit(of: .search, submit)
            .onChange(of: query) { _, newValue in
                search.update(query: newValue)
            }
            .onChange(of: isSearching) { _, isActive in
                // Starting a new search clears the previous results, as in Maps.
                if isActive {
                    places = []
                    selectedPlace = nil
                }
            }
            .onChange(of: selectedPlace) { _, place in
                if let place {
                    moveCamera(to: place)
                }
            }
        }
        .task {
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
            }
        }
    }

    @ViewBuilder
    private var crosshair: some View {
        if let crosshairPoint {
            Crosshair().position(crosshairPoint)
        } else {
            Crosshair()
        }
    }

    // MARK: Search

    private func choose(_ completion: MKLocalSearchCompletion) {
        isSearching = false
        Task { show(await search.places(for: completion)) }
    }

    private func submit() {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        isSearching = false
        Task { show(await search.places(matching: text)) }
    }

    /// Drops a pin for every result and centres the crosshair on the first.
    /// Tapping another pin moves the crosshair to it.
    private func show(_ results: [MKMapItem]) {
        places = results
        selectedPlace = results.first
    }

    private func moveCamera(to place: MKMapItem) {
        let camera = MapCamera(centerCoordinate: place.placemark.coordinate, distance: 1_000)
        withAnimation {
            position = .camera(camera)
        }
    }
}

// MARK: - Crosshair

/// The only custom-drawn element: SF Symbols aren't guaranteed to be
/// pixel-centred in their frame, so two hairlines are used instead.
struct Crosshair: View {
    @Environment(\.colorScheme) private var colorScheme

    private let length: CGFloat = 32
    private let thickness: CGFloat = 1.5

    var body: some View {
        ZStack {
            Rectangle().frame(width: length, height: thickness)
            Rectangle().frame(width: thickness, height: length)
        }
        .foregroundStyle(.primary)
        .shadow(color: colorScheme == .dark ? .black : .white, radius: 1)
        .accessibilityHidden(true)
    }
}

#Preview {
    ContentView()
}
