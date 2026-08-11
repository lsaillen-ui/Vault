import SwiftUI
import SwiftData
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

// MARK: - Vue détail

struct CouponDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let coupon: Coupon

    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    @State private var codeCopied = false
    @State private var showQR = false

    private var cardColor: Color { Color(hex: coupon.cardColor) }

    var body: some View {
        ZStack(alignment: .top) {
            // Fond dégradé immersif basé sur la couleur de la carte
            LinearGradient(
                colors: [cardColor.opacity(0.35), cardColor.opacity(0.08), Color(.systemGroupedBackground)],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.5)
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    heroCard
                    if !coupon.code.isEmpty { codeSection }
                    infoSection
                    actionsSection
                }
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(coupon.brand)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar { toolbarItems }
        .sheet(isPresented: $showEdit) { EditCouponSheet(coupon: coupon) }
        .confirmationDialog(
            "Supprimer \"\(coupon.brand)\" ?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Supprimer le bon", role: .destructive) { deleteCoupon() }
        } message: {
            Text("Cette action est irréversible.")
        }
    }

    // MARK: - Hero card

    private var heroCard: some View {
        CouponCardView(coupon: coupon, isCompact: false)
            .padding(.horizontal, 16)
            .shadow(color: cardColor.opacity(0.3), radius: 20, x: 0, y: 10)
    }

    // MARK: - Section code + QR

    private var codeSection: some View {
        VStack(spacing: 0) {
            // Code en grand avec bouton copier
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text("CODE PROMO")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .tracking(1.5)
                        .foregroundStyle(.secondary)

                    Text(coupon.code)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                }

                // Bouton Copier
                Button { copyCode() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: codeCopied ? "checkmark" : "doc.on.doc.fill")
                            .font(.callout)
                        Text(codeCopied ? "Copié !" : "Copier le code")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(codeCopied ? .green : cardColor)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(codeCopied ? .green.opacity(0.12) : cardColor.opacity(0.12))
                    .clipShape(Capsule())
                    .animation(.spring(duration: 0.3), value: codeCopied)
                }
                .accessibilityLabel(codeCopied ? "Code copié" : "Copier le code \(coupon.code)")
                .buttonStyle(CardPressStyle())
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)

            Divider().padding(.horizontal, 20)

            // QR code généré
            VStack(spacing: 12) {
                Button {
                    withAnimation(.spring(duration: 0.3)) { showQR.toggle() }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    HStack {
                        Image(systemName: "qrcode")
                            .font(.callout)
                        Text(showQR ? "Masquer le QR code" : "Afficher le QR code")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .rotationEffect(.degrees(showQR ? 180 : 0))
                            .animation(.spring(duration: 0.3), value: showQR)
                    }
                    .foregroundStyle(.secondary)
                }
                .accessibilityLabel(showQR ? "Masquer le QR code" : "Afficher le QR code")

                if showQR {
                    QRCodeView(code: coupon.code)
                        .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .top)))

                    Text("Présente ce QR code en caisse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 16)
    }

    // MARK: - Section infos

    private var infoSection: some View {
        VStack(spacing: 0) {
            infoRow(
                icon: coupon.category.icon,
                label: "Catégorie",
                iconColor: coupon.category.color,
                content: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(coupon.category.color)
                            .frame(width: 8, height: 8)
                        Text(coupon.category.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            )

            rowDivider

            infoRow(icon: "calendar.badge.plus", label: "Ajouté le", iconColor: .blue) {
                Text(coupon.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            rowDivider

            if let date = coupon.expirationDate {
                infoRow(
                    icon: coupon.isExpired ? "calendar.badge.exclamationmark" : "calendar.badge.clock",
                    label: "Expiration",
                    iconColor: coupon.isExpired ? .red : (coupon.isExpiringSoon ? .orange : .secondary)
                ) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(expirationLabel)
                            .font(.caption2)
                            .foregroundStyle(coupon.isExpired ? .red : (coupon.isExpiringSoon ? .orange : .secondary))
                    }
                }
                rowDivider
            }

            infoRow(icon: sourceIcon, label: "Source", iconColor: .secondary) {
                Text(coupon.source.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            if coupon.isUsed {
                rowDivider
                infoRow(icon: "checkmark.circle.fill", label: "Statut", iconColor: .green) {
                    Text("Utilisé")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 16)
    }

    // MARK: - Section actions

    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Marquer comme utilisé / Réactiver
            Button { toggleUsed() } label: {
                HStack(spacing: 10) {
                    Image(systemName: coupon.isUsed ? "arrow.uturn.backward.circle.fill" : "checkmark.circle.fill")
                        .font(.title3)
                    Text(coupon.isUsed ? "Réactiver ce bon" : "Marquer comme utilisé")
                        .font(.body)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(coupon.isUsed ? Color(.secondarySystemGroupedBackground) : cardColor)
                .foregroundStyle(coupon.isUsed ? AnyShapeStyle(Color.secondary) : AnyShapeStyle(Color.white))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .animation(.spring(duration: 0.3), value: coupon.isUsed)
            }
            .buttonStyle(CardPressStyle())
            .accessibilityLabel(coupon.isUsed ? "Réactiver le bon \(coupon.brand)" : "Marquer \(coupon.brand) comme utilisé")

            // Modifier + Supprimer
            HStack(spacing: 12) {
                Button { showEdit = true } label: {
                    Label("Modifier", systemImage: "pencil")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(.primary)
                }

                Button { showDeleteConfirm = true } label: {
                    Label("Supprimer", systemImage: "trash")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 4) {
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.callout)
                        .fontWeight(.medium)
                }
                Menu {
                    Button { showEdit = true } label: {
                        Label("Modifier", systemImage: "pencil")
                    }
                    Button { toggleUsed() } label: {
                        Label(
                            coupon.isUsed ? "Réactiver" : "Marquer comme utilisé",
                            systemImage: coupon.isUsed ? "arrow.uturn.backward" : "checkmark.circle"
                        )
                    }
                    Divider()
                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        Label("Supprimer", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.callout)
                        .fontWeight(.medium)
                }
            }
        }
    }

    // MARK: - Helpers

    private var rowDivider: some View {
        Divider().padding(.leading, 52)
    }

    private func infoRow<Content: View>(
        icon: String,
        label: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundStyle(iconColor)
            }

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private var expirationLabel: String {
        guard let date = coupon.expirationDate else { return "" }
        let days = Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 0
        if coupon.isExpired { return "Expiré il y a \(abs(days))j" }
        switch days {
        case 0:  return "Expire aujourd'hui !"
        case 1:  return "Expire demain"
        default: return "Expire dans \(days) jours"
        }
    }

    private var sourceIcon: String {
        switch coupon.source {
        case .manual:         return "pencil"
        case .scan:           return "qrcode.viewfinder"
        case .shareExtension: return "square.and.arrow.up"
        }
    }

    private var shareText: String {
        var lines = ["🎟 \(coupon.brand) — \(coupon.value)"]
        if !coupon.code.isEmpty        { lines.append("Code : \(coupon.code)") }
        if let d = coupon.expirationDate { lines.append("Valable jusqu'au \(d.formatted(date: .long, time: .omitted))") }
        if let n = coupon.notes, !n.isEmpty { lines.append(n) }
        lines.append("\nPartagé depuis Vault 🏷")
        return lines.joined(separator: "\n")
    }

    // MARK: - Actions

    private func copyCode() {
        UIPasteboard.general.string = coupon.code
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation { codeCopied = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { codeCopied = false }
        }
    }

    private func toggleUsed() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(duration: 0.3)) { coupon.isUsed.toggle() }
        coupon.usedAt = coupon.isUsed ? .now : nil

        let isPremium = SubscriptionService.shared.subscription.isPremium
        if coupon.isUsed {
            NotificationService.shared.cancel(for: coupon)
            ReviewManager.onCouponUsed()   // Demande un avis après le 3e bon utilisé
        } else {
            NotificationService.shared.schedule(for: coupon, isPremium: isPremium)
        }
    }

    private func deleteCoupon() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        NotificationService.shared.cancel(for: coupon)
        modelContext.delete(coupon)
        dismiss()
    }
}

