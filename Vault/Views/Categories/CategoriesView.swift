import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Query private var coupons: [Coupon]
    @State private var appeared = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(Array(Category.allCases.enumerated()), id: \.element) { index, category in
                        NavigationLink(destination: categoryDetail(category)) {
                            categoryCard(category, index: index)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Catégories")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                guard !appeared else { return }
                withAnimation(.spring(duration: 0.5)) { appeared = true }
            }
        }
    }

    private func count(for category: Category) -> Int {
        coupons.filter { $0.category == category && !$0.isUsed && !$0.isExpired }.count
    }

    private func categoryCard(_ category: Category, index: Int) -> some View {
        let n = count(for: category)
        return ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [category.color, category.color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 100)
                .shadow(color: category.color.opacity(0.3), radius: 8, y: 4)

            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(.white)

                Text(category.displayName)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text("\(n) bon\(n == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(14)
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.85)
        .animation(
            .spring(duration: 0.45, bounce: 0.2).delay(Double(index) * 0.055),
            value: appeared
        )
        .accessibilityLabel("\(category.displayName), \(n) bon\(n == 1 ? "" : "s") actif\(n == 1 ? "" : "s")")
        .accessibilityHint("Appuie pour voir les bons de cette catégorie")
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private func categoryDetail(_ category: Category) -> some View {
        let filtered = coupons.filter { $0.category == category && !$0.isUsed && !$0.isExpired }
        Group {
            if filtered.isEmpty {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(category.color.opacity(0.1))
                            .frame(width: 120, height: 120)
                        Circle()
                            .fill(category.color.opacity(0.06))
                            .frame(width: 90, height: 90)
                        Image(systemName: category.icon)
                            .font(.system(size: 46))
                            .foregroundStyle(category.color)
                    }

                    VStack(spacing: 8) {
                        Text("Aucun bon ici")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Ajoute un bon dans la catégorie\n\"\(category.displayName)\" via le +.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 32)
            } else {
                List(filtered) { coupon in
                    NavigationLink(destination: CouponDetailView(coupon: coupon)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(coupon.brand).fontWeight(.semibold)
                                Text(coupon.value).foregroundStyle(.secondary).font(.subheadline)
                            }
                            Spacer()
                            if let days = coupon.daysUntilExpiration {
                                Text("\(days)j")
                                    .font(.caption)
                                    .foregroundStyle(days <= 3 ? .orange : .secondary)
                            }
                        }
                    }
                    .accessibilityLabel("\(coupon.brand), \(coupon.value)\(coupon.daysUntilExpiration.map { ", expire dans \($0) jours" } ?? "")")
                }
            }
        }
        .navigationTitle(category.displayName)
    }
}
