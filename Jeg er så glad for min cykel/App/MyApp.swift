import SwiftUI

@main struct MyApp: App {
    @State private var garage = Garage()
    /// "system", "light" eller "dark". Vælges under Profil → Indstillinger.
    @AppStorage("appearance") private var appearance = "system"

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(garage)
                .preferredColorScheme(appearance == "light" ? .light : appearance == "dark" ? .dark : nil)
        }
    }
}

struct RootView: View {
    @Environment(Garage.self) private var garage

    var body: some View {
        if garage.bike == nil {
            // Første gang: tilføj en cykel før resten af appen giver mening.
            AddBikeView()
        } else {
            
            TabView {
                Tab("Værksted", systemImage: "wrench.and.screwdriver") {
                    GarageView()
                }
                Tab("Mekanikere", systemImage: "map") {
                    MechanicMapView()
                }
                Tab("Profil", systemImage: "person.crop.circle") {
                    ProfileView()
                }
            }
        }
    }
}
