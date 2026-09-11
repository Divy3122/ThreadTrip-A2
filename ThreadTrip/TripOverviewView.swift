import SwiftUI

struct TripOverviewView: View {
    @ObservedObject var viewModel: TripOverviewViewModel

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("1 OF 4 · TRIP OVERVIEW")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.indigo)
                    Text(viewModel.trip.title + " 🇯🇵")
                        .font(.largeTitle.bold())
                    Text(viewModel.trip.destinationCities.joined(separator: " • "))
                    Label(viewModel.tripDateText, systemImage: "calendar")
                    Text("\(viewModel.trip.durationInDays) days · \(viewModel.tripBudgetText) per traveller")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Your travel crew") {
                ForEach(viewModel.trip.activeMembers) { member in
                    Label(member.displayName, systemImage: "person.crop.circle")
                }
            }

            Section {
                ForEach(TravelInterest.allCases) { interest in
                    Toggle(isOn: Binding(
                        get: { viewModel.selectedInterests.contains(interest) },
                        set: { _ in viewModel.toggleInterest(interest) }
                    )) {
                        Label(interest.title, systemImage: interest.symbolName)
                    }
                    .disabled(!viewModel.canGenerateDeck)
                }
            } header: {
                Text("Shared interests")
            } footer: {
                Text("These preferences create one shared deck. Every traveller sees the same activities in the same order.")
            }

            Section("Activity budget per traveller") {
                LabeledContent("Maximum", value: viewModel.activityBudgetText)
                Slider(value: Binding(
                    get: { viewModel.activityBudget },
                    set: viewModel.updateActivityBudget
                ), in: 25...300, step: 25)
                .accessibilityLabel("Maximum activity cost")
                .disabled(!viewModel.canGenerateDeck)
            }

            Section {
                Picker("Acceptance rule", selection: Binding(
                    get: { viewModel.trip.decisionPolicy },
                    set: viewModel.updateDecisionPolicy
                )) {
                    ForEach(GroupDecisionPolicy.allCases) { policy in
                        Text(policy.title).tag(policy)
                    }
                }
                .disabled(!viewModel.canGenerateDeck)
                Text(viewModel.trip.decisionPolicy.explanation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("How the group will decide")
            }

            Section {
                if let deck = viewModel.generatedDeck {
                    Label("Shared deck locked", systemImage: "lock.fill")
                        .foregroundStyle(.indigo)
                    Text("\(deck.candidates.count) activities · \(deck.votingRound.eligibleMemberIDs.count) travellers")
                    Text("Preferences are now locked for this voting round.")
                        .font(.footnote)
                    if let voting = viewModel.voting {
                        NavigationLink("Open activity voting") {
                            GroupSwipeDeckView(viewModel: voting)
                        }
                    }
                } else {
                    Button("Generate shared activity deck", systemImage: "sparkles") {
                        viewModel.generateSharedDeck()
                    }
                }
                if let message = viewModel.errorMessage {
                    Label(message, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("ThreadTrip")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TripOverviewView(viewModel: TripOverviewViewModel(
            trip: JapanTripSample.japanTrip,
            generateGroupActivityDeck: GenerateGroupActivityDeckUseCase(
                activityCatalogue: LocalJSONTravelActivityCatalogue()
            )
        ))
    }
}
