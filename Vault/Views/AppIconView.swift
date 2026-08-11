import SwiftUI

// MARK: - App Icon Preview
// Pour exporter : ouvrir ce Preview dans Xcode, faire screenshot ou
// utiliser File → Export As → PDF depuis le canvas Xcode Preview.
// Taille recommandée : 1024×1024 pt.

struct AppIconView: View {
    var size: CGFloat = 512

    var body: some View {
        ZStack {
            // Fond dégradé violet profond
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.07, green: 0.04, blue: 0.18), location: 0),
                    .init(color: Color(red: 0.13, green: 0.07, blue: 0.30), location: 0.55),
                    .init(color: Color(red: 0.05, green: 0.03, blue: 0.13), location: 1),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Halo violet central
            RadialGradient(
                colors: [Color.purple.opacity(0.38), .clear],
                center: UnitPoint(x: 0.5, y: 0.42),
                startRadius: 0,
                endRadius: size * 0.46
            )

            // Cercle décoratif discret
            Circle()
                .stroke(Color.white.opacity(0.045), lineWidth: size * 0.002)
                .frame(width: size * 0.70, height: size * 0.70)
                .offset(x: size * 0.08, y: -size * 0.08)

            // "V" serif avec dégradé blanc→lavande
            Text("V")
                .font(.system(size: size * 0.54, weight: .bold, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color(red: 0.87, green: 0.76, blue: 1.0),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.purple.opacity(0.75), radius: size * 0.055, y: size * 0.025)
                .offset(y: size * 0.018) // Correction optique centre visuel
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.215, style: .continuous))
    }
}

// MARK: - Preview export

#Preview("1024pt — App Store") {
    AppIconView(size: 1024)
        .ignoresSafeArea()
}

#Preview("Grille de tailles") {
    HStack(spacing: 20) {
        VStack(spacing: 8) {
            AppIconView(size: 60)
            Text("60pt").font(.caption).foregroundStyle(.secondary)
        }
        VStack(spacing: 8) {
            AppIconView(size: 120)
            Text("120pt").font(.caption).foregroundStyle(.secondary)
        }
        VStack(spacing: 8) {
            AppIconView(size: 180)
            Text("180pt").font(.caption).foregroundStyle(.secondary)
        }
    }
    .padding(24)
    .background(Color(.systemGroupedBackground))
}
