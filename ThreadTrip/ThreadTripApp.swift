import SwiftUI

@main
struct ThreadTripApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentUnavailableView("ThreadTrip", systemImage: "airplane", description: Text("Plan Japan together. Trip setup is the first milestone."))
                    .navigationTitle("ThreadTrip")
            }
        }
    }
}
