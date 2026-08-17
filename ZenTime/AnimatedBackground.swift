import SwiftCrossUI

/// A softly drifting, video-like green background of large blurred blobs over a dark base.
/// Motion is driven by TimelineView so it animates continuously without owning a timer.
struct AnimatedBackground: View {

    // /// A single drifting blob described by parametric sine motion.
    // private struct Blob {
    //     var color: Color
    //     var radius: CGFloat      // fraction of the smaller dimension
    //     var center: CGPoint      // base position in unit space (0...1)
    //     var amp: CGSize          // drift amplitude in unit space
    //     var speed: CGSize        // radians/sec for x and y
    //     var phase: CGSize        // phase offset
    // }

    // private let blobs: [Blob] = [
    //     Blob(color: Color(red: 0.70, green: 0.72, blue: 0.28), radius: 0.55,
    //          center: CGPoint(x: 0.30, y: 0.35), amp: CGSize(width: 0.10, height: 0.08),
    //          speed: CGSize(width: 0.13, height: 0.17), phase: CGSize(width: 0, height: 1.2)),
    //     Blob(color: Color(red: 0.34, green: 0.45, blue: 0.20), radius: 0.62,
    //          center: CGPoint(x: 0.72, y: 0.62), amp: CGSize(width: 0.12, height: 0.10),
    //          speed: CGSize(width: 0.11, height: 0.09), phase: CGSize(width: 2.1, height: 0.4)),
    //     Blob(color: Color(red: 0.54, green: 0.56, blue: 0.24), radius: 0.48,
    //          center: CGPoint(x: 0.58, y: 0.28), amp: CGSize(width: 0.09, height: 0.11),
    //          speed: CGSize(width: 0.08, height: 0.14), phase: CGSize(width: 3.4, height: 2.7)),
    //     Blob(color: Color(red: 0.20, green: 0.30, blue: 0.16), radius: 0.70,
    //          center: CGPoint(x: 0.40, y: 0.80), amp: CGSize(width: 0.13, height: 0.07),
    //          speed: CGSize(width: 0.10, height: 0.12), phase: CGSize(width: 1.1, height: 4.0)),
    // ]

    var body: some View {
        // TimelineView(.animation) { timeline in
        //     let t = timeline.date.timeIntervalSinceReferenceDate
        //     GeometryReader { geo in
        //         let w = geo.size.width
        //         let h = geo.size.height
        //         let minDim = min(w, h)
        //         ZStack {
        //             // Solid dark-green base that fills edge-to-edge (NOT blurred), so
        //             // there is no translucent halo where a blurred fill fades out.
        //             LinearGradient(
        //                 colors: [Color(red: 0.06, green: 0.09, blue: 0.05),
        //                          Color(red: 0.10, green: 0.14, blue: 0.08)],
        //                 startPoint: .top, endPoint: .bottom)

        //             // Drifting blurred blobs, rendered off-screen for smooth motion.
        //             // Only this group is blurred; its transparent edges reveal the
        //             // solid base above rather than the desktop behind the window.
        //             ZStack {
        //                 ForEach(blobs.indices, id: \.self) { i in
        //                     let b = blobs[i]
        //                     let x = (b.center.x + b.amp.width * sin(t * b.speed.width + b.phase.width)) * w
        //                     let y = (b.center.y + b.amp.height * cos(t * b.speed.height + b.phase.height)) * h
        //                     let d = b.radius * minDim * 2
        //                     Circle()
        //                         .fill(b.color)
        //                         .frame(width: d, height: d)
        //                         .position(x: x, y: y)
        //                 }
        //             }
        //             .blur(radius: minDim * 0.18)
        //             .drawingGroup()
        //         }
        //         // Gentle darkening vignette for depth.
        //         .overlay(
        //             RadialGradient(
        //                 colors: [.clear, Color.black.opacity(0.35)],
        //                 center: .center, startRadius: minDim * 0.2, endRadius: minDim * 0.9)
        //         )
        //     }
        // }
        // .ignoresSafeArea()
        Color.clear
    }
}