// MARK: - QR Code view

private struct QRCodeView: View {
    let code: String

    private var qrImage: UIImage? {
        guard !code.isEmpty,
              let data = code.data(using: .isoLatin1) ?? code.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator")
        else { return nil }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let ciImage = filter.outputImage else { return nil }
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    var body: some View {
        if let image = qrImage {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 170, height: 170)
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        } else {
            // Fallback si génération impossible
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.secondary.opacity(0.1))
                    .frame(width: 170, height: 170)
                VStack(spacing: 8) {
                    Image(systemName: "qrcode")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("QR code indisponible")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Feuille de modification

private struct EditCouponSheet: View {
    let coupon: Coupon
    @Environment(\.dismiss) private var dismiss

    @State private var brand: String
    @State private var value: String
    @State private var code: String
    @State private var category: Category
    @State private var notes: String
    @State private var hasExpiration: Bool
    @State private var expirationDate: Date

    private var isValid: Bool {
        !brand.trimmingCharacters(in: .whitespaces).isEmpty &&
        !value.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init(coupon: Coupon) {
        self.coupon = coupon
        _brand        = State(initialValue: coupon.brand)
        _value        = State(initialValue: coupon.value)
        _code         = State(initialValue: coupon.code)
        _category     = State(initialValue: coupon.category)
        _notes        = State(initialValue: coupon.notes ?? "")
        _hasExpiration = State(initialValue: coupon.expirationDate != nil)
        _expirationDate = State(initialValue: coupon.expirationDate
                                ?? Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Marque & valeur") {
                    TextField("Marque", text: $brand)
                    TextField("Valeur", text: $value)
                }

                Section("Code promo") {
                    TextField("Code ou numéro de carte", text: $code)
                        .font(.system(.body, design: .monospaced))
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }

                Section("Catégorie") {
                    Picker("Catégorie", selection: $category) {
                        ForEach(Category.allCases) { cat in
                            Label(cat.displayName, systemImage: cat.icon).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Expiration") {
                    Toggle(isOn: $hasExpiration.animation()) {
                        Label(hasExpiration ? "Avec date" : "Sans expiration",
                              systemImage: hasExpiration ? "calendar.badge.clock" : "infinity")
                    }
                    .tint(.blue)
                    if hasExpiration {
                        DatePicker("Date", selection: $expirationDate, in: Date.now..., displayedComponents: .date)
                    }
                }

                Section("Notes") {
                    TextField("Conditions, restrictions…", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle("Modifier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") { applyChanges() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
        }
    }

    private func applyChanges() {
        coupon.brand          = brand.trimmingCharacters(in: .whitespaces)
        coupon.value          = value.trimmingCharacters(in: .whitespaces)
        coupon.code           = code.trimmingCharacters(in: .whitespaces)
        coupon.category       = category
        coupon.notes          = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes
        coupon.expirationDate = hasExpiration ? expirationDate : nil

        // Replanifie les notifications avec les nouvelles données
        let isPremium = SubscriptionService.shared.subscription.isPremium
        NotificationService.shared.schedule(for: coupon, isPremium: isPremium)

        dismiss()
    }
}

// MARK: - Extension label source

private extension CouponSource {
    var label: String {
        switch self {
        case .manual:         return "Saisie manuelle"
        case .scan:           return "Scanner QR"
        case .shareExtension: return "Share Extension"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CouponDetailView(coupon: PreviewCoupons.mcdo)
    }
    .modelContainer(for: Coupon.self, inMemory: true)
}
