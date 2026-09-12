import SwiftUI

struct GroupSwipeDeckView: View {

    @ObservedObject var viewModel: GroupSwipeDeckViewModel

    let trip: GroupTrip
    let decisionPolicy: GroupDecisionPolicy

    @GestureState private var dragOffset: CGSize = .zero

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                travellerPicker
                votingProgress
                votingContent
                groupProgress
            }
            .padding(20)
        }
        .navigationTitle("Activity voting")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "Could not save response",
            isPresented: errorAlertBinding
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(
                viewModel.errorMessage
                ?? "Try responding to this activity again."
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("2 OF 4 · ACTIVITY VOTING")
                .font(.caption.weight(.bold))
                .foregroundStyle(.indigo)

            Text("What would you enjoy?")
                .font(.largeTitle.bold())

            Text(
                "Prototype: pass the phone or select a traveller to try their deck. Responses stay on this device until the app closes."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Traveller Picker

    private var travellerPicker: some View {
        Picker(
            "Voting as",
            selection: $viewModel.selectedMemberID
        ) {
            ForEach(viewModel.members) { member in
                Text(member.displayName)
                    .tag(member.id)
            }
        }
        .pickerStyle(.menu)
    }

    // MARK: - Voting Progress

    private var votingProgress: some View {
        VStack(alignment: .leading, spacing: 10) {

            ProgressView(
                value: Double(viewModel.memberSwipes.count),
                total: Double(viewModel.deck.candidates.count)
            )

            Text(
                "\(viewModel.memberSwipes.count) of \(viewModel.deck.candidates.count) answered · \(currentTravellerName)"
            )
            .font(.subheadline)

            Label(
                "Same activities. Same order. Your own Yes or No.",
                systemImage: "lock.fill"
            )
            .font(.footnote)
            .foregroundStyle(.indigo)
        }
    }

    // MARK: - Voting

    @ViewBuilder
    private var votingContent: some View {
        if let candidate = viewModel.currentCandidate {
            currentActivitySection(candidate)
        } else {
            completedMemberCard
        }
    }

    private func currentActivitySection(
        _ candidate: ActivityCandidate
    ) -> some View {

        VStack(alignment: .leading, spacing: 16) {

            activityCard(candidate)
                .offset(x: dragOffset.width)
                .rotationEffect(
                    .degrees(
                        Double(dragOffset.width / 25)
                    )
                )
                .gesture(swipeGesture)
                .id(candidate.id)

            votingButtons

            Text(
                "Swipe left for No, right for Yes, or use the buttons."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }

    private var votingButtons: some View {
        HStack(spacing: 16) {

            Button {
                viewModel.recordSwipe(.no)
            } label: {
                Label(
                    "No",
                    systemImage: "xmark"
                )
                .frame(maxWidth: .infinity)
            }
            .tint(.red)

            Button {
                viewModel.recordSwipe(.yes)
            } label: {
                Label(
                    "Yes",
                    systemImage: "heart.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .tint(.indigo)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    private var swipeGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in

                if value.translation.width > 100 {
                    viewModel.recordSwipe(.yes)
                }

                if value.translation.width < -100 {
                    viewModel.recordSwipe(.no)
                }
            }
    }

    // MARK: - Traveller Finished

    private var completedMemberCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            Label(
                "Your votes are saved",
                systemImage: "checkmark.circle.fill"
            )
            .font(.title2.bold())

            Text(
                "Yes: \(yesVoteCount) · No: \(noVoteCount)"
            )

            Text(
                "Select another traveller above to continue the group's voting."
            )
        }
        .padding()
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            .indigo.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    // MARK: - Group Progress

    private var groupProgress: some View {
        VStack(alignment: .leading, spacing: 14) {

            Text(
                "\(viewModel.completedTravellerCount) of \(totalTravellerCount) travellers finished"
            )
            .font(.headline)

            if everyoneHasFinished {
                dashboardReadyCard
            }
        }
    }

    private var dashboardReadyCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            Label(
                "Everyone has voted",
                systemImage: "checkmark.circle.fill"
            )
            .font(.headline)
            .foregroundStyle(.indigo)

            Text("The complete group result is ready.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            NavigationLink {
                dashboardDestination
            } label: {
                dashboardButton
            }
            .buttonStyle(.plain)
        }
    }

    private var dashboardButton: some View {
        HStack(spacing: 12) {

            Image(systemName: "chart.bar.fill")

            Text("View group decisions")

            Spacer()

            Image(systemName: "arrow.right")
        }
        .font(.headline)
        .foregroundStyle(.white)
        .padding(18)
        .frame(
            maxWidth: .infinity,
            minHeight: 58
        )
        .background(
            Color(
                red: 0.27,
                green: 0.24,
                blue: 0.57
            ),
            in: RoundedRectangle(cornerRadius: 18)
        )
    }

    private var dashboardDestination: some View {
        GroupDecisionDashboardView(
            trip: trip,
            viewModel: GroupDecisionDashboardViewModel(
                deck: viewModel.deck,
                swipes: viewModel.swipes,
                decisionPolicy: decisionPolicy
            )
        )
    }

    // MARK: - Activity Card

    private func activityCard(
        _ candidate: ActivityCandidate
    ) -> some View {

        VStack(alignment: .leading, spacing: 16) {

            Image(systemName: candidate.symbolName)
                .font(.system(size: 60))
                .foregroundStyle(.indigo)
                .frame(
                    maxWidth: .infinity,
                    minHeight: 130
                )
                .accessibilityHidden(true)

            Text(candidate.city.uppercased())
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            Text(candidate.title)
                .font(.title2.bold())

            Text(candidate.activityDescription)

            Label(
                candidate.category.title,
                systemImage: candidate.category.symbolName
            )

            HStack {

                Text(
                    candidate.estimatedCostPerTraveller
                        .formatted(
                            .currency(
                                code: candidate.currencyCode
                            )
                            .precision(
                                .fractionLength(0)
                            )
                        )
                    + " pp"
                )

                Spacer()

                Label(
                    "\(candidate.suggestedDurationMinutes) min",
                    systemImage: "clock"
                )
            }
            .font(.subheadline)
        }
        .padding(20)
        .background(
            .indigo.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .overlay(alignment: .topTrailing) {

            if abs(dragOffset.width) > 30 {
                Text(
                    dragOffset.width > 0
                    ? "YES"
                    : "NO"
                )
                .font(.title.bold())
                .foregroundStyle(
                    dragOffset.width > 0
                    ? .indigo
                    : .red
                )
                .padding()
            }
        }
    }

    // MARK: - Helper Values

    private var currentTravellerName: String {
        viewModel.currentMember?.displayName
        ?? "Traveller"
    }

    private var yesVoteCount: Int {
        viewModel.memberSwipes.filter {
            $0.choice == .yes
        }.count
    }

    private var noVoteCount: Int {
        viewModel.memberSwipes.filter {
            $0.choice == .no
        }.count
    }

    private var totalTravellerCount: Int {
        viewModel.deck.votingRound
            .eligibleMemberIDs.count
    }

    private var everyoneHasFinished: Bool {
        viewModel.completedTravellerCount
        == totalTravellerCount
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: {
                viewModel.errorMessage != nil
            },
            set: { isPresented in
                if !isPresented {
                    viewModel.errorMessage = nil
                }
            }
        )
    }
}
