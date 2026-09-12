import SwiftUI

struct GroupSwipeDeckView: View {
    @ObservedObject var viewModel: GroupSwipeDeckViewModel
    @GestureState private var dragOffset: CGSize = .zero

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("2 OF 4 · ACTIVITY VOTING")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.indigo)
                Text("What would you enjoy?")
                    .font(.largeTitle.bold())

                Picker("Voting as", selection: $viewModel.selectedMemberID) {
                    ForEach(viewModel.members) { member in
                        Text(member.displayName).tag(member.id)
                    }
                }
                .pickerStyle(.menu)
                Text("Prototype: pass the phone or select a traveller to try their deck. Responses stay on this device until the app closes.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                ProgressView(value: Double(viewModel.memberSwipes.count), total: Double(viewModel.deck.candidates.count))
                Text("\(viewModel.memberSwipes.count) of \(viewModel.deck.candidates.count) answered · \(viewModel.currentMember?.displayName ?? "Traveller")")
                    .font(.subheadline)
                Label("Same activities. Same order. Your own Yes or No.", systemImage: "lock.fill")
                    .font(.footnote)
                    .foregroundStyle(.indigo)

                if let candidate = viewModel.currentCandidate {
                    activityCard(candidate)
                        .offset(x: dragOffset.width)
                        .rotationEffect(.degrees(Double(dragOffset.width / 25)))
                        .gesture(DragGesture().updating($dragOffset) { value, state, _ in
                            state = value.translation
                        }.onEnded { value in
                            if value.translation.width > 100 { viewModel.recordSwipe(.yes) }
                            if value.translation.width < -100 { viewModel.recordSwipe(.no) }
                        })
                        .id(candidate.id)

                    HStack(spacing: 16) {
                        Button { viewModel.recordSwipe(.no) } label: {
                            Label("No", systemImage: "xmark").frame(maxWidth: .infinity)
                        }
                        .tint(.red)
                        Button { viewModel.recordSwipe(.yes) } label: {
                            Label("Yes", systemImage: "heart.fill").frame(maxWidth: .infinity)
                        }
                        .tint(.indigo)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    Text("Swipe left for No, right for Yes, or use the buttons.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Your votes are saved", systemImage: "checkmark.circle.fill")
                            .font(.title2.bold())
                        Text("Yes: \(viewModel.memberSwipes.filter { $0.choice == .yes }.count) · No: \(viewModel.memberSwipes.filter { $0.choice == .no }.count)")
                        Text("Select another traveller above to continue the group's voting.")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.indigo.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                }

                Text("\(viewModel.completedTravellerCount) of \(viewModel.deck.votingRound.eligibleMemberIDs.count) travellers finished")
                    .font(.headline)
                if viewModel.completedTravellerCount == viewModel.deck.votingRound.eligibleMemberIDs.count {
                    Text("Everyone has voted. The Group Decision Dashboard is the next development milestone.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
        }
        .navigationTitle("Activity voting")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Could not save response", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Try responding to this activity again.")
        }
    }

    private func activityCard(_ candidate: ActivityCandidate) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: candidate.symbolName)
                .font(.system(size: 60))
                .foregroundStyle(.indigo)
                .frame(maxWidth: .infinity, minHeight: 130)
                .accessibilityHidden(true)
            Text(candidate.city.uppercased())
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(candidate.title).font(.title2.bold())
            Text(candidate.activityDescription)
            Label(candidate.category.title, systemImage: candidate.category.symbolName)
            HStack {
                Text(candidate.estimatedCostPerTraveller.formatted(.currency(code: candidate.currencyCode).precision(.fractionLength(0))) + " pp")
                Spacer()
                Label("\(candidate.suggestedDurationMinutes) min", systemImage: "clock")
            }
            .font(.subheadline)
        }
        .padding(20)
        .background(.indigo.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
        .overlay(alignment: .topTrailing) {
            if abs(dragOffset.width) > 30 {
                Text(dragOffset.width > 0 ? "YES" : "NO")
                    .font(.title.bold())
                    .foregroundStyle(dragOffset.width > 0 ? .indigo : .red)
                    .padding()
            }
        }
    }
}
