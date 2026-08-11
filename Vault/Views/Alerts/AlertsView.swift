import SwiftUI
import SwiftData

struct AlertsView: View {
    @Query(sort: \Coupon.expirationDate) private var coupons: [Coupon]
    @State private var appeared = false

    private var expiringSoon: [Coupon] {
        coupons.filter { $0.isExpiringSoon && !$0.isUsed }
    }

    private var expired: [Coupon] {
        coupons.filter { $0.isExpired && !$0.isUsed }
    }

    private var hasAlerts: Bool { !expiringSoon.isEmpty || !expired.isEmpty }

    var body: some View {
        NavigationStack {
            Group {
                if hasAlerts {
                    List {
                        if !expiringSoon.isEmpty {
                            Section {
                                ForEach(Array(expiringSoon.enumerated()), id: \.element.id) { index, coupon in
                                    NavigationLink(destination: CouponDetailView(coupon: coupon)) {
                                        alertRow(coupon: coupon, isExpired: false)
                                    }
                                    .opacity(appeared ? 1 : 0)
                                    .offset(x: appeared ? 0 : -20)
                                    .animation(
                                        .spring(duration: 0.4, bounce: 0.1).delay(Double(index) * 0.06),
                                        value: appeared
                                    )
                                    .accessibilityLabel(alertLabel(coupon: coupon, isExpired: false))
                                }
                            } header: {
                                Label("Expire bientôt", systemImage: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }

                        if !expired.isEmpty {
                            Section {
                                ForEach(Array(expired.enumerated()), id: \.element.id) { index, coupon in
                                    NavigationLink(destination: CouponDetailView(coupon: coupon)) {
                                        alertRow(coupon: coupon, isExpired: true)
                                    }
                                    .opacity(appeared ? 1 : 0)
                                    .offset(x: appeared ? 0 : -20)
                                    .animation(
                                        .spring(duration: 0.4, bounce: 0.1)
                                            .delay(Double(expiringSoon.count + index) * 0.06),
                                        value: appeared
                                    )
                                    .accessibilityLabel(alertLabel(coupon: coupon, isExpired: true))
                                }
                            } header: {
                                Label("Expirés", systemImage: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                } else {
                    emptyState
                }
            }
            .navigationTitle("Alertes")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                guard !appeared else { return }
                withAnimation(.spring(duration: 0.5).delay(0.1)) { appeared = true }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(.green.opacity(0.1))
                    .frame(width: 130, height: 130)
                    .scaleEffect(appeared ? 1 : 0.7)

                Circle()
                    .fill(.green.opacity(0.06))
                    .frame(width: 100, height: 100)
                    .scaleEffect(appeared ? 1 : 0.7)

                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.green)
                    .scaleEffect(appeared ? 1 : 0.4)
                    .opacity(appeared ? 1 : 0)
            }
            .animation(.spring(duration: 0.6, bounce: 0.3), value: appeared)

            VStack(spacing: 8) {
                Text("Tout est à jour")
                    .font(.title2)
                    .fontWeight(.bold)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(.spring(duration: 0.5).delay(0.15), value: appeared)

                Text("Aucun bon n'expire bientôt.\nProfite de tes réductions !")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(.spring(duration: 0.5).delay(0.22), value: appeared)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tout est à jour. Aucun bon n'expire bientôt.")
    }

    private func alertRow(coupon: Coupon, isExpired: Bool) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: coupon.cardColor).opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: coupon.category.icon)
                        .foregroundStyle(Color(hex: coupon.cardColor))
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(coupon.brand)
                    .fontWeight(.semibold)
                Text(coupon.value)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isExpired {
                Text("Expiré")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.red)
                    .clipShape(Capsule())
            } else if let days = coupon.daysUntilExpiration {
                Text(days == 0 ? "Auj." : "\(days)j")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange)
                    .clipShape(Capsule())
            }
        }
    }

    private func alertLabel(coupon: Coupon, isExpired: Bool) -> String {
        if isExpired {
            return "\(coupon.brand), \(coupon.value). Expiré."
        } else if let days = coupon.daysUntilExpiration {
            switch days {
            case 0:  return "\(coupon.brand), \(coupon.value). Expire aujourd'hui."
            case 1:  return "\(coupon.brand), \(coupon.value). Expire demain."
            default: return "\(coupon.brand), \(coupon.value). Expire dans \(days) jours."
            }
        }
        return "\(coupon.brand), \(coupon.value)."
    }
}
