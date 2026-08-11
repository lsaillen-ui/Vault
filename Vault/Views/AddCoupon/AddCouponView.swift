import SwiftUI
import SwiftData

struct AddCouponView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingCoupons: [Coupon]

    @State private var vm = AddCouponViewModel()
    @State private var showScanner = false
    @State private var showPaywall = false
    @FocusState private var focusedField: Field?

    private enum Field: Hashable { case brand, value, code, notes }

    private var isPremium: Bool { SubscriptionService.shared.subscription.isPremium }
    private var couponCount: Int { existingCoupons.count }
    private var canAdd: Bool { SubscriptionService.shared.canAddCoupon(currentCount: couponCount) }

    private var brandSuggestions: [String] {
        guard vm.brand.count >= 2 else { return [] }
        let existing = Set(existingCoupons.map(\.brand))
        return existing
            .filter { $0.localizedCaseInsensitiveContains(vm.brand) && $0.lowercased() != vm.brand.lowercased() }
            .sorted()
            .prefix(5)
            .map { $0 }
    }

    private var previewCoupon: Coupon {
        Coupon(
            brand: vm.brand.isEmpty ? "Ma marque" : vm.brand,
            value: vm.value.isEmpty ? "Valeur" : vm.value,
            code: vm.code,
            category: vm.category,
            expirationDate: vm.hasExpiration ? vm.expirationDate : nil,
            notes: vm.notes.isEmpty ? nil : vm.notes,
            cardColor: vm.cardColor
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    cardPreviewSection
                    limitBanner
                    formSections
                }
                .animation(.spring(duration: 0.3), value: couponCount)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Nouveau bon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarItems }
            .sheet(isPresented: $showScanner) {
                ScannerView { scanned in
                    vm.code = scanned
                    showScanner = false
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(limitReached: true)
            }
            .onChange(of: vm.category) { vm.syncColorWithCategory() }
        }
    }

    // MARK: - Bannière limite freemium

    @ViewBuilder
    private var limitBanner: some View {
        if !isPremium && couponCount >= UserSubscription.maxFreeCoupons - 3 {
            let remaining = max(0, UserSubscription.maxFreeCoupons - couponCount)
            let atLimit = remaining == 0
            let accent: Color = atLimit ? .red : .orange

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showPaywall = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: atLimit ? "lock.fill" : "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(accent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(atLimit
                             ? "Limite atteinte — Passe à Premium"
                             : "Plus que \(remaining) bon\(remaining > 1 ? "s" : "") gratuit\(remaining > 1 ? "s" : "")")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Text("\(couponCount)/\(UserSubscription.maxFreeCoupons) bons utilisés")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("Débloquer →")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(accent)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(accent.opacity(0.09))
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .strokeBorder(accent.opacity(0.28), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityLabel(atLimit
                ? "Limite de \(UserSubscription.maxFreeCoupons) bons atteinte. Appuie pour passer à Premium."
                : "Plus que \(remaining) bon\(remaining > 1 ? "s" : "") gratuit\(remaining > 1 ? "s" : ""). Appuie pour débloquer Premium.")
        }
    }

    // MARK: - Prévisualisation live

    private var cardPreviewSection: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: vm.cardColor).opacity(0.18), Color(.systemGroupedBackground)],
                startPoint: .top,
                endPoint: .bottom
            )

            CouponCardView(coupon: previewCoupon, isCompact: false)
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .animation(.spring(duration: 0.35, bounce: 0.1), value: vm.cardColor)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Sections du formulaire

    private var formSections: some View {
        VStack(spacing: 20) {
            brandSection
            valueSection
            codeSection
            categorySection
            expirationSection
            notesSection
            colorSection
        }
        .padding(16)
        .padding(.bottom, 32)
    }

    // MARK: Marque

    private var brandSection: some View {
        formCard("Marque / Magasin") {
            VStack(alignment: .leading, spacing: 0) {
                TextField("ex : McDonald's, Zalando…", text: $vm.brand)
                    .focused($focusedField, equals: .brand)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .value }
                    .font(.body)
                    .accessibilityLabel("Nom de la marque ou du magasin")

                if !brandSuggestions.isEmpty {
                    Divider().padding(.top, 10)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(brandSuggestions, id: \.self) { suggestion in
                                Button {
                                    withAnimation(.spring(duration: 0.2)) {
                                        vm.brand = suggestion
                                        focusedField = .value
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                } label: {
                                    Label(suggestion, systemImage: "clock.arrow.circlepath")
                                        .font(.caption)
                                        .padding(.horizontal, 11)
                                        .padding(.vertical, 6)
                                        .background(.blue.opacity(0.1))
                                        .foregroundStyle(.blue)
                                        .clipShape(Capsule())
                                }
                                .accessibilityLabel("Suggestion : \(suggestion)")
                            }
                        }
                        .padding(.top, 10)
                    }
                }
            }
        }
    }

    // MARK: Valeur

    private let valuePresets = ["−10%", "−20%", "−30%", "−50%", "CHF 10", "CHF 25", "CHF 50", "Livraison offerte", "2+1 gratuit"]

    private var valueSection: some View {
        formCard("Valeur du bon") {
            VStack(alignment: .leading, spacing: 0) {
                TextField("ex : −20%, CHF 25, Livraison offerte…", text: $vm.value)
                    .focused($focusedField, equals: .value)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .code }
                    .font(.body)
                    .accessibilityLabel("Valeur du bon, par exemple moins vingt pourcent ou CHF 25")

                Divider().padding(.top, 10)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(valuePresets, id: \.self) { preset in
                            Button {
                                withAnimation(.spring(duration: 0.2)) { vm.value = preset }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                Text(preset)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 11)
                                    .padding(.vertical, 6)
                                    .background(vm.value == preset ? Color(hex: vm.cardColor) : Color(hex: vm.cardColor).opacity(0.12))
                                    .foregroundStyle(vm.value == preset ? .white : Color(hex: vm.cardColor))
                                    .clipShape(Capsule())
                            }
                            .accessibilityLabel("\(preset)\(vm.value == preset ? ", sélectionné" : "")")
                            .accessibilityAddTraits(vm.value == preset ? [.isButton, .isSelected] : .isButton)
                        }
                    }
                    .padding(.top, 10)
                }
            }
        }
    }

    // MARK: Code promo

    private var codeSection: some View {
        formCard("Code promo") {
            HStack(spacing: 12) {
                TextField("ex : SAVE20, PROMO2024…", text: $vm.code)
                    .focused($focusedField, equals: .code)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .notes }
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Code promo ou numéro de carte")

                if focusedField == .code {
                    Button {
                        if let clipboard = UIPasteboard.general.string, !clipboard.isEmpty {
                            withAnimation { vm.code = clipboard }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    } label: {
                        Image(systemName: "doc.on.clipboard")
                            .font(.callout)
                            .foregroundStyle(.blue)
                    }
                    .accessibilityLabel("Coller depuis le presse-papiers")
                }

                Button {
                    showScanner = true
                } label: {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Scanner un QR code ou code-barres")
            }
        }
    }

    // MARK: Catégorie

    private var categorySection: some View {
        formCard("Catégorie") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Category.allCases) { cat in
                        Button {
                            withAnimation(.spring(duration: 0.25)) {
                                vm.category = cat
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(vm.category == cat ? cat.color : cat.color.opacity(0.12))
                                        .frame(width: 46, height: 46)
                                    Image(systemName: cat.icon)
                                        .font(.callout)
                                        .foregroundStyle(vm.category == cat ? .white : cat.color)
                                }
                                .overlay(
                                    Circle()
                                        .strokeBorder(cat.color.opacity(vm.category == cat ? 0 : 0.3), lineWidth: 1.5)
                                )
                                .scaleEffect(vm.category == cat ? 1.08 : 1.0)
                                .animation(.spring(duration: 0.25, bounce: 0.3), value: vm.category == cat)

                                Text(cat.displayName)
                                    .font(.caption2)
                                    .fontWeight(vm.category == cat ? .semibold : .regular)
                                    .foregroundStyle(vm.category == cat ? cat.color : .secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .frame(width: 54)
                            }
                        }
                        .accessibilityLabel("\(cat.displayName)\(vm.category == cat ? ", sélectionné" : "")")
                        .accessibilityAddTraits(vm.category == cat ? [.isButton, .isSelected] : .isButton)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: Date d'expiration

    private var expirationSection: some View {
        formCard("Date d'expiration") {
            VStack(spacing: 12) {
                Toggle(isOn: $vm.hasExpiration.animation(.spring(duration: 0.25))) {
                    Label(
                        vm.hasExpiration ? "Avec date d'expiration" : "Sans expiration",
                        systemImage: vm.hasExpiration ? "calendar.badge.clock" : "infinity"
                    )
                    .font(.subheadline)
                }
                .tint(.blue)

                if vm.hasExpiration {
                    Divider()
                    DatePicker(
                        "Date",
                        selection: $vm.expirationDate,
                        in: Date.now...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel("Date d'expiration du bon")
                }
            }
        }
    }

    // MARK: Notes

    private var notesSection: some View {
        formCard("Notes (optionnel)") {
            TextField(
                "Conditions d'utilisation, restrictions…",
                text: $vm.notes,
                axis: .vertical
            )
            .focused($focusedField, equals: .notes)
            .lineLimit(2...5)
            .font(.body)
            .accessibilityLabel("Notes et conditions du bon")
        }
    }

    // MARK: Couleur de la carte

    private let colorPresets = [
        "007AFF", "FF6B9D", "FF9500", "30D158",
        "AF52DE", "FF2D55", "32ADE6", "5856D6",
        "FF3B30", "34C759", "FFD60A", "8E8E93",
    ]

    private func colorName(_ hex: String) -> String {
        switch hex {
        case "007AFF": return "Bleu"
        case "FF6B9D": return "Rose"
        case "FF9500": return "Orange"
        case "30D158": return "Vert"
        case "AF52DE": return "Violet"
        case "FF2D55": return "Rouge vif"
        case "32ADE6": return "Bleu ciel"
        case "5856D6": return "Indigo"
        case "FF3B30": return "Rouge"
        case "34C759": return "Vert clair"
        case "FFD60A": return "Jaune"
        case "8E8E93": return "Gris"
        default: return hex
        }
    }

    private var colorSection: some View {
        formCard("Couleur de la carte") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(colorPresets, id: \.self) { hex in
                        let isSelected = vm.cardColor == hex
                        Button {
                            withAnimation(.spring(duration: 0.2)) { vm.cardColor = hex }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Circle()
                                        .strokeBorder(.white, lineWidth: isSelected ? 3 : 0)
                                )
                                .shadow(color: Color(hex: hex).opacity(isSelected ? 0.5 : 0), radius: 6)
                                .scaleEffect(isSelected ? 1.15 : 1)
                                .animation(.spring(duration: 0.2, bounce: 0.3), value: isSelected)
                        }
                        .accessibilityLabel("\(colorName(hex))\(isSelected ? ", sélectionné" : "")")
                        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Annuler") {
                vm.reset()
                dismiss()
            }
            .foregroundStyle(.secondary)
        }
        ToolbarItem(placement: .confirmationAction) {
            Button {
                save()
            } label: {
                Text("Enregistrer")
                    .fontWeight(.semibold)
            }
            .disabled(!vm.isValid)
        }
    }

    // MARK: - Actions

    private func save() {
        guard canAdd else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            showPaywall = true
            return
        }
        let coupon = vm.buildCoupon()
        modelContext.insert(coupon)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        let premium = SubscriptionService.shared.subscription.isPremium
        NotificationService.shared.schedule(for: coupon, isPremium: premium)
        vm.reset()
        dismiss()
    }

    // MARK: - Helper : carte de section

    @ViewBuilder
    private func formCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.4)
                .padding(.horizontal, 4)

            content()
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

// MARK: - Preview

#Preview {
    AddCouponView()
        .modelContainer(for: Coupon.self, inMemory: true)
}
