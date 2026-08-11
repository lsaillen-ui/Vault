import SwiftUI

struct AlertBannerView: View {
    let coupons: [Coupon]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(coupons) { coupon in
                    bannerChip(coupon: coupon)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func bannerChip(coupon: Coupon) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption2)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 1) {
                Text(coupon.brand)
                    .font(.caption)
                    .fontWeight(.semibold)

                if let days = coupon.daysUntilExpiration {
                    Text(days == 0 ? "Aujourd'hui !" : "Dans \(days)j")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.orange.opacity(0.12))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(.orange.opacity(0.3), lineWidth: 1))
    }
}
