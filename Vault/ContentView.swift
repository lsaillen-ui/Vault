import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem { Label("Accueil", systemImage: "house.fill") }
                .tag(0)

            CategoriesView()
                .tabItem { Label("Catégories", systemImage: "square.grid.2x2.fill") }
                .tag(1)

            AddCouponView()
                .tabItem { Label("Ajouter", systemImage: "plus.circle.fill") }
                .tag(2)

            AlertsView()
                .tabItem { Label("Alertes", systemImage: "bell.fill") }
                .tag(3)

            SettingsView()
                .tabItem { Label("Réglages", systemImage: "gearshape.fill") }
                .tag(4)
        }
        .tint(.blue)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: Coupon.self, inMemory: true)
}
