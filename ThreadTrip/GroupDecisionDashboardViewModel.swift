//
//  GroupDecisionDashboardViewModel.swift
//  ThreadTrip
//
//  Created by Divy Patel on 12/9/2026.
//

import Combine
import Foundation

@MainActor
final class GroupDecisionDashboardViewModel: ObservableObject {

    @Published private(set) var decisions: [GroupActivityDecision] = []
    @Published private(set) var errorMessage: String?

    let decisionPolicy: GroupDecisionPolicy

    init(
        deck: GeneratedGroupActivityDeck,
        swipes: [ActivitySwipe],
        decisionPolicy: GroupDecisionPolicy,
        buildDashboard: BuildGroupDecisionDashboardUseCase =
            BuildGroupDecisionDashboardUseCase()
    ) {
        self.decisionPolicy = decisionPolicy

        do {
            decisions = try buildDashboard.execute(
                deck: deck,
                swipes: swipes,
                decisionPolicy: decisionPolicy
            )

            errorMessage = nil

        } catch let error as BuildGroupDecisionDashboardError {

            errorMessage = error.localizedDescription

        } catch {

            errorMessage = """
            The group result could not be prepared. \
            Return to Activity Voting and check that everyone has finished.
            """
        }
    }

    var acceptedActivityCount: Int {
        decisions.filter(\.isAccepted).count
    }

    var rejectedActivityCount: Int {
        decisions.filter {
            !$0.isAccepted
        }.count
    }

    var totalActivityCount: Int {
        decisions.count
    }

    var totalYesVotes: Int {
        decisions.reduce(0) {
            $0 + $1.yesVoteCount
        }
    }

    var totalNoVotes: Int {
        decisions.reduce(0) {
            $0 + $1.noVoteCount
        }
    }

    var travellerCount: Int {
        decisions.first?.eligibleTravellerCount ?? 0
    }
}
