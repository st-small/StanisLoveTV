import SwiftUI

struct PlaybackStatsOverlayView: View {
    let observedBitrate: Double?
    let indicatedBitrate: Double?
    let stallCount: Int
    let presentationSize: CGSize
    let isLikelyToKeepUp: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            Text("PLAYBACK STATS")
                .font(.caption2)
                .bold()
                .foregroundStyle(.secondary)

            statRow("Bitrate", bitrateText)
            statRow("Resolution", resolutionText)
            statRow("Stalls", "\(stallCount)")
            statRow("Buffer", isLikelyToKeepUp ? "Healthy" : "Low")
        }
        .padding(DSSpacing.s)
        .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: DSRadius.s))
        .foregroundStyle(.white)
        .font(.caption)
        .accessibilityHidden(true)
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack(spacing: DSSpacing.s) {
            Text(label).foregroundStyle(.secondary)
            Spacer(minLength: DSSpacing.s)
            Text(value).monospacedDigit()
        }
    }

    private var bitrateText: String {
        guard let observedBitrate, observedBitrate > 0 else { return "—" }
        return String(format: "%.1f Mbps", observedBitrate / 1_000_000)
    }

    private var resolutionText: String {
        guard presentationSize != .zero else { return "—" }
        return "\(Int(presentationSize.width))×\(Int(presentationSize.height))"
    }
}
