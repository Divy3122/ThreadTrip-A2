import SwiftUI

@main
struct ThreadTripApp: App {
    @StateObject private var tripOverview = TripOverviewViewModel(
        trip: JapanTripSample.japanTrip,
        generateGroupActivityDeck: GenerateGroupActivityDeckUseCase(
            activityCatalogue: LocalJSONTravelActivityCatalogue()
        )
    )

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                TripOverviewView(viewModel: tripOverview)
            }
            .tint(.indigo)
        }
    }
}
