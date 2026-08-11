import SwiftUI
import SwiftData
import Charts

// MARK: - Modèle de données graphique

struct MonthlySavings: Identifiable {
    let id = UUID()
    let date: Date     // Premier jour du mois
    let amount: Double
    let couponCount: Int
}

// MARK: - Vue principale

struct SavingsStatsView: View {
    @Query private var coupons: [Coupon]
    @State private var showPaywall = false

    private var isPremium: Bool { SubscriptionService.shared.subscription.isPremium }

    // MARK: - Données réelles (utilisées uniquement si Premium)

    private var usedCoupons: [Coupon] { coupons.filter(\.isUsed) }
    private var expiredUnusedCount: Int { coupons.filter { $0.isExpired && !$0.isUsed }.count }

    private var thisMonthStart: Date {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year, .month], from: .now)) ?? .now
    }

    private var savingsThisMonth: Double {
        let cal = Calendar.current
        return usedCoupons
            .filter { cal.isDate($0.usedAt ?? $0.createdAt, equalTo: thisMonthStart, toGranularity: .month) &&
                      cal.isDate($0.usedAt ?? $0.createdAt, equalTo: thisMonthStart, toGranularity: .year) }
            .compactMap { SavingsParser.parse($0.value).monetaryAmount }
            .reduce(0, +)
    }

    private var savingsThisYear: Double {
        let year = Calendar.current.component(.year, from: .now)
        return usedCoupons
            .filter { Calendar.current.component(.year, from: $0.usedAt ?? $0.createdAt) == year }
            .compactMap { SavingsParser.parse($0.value).monetaryAmount }
            .reduce(0, +)
    }

    private var monthlyChartData: [MonthlySavings] {
        let cal = Calendar.current
        return (0..<12).compactMap { i -> MonthlySavings? in
            // i=0 → il y a 11 mois, i=11 → mois courant
            guard let monthDate = cal.date(byAdding: .month, value: -(11 - i), to: thisMonthStart) else { return nil }
            let monthCoupons = usedCoupons.filter {
                let d = $0.usedAt ?? $0.createdAt
                return cal.isDate(d, equalTo: monthDate, toGranularity: .month) &&
                       cal.isDate(d, equalTo: monthDate, toGranularity: .year)
            }
            let amount = monthCoupons.compactMap { SavingsParser.parse($0.value).monetaryAmount }.reduce(0, +)
            return MonthlySavings(date: monthDate, amount: amount, couponCount: monthCoupons.count)
        }
    }

    private var topCategory: (category: Category, amount: Double, count: Int)? {
        let grouped = Dictionary(grouping: usedCoupons, by: \.category)
        return grouped
            .compactMap { cat, cs -> (Category, Double, Int)? in
                let amount = cs.compactMap { SavingsParser.parse($0.value).monetaryAmount }.reduce(0, +)
                guard amount > 0 else { return nil }
                return (cat, amount, cs.count)
            }
            .sorted { $0.1 > $1.1 }
            .first
    }

    // MARK: - Données de prévisualisation (non-Premium)

    private var previewMonthlyData: [MonthlySavings] {
        let amounts: [Double] = [18, 0, 32, 12, 45, 8, 25, 0, 38, 15, 52, 27]
        let cal = Calendar.current
        return amounts.enumerated().compactMap { i, amount in
            guard let date = cal.date(byAdding: .month, value: -(11 - i), to: thisMonthStart) else { return nil }
            return MonthlySavings(date: date, amount: amount, couponCount: max(0, Int(amount / 12)))
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                scrollContent
                    .blur(radius: isPremium ? 0 : 10)
                    .allowsHitTesting(isPremium)
                    .animation(.easeInOut(duration: 0.4), value: isPremium)

                if !isPremium {
                    premiumGate
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Mes économies")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    // MARK: - Contenu défilable

    private var scrollContent: some View {
        let chartData  = isPremium ? monthlyChartData  : previewMonthlyData
        let monthTotal = isPremium ? savingsThisMonth  : 52.0
        let yearTotal  = isPremium ? savingsThisYear   : 272.5
        let usedCount  = isPremium ? usedCoupons.count : 14
        let expCount   = isPremium ? expiredUnusedCount : 3

        return ScrollView {
            VStack(spacing: 20) {
                summaryCards(monthAmount: monthTotal, yearAmount: yearTotal)
                chartSection(data: chartData)
                if isPremium {
                    topCategorySection
                }
                utilizationSection(used: usedCount, expired: expCount)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, isPremium ? 32 : 260) // espace pour la CTA quand non-premium
        }
    }

    // MARK: - Cartes résumé

    private func summaryCards(monthAmount: Double, yearAmount: Double) -> some View {
        HStack(spacing: 12) {
            amountCard(
                title: "Ce mois",
                amount: monthAmount,
                icon: "calendar",
                accent: .blue
            )
            amountCard(
                title: "Cette année",
                amount: yearAmount,
                icon: "star.fill",
                accent: .orange
            )
        }
    }

    private func amountCard(title: String, amount: Double, icon: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(accent)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("CHF")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(accent.opacity(0.8))
                Text(amount > 0 ? amount.formatted(.number.precision(.fractionLength(0...2))) : "0")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(amount > 0 ? .primary : Color(.tertiaryLabel))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accent.opacity(0.15), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) : CHF \(amount > 0 ? amount.formatted(.number.precision(.fractionLength(0...2))) : "0")")
    }

    // MARK: - Graphique en barres

    private func chartSection(data: [MonthlySavings]) -> some View {
        let maxAmount = data.map(\.amount).max() ?? 1
        let average = data.map(\.amount).reduce(0, +) / Double(data.count)

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Économies par mois")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                if average > 0 {
                    Text("Moy. CHF \(average.formatted(.number.precision(.fractionLength(0))))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Chart {
                // Barres mensuelles
                ForEach(data) { month in
                    BarMark(
                        x: .value("Mois", month.date, unit: .month),
                        y: .value("CHF", month.amount)
                    )
                    .foregroundStyle(
                        month.amount == 0
                            ? AnyShapeStyle(Color(.systemGray5))
                            : AnyShapeStyle(LinearGradient(
                                colors: [
                                    .blue.opacity(0.5 + 0.5 * (month.amount / max(maxAmount, 1))),
                                    .blue
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            ))
                    )
                    .cornerRadius(5)
                }

                // Ligne de moyenne (unique, hors boucle)
                if average > 0 {
                    RuleMark(y: .value("Moyenne", average))
                        .foregroundStyle(.orange.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month, count: 2)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date, format: .dateTime.month(.abbreviated))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine()
                        .foregroundStyle(Color(.systemGray5))
                    if let v = value.as(Double.self) {
                        AxisValueLabel {
                            Text(v.formatted(.number.precision(.fractionLength(0))))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartPlotStyle { plot in
                plot.background(Color(.systemBackground).opacity(0))
            }
            .frame(height: 180)
            .accessibilityLabel("Graphique des économies par mois sur 12 mois")
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Catégorie top

    @ViewBuilder
    private var topCategorySection: some View {
        if let top = topCategory {
            VStack(alignment: .leading, spacing: 14) {
                Text("Où tu économises le plus")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(top.category.color.opacity(0.15))
                            .frame(width: 52, height: 52)
                        Image(systemName: top.category.icon)
                            .font(.title3)
                            .foregroundStyle(top.category.color)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(top.category.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("\(top.count) bon\(top.count > 1 ? "s" : "") utilisé\(top.count > 1 ? "s" : "")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 1) {
                        Text("CHF")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(top.amount.formatted(.number.precision(.fractionLength(0...2))))
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    // MARK: - Utilisation des bons

    private func utilizationSection(used: Int, expired: Int) -> some View {
        let total = used + expired
        let usedFraction = total > 0 ? Double(used) / Double(total) : 0

        return VStack(alignment: .leading, spacing: 14) {
            Text("Utilisation des bons")
                .font(.subheadline)
                .fontWeight(.semibold)

            HStack(spacing: 0) {
                statPill(
                    value: "\(used)",
                    label: "Utilisés",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                Divider().frame(height: 36)

                statPill(
                    value: "\(expired)",
                    label: "Expirés sans usage",
                    icon: "clock.badge.xmark",
                    color: .red
                )
            }

            if total > 0 {
                // Barre de progression utilisé vs expiré
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.red.opacity(0.15))
                            .frame(height: 8)

                        Capsule()
                            .fill(
                                LinearGradient(colors: [.green.opacity(0.8), .green],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: max(8, geo.size.width * usedFraction), height: 8)
                            .animation(.spring(duration: 0.6, bounce: 0.1), value: usedFraction)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("\(Int(usedFraction * 100))% de tes bons ont été utilisés avant expiration")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func statPill(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) : \(value)")
    }

    // MARK: - Porte Premium (overlay)

    private var premiumGate: some View {
        VStack(spacing: 0) {
            // Fondu vers le bas pour "cacher" le contenu flou
            LinearGradient(
                colors: [.clear, Color(.systemGroupedBackground).opacity(0.7), Color(.systemGroupedBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
            .allowsHitTesting(false)

            // Carte CTA
            VStack(spacing: 18) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.12))
                            .frame(width: 48, height: 48)
                        Image(systemName: "lock.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Fonctionnalité Premium")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Text("Accède à toutes tes statistiques d'économies.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Avantages résumés
                VStack(spacing: 8) {
                    featureRow("chart.bar.fill",     .blue,   "Graphique des 12 derniers mois")
                    featureRow("star.fill",          .orange, "Total économisé par mois et par an")
                    featureRow("square.grid.2x2",    .purple, "Analyse par catégorie")
                }

                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                        Text("Débloquer avec Premium")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        LinearGradient(
                            colors: [.blue, Color(red: 0.1, green: 0.3, blue: 0.9)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .blue.opacity(0.25), radius: 8, y: 3)
                }
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color(.systemGray5), lineWidth: 0.5)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }

    private func featureRow(_ icon: String, _ color: Color, _ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 18)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("Premium") {
    SavingsStatsView()
        .modelContainer(for: Coupon.self, inMemory: true)
}

#Preview("Non Premium") {
    SavingsStatsView()
        .modelContainer(for: Coupon.self, inMemory: true)
}
