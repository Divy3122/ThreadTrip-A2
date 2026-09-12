import Combine
import Foundation

/// Holds the group's responses for one locked deck during this app session.
/// Switching travellers or leaving the voting screen must not discard votes.
@MainActor
final class GroupSwipeDeckViewModel: ObservableObject {
    @Published private(set) var swipes: [ActivitySwipe] = []
    @Published var selectedMemberID: UUID
    @Published var errorMessage: String?

    let deck: GeneratedGroupActivityDeck
    let members: [TripMember]
    private let recordActivitySwipe = RecordActivitySwipeUseCase()

    init(deck: GeneratedGroupActivityDeck, members: [TripMember]) {
        self.deck = deck
        self.members = members.filter { deck.votingRound.eligibleMemberIDs.contains($0.id) }
        self.selectedMemberID = deck.votingRound.eligibleMemberIDs.first ?? UUID()
    }

    var currentMember: TripMember? {
        members.first { $0.id == selectedMemberID }
    }

    var memberSwipes: [ActivitySwipe] {
        swipes.filter { $0.votingRoundID == deck.votingRound.id && $0.memberID == selectedMemberID }
    }

    var currentCandidate: ActivityCandidate? {
        let answered = Set(memberSwipes.map(\.activityCandidateID))
        return deck.candidates.first { !answered.contains($0.id) }
    }

    var completedTravellerCount: Int {
        deck.votingRound.eligibleMemberIDs.filter { memberID in
            let answered = Set(swipes.filter {
                $0.votingRoundID == deck.votingRound.id && $0.memberID == memberID
            }.map(\.activityCandidateID))
            return answered == Set(deck.votingRound.candidateIDs)
        }.count
    }

    func recordSwipe(_ choice: ActivitySwipeChoice) {
        guard let candidate = currentCandidate else { return }
        do {
            let swipe = try recordActivitySwipe.execute(
                choice: choice,
                candidateID: candidate.id,
                memberID: selectedMemberID,
                in: deck.votingRound,
                existingSwipes: swipes
            )
            swipes.append(swipe)
            errorMessage = nil
        } catch let error as RecordActivitySwipeError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Your activity response could not be saved. Keep this deck open and try again."
        }
    }
}
