import SwiftUI

/// Stille sværhedsgrad: tre stigende streger som et signalmeter, eller en nøgle for mekaniker.
/// Arver font og farve fra omgivelserne.
struct DifficultyBadge: View {
    let difficulty: Difficulty

    var body: some View {
        HStack(spacing: 6) {
            if difficulty.isDIY {
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(1...3, id: \.self) { level in
                        Capsule()
                            .fill(Color.primary.opacity(level <= difficulty.rawValue ? 0.85 : 0.18))
                            .frame(width: 3, height: 4 + CGFloat(level) * 3)
                    }
                }
            } else {
                Image(systemName: "wrench.and.screwdriver")
                    .imageScale(.small)
            }
            Text(difficulty.title)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sværhedsgrad: \(difficulty.title)")
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        ForEach(Difficulty.allCases, id: \.self) { DifficultyBadge(difficulty: $0) }
    }
    .font(.subheadline)
    .foregroundStyle(.secondary)
}
