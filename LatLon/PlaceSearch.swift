import SwiftUI
import MapKit

/// Wraps `MKLocalSearchCompleter`, the same as-you-type engine Apple Maps uses
/// (so "21 Bay" suggests "21 Bayovista Way"), and `MKLocalSearch` for turning a
/// suggestion or a typed query into places on the map.
@MainActor
@Observable
final class PlaceSearch: NSObject, MKLocalSearchCompleterDelegate {
    private(set) var completions: [MKLocalSearchCompletion] = []

    @ObservationIgnored private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest, .query]
    }

    /// The visible map region; suggestions near it are ranked first, as in Maps.
    var region: MKCoordinateRegion {
        get { completer.region }
        set { completer.region = newValue }
    }

    func update(query: String) {
        if query.isEmpty {
            completer.cancel()
            completions = []
        } else {
            completer.queryFragment = query
        }
    }

    func places(for completion: MKLocalSearchCompletion) async -> [MKMapItem] {
        await run(MKLocalSearch.Request(completion: completion))
    }

    func places(matching query: String) async -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        return await run(request)
    }

    private func run(_ request: MKLocalSearch.Request) async -> [MKMapItem] {
        request.region = completer.region
        request.resultTypes = [.address, .pointOfInterest]
        do {
            return try await MKLocalSearch(request: request).start().mapItems
        } catch {
            return []
        }
    }

    // MARK: MKLocalSearchCompleterDelegate (always called on the main thread)

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        MainActor.assumeIsolated {
            completions = completer.results
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        MainActor.assumeIsolated {
            completions = []
        }
    }
}

/// A suggestion row in the Maps style: the part you typed is bold, with the
/// address or locality underneath.
struct SuggestionRow: View {
    let completion: MKLocalSearchCompletion

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.highlighted(completion.title, ranges: completion.titleHighlightRanges))
                    .foregroundStyle(.primary)
                if !completion.subtitle.isEmpty {
                    Text(completion.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        } icon: {
            // Query suggestions ("Coffee") have no subtitle; places do.
            Image(systemName: completion.subtitle.isEmpty ? "magnifyingglass" : "mappin.circle.fill")
                .foregroundStyle(completion.subtitle.isEmpty ? Color.secondary : Color.red)
        }
    }

    static func highlighted(_ text: String, ranges: [NSValue]) -> AttributedString {
        let string = text as NSString
        var result = AttributedString()
        var cursor = 0
        for range in ranges.map(\.rangeValue).sorted(by: { $0.location < $1.location }) {
            guard range.location >= cursor, NSMaxRange(range) <= string.length else { continue }
            result += AttributedString(string.substring(with: NSRange(location: cursor, length: range.location - cursor)))
            var match = AttributedString(string.substring(with: range))
            match.inlinePresentationIntent = .stronglyEmphasized
            result += match
            cursor = NSMaxRange(range)
        }
        result += AttributedString(string.substring(from: cursor))
        return result
    }
}
