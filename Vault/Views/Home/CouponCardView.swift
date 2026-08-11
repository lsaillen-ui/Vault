import SwiftUI

// MARK: - Carte principale

struct CouponCardView: View {
    let coupon: Coupon
    var isCompact: Bool = false

    private var cardColor: Color { Color(hex: coupon.cardColor) }

    var body: some View {
        Group {
            if isCompact {
                compactCard
            } else {
                extendedCard
            }
        }
        // VoiceOver : un seul élément qui résume le bon
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(voiceOverLabel)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Appuie pour voir les détails")
    }

    // MARK: - Accessibilité

    private var voiceOverLabel: String {
        var parts: [String] = [coupon.brand, coupon.value]
        if coupon.isUsed {
            parts.append("Utilisé")
        } else if coupon.isExpired {
            parts.append("Expiré")
        } else if let days = coupon.daysUntilExpiration {
            switch days {
            case 0:        parts.append("Expire aujourd'hui")
            case 1:        parts.append("Expire demain")
            case 2...7:    parts.append("Expire dans \(days) jours")
            default:
                if let d = coupon.expirationDate {
                    parts.append("Expire le \(d.formatted(date: .abbreviated, time: .omitted))")
                }
            }
        }
        if !coupon.code.isEmpty { parts.append("Code : \(coupon.code)") }
        return parts.joined(separator: ". ")
    }

    // MARK: Étendue (vue détail / hero)

    private var extendedCard: some View {
        ZStack(alignment: .topLeading) {
            cardBackground(cornerRadius: 22)

            decorativeCircles

            VStack(alignment: .leading, spacing: 0) {
                // — Section supérieure : marque, valeur, description, date
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(coupon.brand.uppercased())
                            .font(.caption2)
                            .fontWeight(.bold)
                            .tracking(1.4)
                            .foregroundStyle(.white.opacity(0.65))

                        Spacer()

                        statusBadge(compact: false)
                    }

                    Text(coupon.value)
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if let notes = coupon.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.75))
                            .lineLimit(2)
                    }

                    if let date = coupon.expirationDate {
                        Label(
                            "Valable jusqu'au \(date.formatted(date: .abbreviated, time: .omitted))",
                            systemImage: "calendar"
                        )
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding(18)

                // — Séparateur pointillés (style coupon physique)
                CouponDashedLine(color: .white.opacity(0.35))

                // — Section inférieure : code promo
                HStack(spacing: 10) {
                    if !coupon.code.isEmpty {
                        Text(coupon.code)
                            .font(.system(.callout, design: .monospaced))
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(.white.opacity(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                            )
                    } else {
                        Text("Aucun code requis")
                            .font(.caption)
                            .italic()
                            .foregroundStyle(.white.opacity(0.45))
                    }

                    Spacer()

                    Image(systemName: coupon.category.icon)
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.3))
                }
                .padding(18)
            }
        }
        .frame(height: 215)
        .shadow(color: cardColor.opacity(0.45), radius: 14, x: 0, y: 6)
        .overlay { if coupon.isUsed { usedStamp } }
        .opacity(coupon.isUsed ? 0.6 : 1)
    }

    // MARK: Compacte (grille / liste)

    private var compactCard: some View {
        ZStack(alignment: .topLeading) {
            cardBackground(cornerRadius: 18)

            decorativeCircles

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .top) {
                        Text(coupon.brand.uppercased())
                            .font(.caption2)
                            .fontWeight(.bold)
                            .tracking(1.2)
                            .foregroundStyle(.white.opacity(0.65))
                            .lineLimit(1)

                        Spacer(minLength: 4)

                        statusBadge(compact: true)
                    }

                    Text(coupon.value)
                        .font(.title2)
                        .fontWeight(.heavy)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .padding(14)

                CouponDashedLine(color: .white.opacity(0.3))

                HStack {
                    if !coupon.code.isEmpty {
                        Text(coupon.code)
                            .font(.system(.caption2, design: .monospaced))
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(.white.opacity(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    } else if let date = coupon.expirationDate {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.55))
                    } else {
                        Image(systemName: coupon.category.icon)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
        }
        .frame(height: 138)
        .shadow(color: cardColor.opacity(0.35), radius: 10, x: 0, y: 4)
        .opacity(coupon.isUsed ? 0.55 : 1)
    }

    // MARK: Sous-composants

    @ViewBuilder
    private func statusBadge(compact: Bool) -> some View {
        let days = coupon.daysUntilExpiration

        if let days, days <= 7 {
            let label = days == 0 ? "Auj." : "\(days)j"
            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal, compact ? 7 : 9)
                .padding(.vertical, compact ? 3 : 5)
                .background(.red.opacity(0.88))
                .clipShape(Capsule())
        } else {
            HStack(spacing: 3) {
                Image(systemName: coupon.category.icon)
                    .font(.caption2)
                if !compact {
                    Text(coupon.category.displayName)
                        .font(.caption2)
                }
            }
            .foregroundStyle(.white.opacity(0.85))
            .padding(.horizontal, compact ? 7 : 9)
            .padding(.vertical, compact ? 3 : 5)
            .background(.white.opacity(0.15))
            .clipShape(Capsule())
        }
    }

    private func cardBackground(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [cardColor, cardColor.opacity(0.72)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var decorativeCircles: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.07))
                .frame(width: 140, height: 140)
                .offset(x: 110, y: -45)
            Circle()
                .fill(.white.opacity(0.05))
                .frame(width: 95, height: 95)
                .offset(x: 145, y: 55)
        }
    }

    private var usedStamp: some View {
        Text("UTILISÉ")
            .font(.caption)
            .fontWeight(.heavy)
            .tracking(4)
            .foregroundStyle(.white.opacity(0.7))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(.white.opacity(0.55), lineWidth: 2)
            )
            .rotationEffect(.degrees(-18))
    }
}

