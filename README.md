# Xcode Lat Lon

Apple Maps with everything stripped out except the coordinate under a crosshair. Built for
pasting into the iOS Simulator's **Features → Location → Custom Location…** dialog, which has
separate latitude and longitude fields and doesn't remember anything.

Runs on iPhone, iPad and natively on macOS (one multiplatform target).

- Full-screen map with a crosshair at the camera centre
- Card with latitude and longitude (6 decimal places, ~10 cm), each with a copy button that
  shows a checkmark and "Copied" for 1.5 s
- Maps-style search with as-you-type suggestions (`MKLocalSearchCompleter`); pressing Return
  pins every result, and tapping a pin moves the crosshair to it
- Map style menu (Explore / Driving / Satellite), remembered between launches
- Stock MapKit controls: on macOS the location button, zoom stepper, 2D/3D pitch slider,
  compass and scale; on iOS the location button, pitch toggle, compass and scale

## Build

Open `Xcode Lat Lon.xcodeproj` in Xcode 16 or later (Xcode 26 recommended; that's what turns on the
Liquid Glass card), pick your team under *Signing & Capabilities*, choose an iOS simulator,
device or "My Mac", and run. Deployment targets: iOS 17, macOS 14.

Everything is stock SwiftUI and MapKit. The only custom-drawn view is the crosshair.
