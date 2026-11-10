import SwiftUI
import CoreLocation
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

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
            .help("Copy \(title.lowercased())")
            .accessibilityLabel("Copy \(title.lowercased())")
            .sensoryFeedback(.success, trigger: isCopied) { _, newValue in newValue }
        }
    }

    private func copy() {
        Clipboard.copy(value)
        withAnimation { isCopied = true }

        resetTask?.cancel()
        resetTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            withAnimation { isCopied = false }
        }
    }
}

enum Clipboard {
    static func copy(_ string: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = string
        #else
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
        #endif
    }
}

// MARK: - Card background

private extension View {
    /// Liquid Glass on iOS/macOS 26+, the standard material on earlier versions.
    @ViewBuilder
    func cardBackground() -> some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        #if compiler(>=6.2)
        if #available(iOS 26.0, macOS 26.0, *) {
            self.glassEffect(.regular, in: shape)
        } else {
            self.background(.regularMaterial, in: shape)
        }
        #else
        self.background(.regularMaterial, in: shape)
        #endif
    }
}