// MARK: - Séparateur pointillés

struct CouponDashedLine: View {
    var color: Color = .white.opacity(0.35)

    var body: some View {
        Canvas { ctx, size in
            var path = Path()
            path.move(to: CGPoint(x: 0, y: 0.5))
            path.addLine(to: CGPoint(x: size.width, y: 0.5))
            ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
        }
        .frame(height: 1)
    }
}

// MARK: - Données de preview

#if DEBUG
enum PreviewCoupons {
    static let mcdo = Coupon(
        brand: "McDonald's",
        value: "−20%",
        code: "MCDO20",
        category: .restauFood,
        expirationDate: Calendar.current.date(byAdding: .day, value: 3, to: .now),
        notes: "Sur tout le menu, valable au comptoir"
    )

    static let zalando = Coupon(
        brand: "Zalando",
        value: "CHF 15",
        code: "ZAL15OFF",
        category: .mode,
        expirationDate: Calendar.current.date(byAdding: .day, value: 28, to: .now),
        notes: "Dès CHF 80 d'achat"
    )

    static let fnac = Coupon(
        brand: "Fnac",
        value: "−10%",
        code: "FNAC10",
        category: .techJeux,
        expirationDate: Calendar.current.date(byAdding: .day, value: 6, to: .now),
        notes: "Jeux vidéo & consoles"
    )

    static let ikea = Coupon(
        brand: "IKEA",
        value: "CHF 50",
        code: "",
        category: .maison,
        expirationDate: Calendar.current.date(byAdding: .month, value: 2, to: .now),
        notes: "Carte cadeau"
    )

    static let uberEats = Coupon(
        brand: "Uber Eats",
        value: "Livraison offerte",
        code: "FREESHIP",
        category: .restauFood,
        expirationDate: Calendar.current.date(byAdding: .day, value: 1, to: .now)
    )

    static let all: [Coupon] = [mcdo, zalando, fnac, ikea, uberEats]
}
#endif

// MARK: - Previews

#Preview("Grille compacte") {
    ScrollView {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(PreviewCoupons.all, id: \.id) { coupon in
                CouponCardView(coupon: coupon, isCompact: true)
            }
        }
        .padding(16)
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Cartes étendues") {
    ScrollView {
        VStack(spacing: 20) {
            ForEach(PreviewCoupons.all, id: \.id) { coupon in
                CouponCardView(coupon: coupon, isCompact: false)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Bon utilisé") {
    let used = Coupon(brand: "Starbucks", value: "Café offert", code: "SBUX1FREE", category: .restauFood)
    used.isUsed = true
    return VStack(spacing: 16) {
        CouponCardView(coupon: used, isCompact: false).padding(.horizontal, 16)
        CouponCardView(coupon: used, isCompact: true).padding(.horizontal, 16)
    }
    .padding(.vertical, 20)
    .background(Color(.systemGroupedBackground))
}
