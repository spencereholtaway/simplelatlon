# Lat Lon

A tiny iPhone / iPad / Mac (Designed for iPad) app for picking coordinates to paste into the
iOS Simulator's **Features → Location → Custom Location…** dialog, which has separate
latitude and longitude fields and doesn't remember anything.

- Full-screen map with a crosshair in the centre
- Card showing the latitude and longitude under the crosshair (6 decimal places, ~10 cm)
- A copy button per value; tapping it shows a checkmark and "Copied" for 1.5 s

## Build

Open `LatLon.xcodeproj` in Xcode 16 or later (Xcode 26 recommended; that's what turns on the
Liquid Glass card), pick your team under *Signing & Capabilities*, and run.
The deployment target is iOS 17.

Everything is stock SwiftUI and MapKit (`Map`, `MapReader`, `onMapCameraChange`,
`UIPasteboard`, SF Symbols, `sensoryFeedback`). The only custom-drawn view is the crosshair.
