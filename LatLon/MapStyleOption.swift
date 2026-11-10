import SwiftUI
import MapKit

/// The map styles Apple Maps offers, as far as MapKit exposes them.
/// (Maps' Transit style has no public MapKit equivalent.)
enum MapStyleOption: String, CaseIterable, Identifiable {
    case explore
    case driving
    case satellite

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .explore: "Explore"
        case .driving: "Driving"
        case .satellite: "Satellite"
        }
    }

    var systemImage: String {
        switch self {
        case .explore: "map"
        case .driving: "car"
        case .satellite: "globe.americas"
        }
    }

    var style: MapStyle {
        switch self {
        case .explore: .standard(elevation: .realistic)
        case .driving: .standard(elevation: .realistic, emphasis: .muted, showsTraffic: true)
        case .satellite: .hybrid(elevation: .realistic)
        }
    }
}

/// The toolbar map button. The choice is remembered between launches.
struct MapStylePicker: View {
    @Binding var selection: MapStyleOption

    var body: some View {
        Menu {
            Picker("Map Style", selection: $selection) {
                ForEach(MapStyleOption.allCases) { option in
                    Label(option.title, systemImage: option.systemImage)
                        .tag(option)
                }
            }
            .pickerStyle(.inline)
        } label: {
            Label("Map Style", systemImage: "map")
        }
    }
}
