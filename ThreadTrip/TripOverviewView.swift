import SwiftUI

struct TripOverviewView: View {

    @ObservedObject var viewModel: TripOverviewViewModel

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var textSize

    private let coral = Color(red: 0.88, green: 0.25, blue: 0.22)
    private let indigo = Color(red: 0.27, green: 0.24, blue: 0.57)

    private var cardColor: Color {
        Color(uiColor: .secondarySystemGroupedBackground)
    }

    private var canvas: Color {
        if colorScheme == .dark {
            return Color(uiColor: .systemGroupedBackground)
        } else {
            return Color(red: 0.97, green: 0.96, blue: 0.94)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                tripCard
                crewCard
                preferencesCard
                deckControls
            }
            .padding(20)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(canvas.ignoresSafeArea())
        .navigationTitle("ThreadTrip")
        .navigationBarTitleDisplayMode(.inline)
        .tint(coral)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack {
                Text("LET’S PLAN SOMETHING GREAT")
                    .font(.caption2.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(coral)

                Spacer()

                Text("1 of 4")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(coral.opacity(0.10), in: Capsule())
            }

            Text("One trip. Everyone’s ideas.")
                .font(.title2.bold())

            Text("Turn your saved places into a plan together.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Trip Card

    private var tripCard: some View {
        VStack(alignment: .leading, spacing: 20) {

            HStack(alignment: .top) {

                VStack(alignment: .leading, spacing: 8) {
                    Text("YOUR NEXT ADVENTURE")
                        .font(.caption2.bold())
                        .tracking(1.2)

                    Text(viewModel.trip.title)
                        .font(.largeTitle.bold())

                    Text(viewModel.trip.destinationCities.joined(separator: " · "))
                        .font(.subheadline)
                }

                Spacer(minLength: 8)

                Text("🇯🇵")
                    .font(.largeTitle)
                    .padding(10)
                    .background(
                        .white.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .accessibilityLabel("Japan")
            }

            Label(viewModel.tripDateText, systemImage: "calendar")
                .font(.subheadline.weight(.medium))

            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(height: 1)

            ViewThatFits(in: .horizontal) {

                HStack(spacing: 28) {
                    tripMetric(
                        "\(viewModel.trip.durationInDays) days",
                        caption: "Time to explore",
                        symbol: "sun.max"
                    )

                    tripMetric(
                        viewModel.tripBudgetText,
                        caption: "Budget per traveller",
                        symbol: "wallet.bifold"
                    )
                }

                VStack(alignment: .leading, spacing: 16) {
                    tripMetric(
                        "\(viewModel.trip.durationInDays) days",
                        caption: "Time to explore",
                        symbol: "sun.max"
                    )

                    tripMetric(
                        viewModel.tripBudgetText,
                        caption: "Budget per traveller",
                        symbol: "wallet.bifold"
                    )
                }
            }
        }
        .foregroundStyle(.white)
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    indigo,
                    Color(red: 0.49, green: 0.28, blue: 0.53)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 26)
        )
        .shadow(
            color: indigo.opacity(0.20),
            radius: 16,
            y: 8
        )
    }

    private func tripMetric(
        _ value: String,
        caption: String,
        symbol: String
    ) -> some View {

        VStack(alignment: .leading, spacing: 5) {
            Label(value, systemImage: symbol)
                .font(.headline)

            Text(caption)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
        }
    }

    // MARK: - Crew Card

    private var crewCard: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack {
                Text("Your travel crew")
                    .font(.headline)

                Spacer()

                Text("\(viewModel.trip.activeMembers.count) travellers")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(
                columns: [
                    GridItem(
                        .adaptive(
                            minimum: textSize.isAccessibilitySize ? 90 : 65
                        )
                    )
                ],
                spacing: 14
            ) {

                ForEach(viewModel.trip.activeMembers) { member in

                    VStack(spacing: 6) {
                        Text(member.initials)
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                member.id == viewModel.trip.activeMembers.first?.id
                                ? coral
                                : indigo,
                                in: Circle()
                            )

                        Text(member.displayName)
                            .font(.caption)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(member.displayName)
                }
            }

            Text("Different tastes. One shared adventure.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(
            cardColor,
            in: RoundedRectangle(cornerRadius: 22)
        )
    }

    // MARK: - Preferences

    private var preferencesCard: some View {
        VStack(alignment: .leading, spacing: 22) {

            VStack(alignment: .leading, spacing: 6) {
                Text("Build your shared deck")
                    .font(.title3.bold())

                Text("Pick what your group loves. We’ll find activities for everyone to vote on.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("WHAT’S YOUR TRAVEL STYLE?")

                LazyVGrid(
                    columns: [
                        GridItem(
                            .adaptive(
                                minimum: textSize.isAccessibilitySize ? 230 : 135
                            )
                        )
                    ],
                    spacing: 10
                ) {

                    ForEach(TravelInterest.allCases) { interest in
                        interestChip(interest)
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("ACTIVITY BUDGET")

                Text(viewModel.activityBudgetText)
                    .font(.title2.bold())

                Text("Maximum estimated cost per traveller")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Slider(
                    value: Binding(
                        get: {
                            viewModel.activityBudget
                        },
                        set: {
                            viewModel.updateActivityBudget($0)
                        }
                    ),
                    in: 25...300,
                    step: 25
                )
                .accessibilityLabel("Maximum activity cost per traveller")
                .accessibilityValue(viewModel.activityBudgetText)
                .disabled(!viewModel.canGenerateDeck)

                HStack {
                    Text("25 \(viewModel.trip.tasteProfile.currencyCode)")

                    Spacer()

                    Text("300 \(viewModel.trip.tasteProfile.currencyCode)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("HOW WILL YOUR GROUP DECIDE?")

                Picker(
                    "Acceptance rule",
                    selection: Binding(
                        get: {
                            viewModel.trip.decisionPolicy
                        },
                        set: {
                            viewModel.updateDecisionPolicy($0)
                        }
                    )
                ) {

                    ForEach(GroupDecisionPolicy.allCases) { policy in
                        Text(policy.title)
                            .tag(policy)
                    }
                }
                .pickerStyle(.menu)
                .disabled(!viewModel.canGenerateDeck)

                Text(viewModel.trip.decisionPolicy.explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Label(
                "One locked deck. The same activities, in the same order, for every traveller.",
                systemImage: "person.3.fill"
            )
            .font(.caption)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                coral.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
        .padding(20)
        .background(
            cardColor,
            in: RoundedRectangle(cornerRadius: 22)
        )
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption2.bold())
            .tracking(0.8)
            .foregroundStyle(.secondary)
    }

    private func interestChip(_ interest: TravelInterest) -> some View {
        let selected = viewModel.selectedInterests.contains(interest)

        return Button {
            viewModel.toggleInterest(interest)
        } label: {

            HStack(spacing: 7) {
                Image(systemName: interest.symbolName)

                Text(interest.title)

                Spacer(minLength: 0)

                if selected {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                }
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(selected ? Color.white : Color.primary)
            .background(
                selected
                ? coral
                : Color(uiColor: .tertiarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 13)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(interest.title)
        .accessibilityValue(selected ? "Selected" : "Not selected")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .disabled(!viewModel.canGenerateDeck)
    }

    // MARK: - Deck Controls

    private var deckControls: some View {
        VStack(alignment: .leading, spacing: 14) {

            if let deck = viewModel.generatedDeck {

                VStack(alignment: .leading, spacing: 6) {
                    Label(
                        "Your shared deck is ready",
                        systemImage: "checkmark.seal.fill"
                    )
                    .font(.headline)

                    Text(
                        "\(deck.candidates.count) activities · \(deck.votingRound.eligibleMemberIDs.count) travellers"
                    )
                    .font(.subheadline)

                    Text("Preferences are locked. Let’s find your group’s favourites.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    cardColor,
                    in: RoundedRectangle(cornerRadius: 18)
                )

                if let voting = viewModel.voting {

                    NavigationLink {
                        GroupSwipeDeckView(
                            viewModel: voting,
                            decisionPolicy: viewModel.trip.decisionPolicy
                        )
                    } label: {
                        actionLabel(
                            "Open activity voting",
                            symbol: "hand.draw.fill",
                            color: indigo
                        )
                    }
                    .buttonStyle(.plain)
                }

            } else {

                Button {
                    viewModel.generateSharedDeck()
                } label: {
                    actionLabel(
                        "Generate shared activity deck",
                        symbol: "sparkles",
                        color: coral
                    )
                }
                .buttonStyle(.plain)
            }

            if let message = viewModel.errorMessage {
                Label(
                    message,
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.subheadline)
                .foregroundStyle(.red)
                .padding(16)
                .background(
                    cardColor,
                    in: RoundedRectangle(cornerRadius: 14)
                )
            }
        }
    }

    // MARK: - Action Button

    private func actionLabel(
        _ title: String,
        symbol: String,
        color: Color
    ) -> some View {

        HStack(spacing: 12) {
            Image(systemName: symbol)

            Text(title)

            Spacer(minLength: 0)

            Image(systemName: "arrow.right")
        }
        .font(.headline)
        .foregroundStyle(.white)
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 58)
        .background(
            color,
            in: RoundedRectangle(cornerRadius: 18)
        )
    }
}

#Preview {
    NavigationStack {
        TripOverviewView(
            viewModel: TripOverviewViewModel(
                trip: JapanTripSample.japanTrip,
                generateGroupActivityDeck: GenerateGroupActivityDeckUseCase(
                    activityCatalogue: LocalJSONTravelActivityCatalogue()
                )
            )
        )
    }
}
