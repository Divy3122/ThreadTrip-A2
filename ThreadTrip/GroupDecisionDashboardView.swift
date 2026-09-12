//
//  GroupDecisionDashboardView.swift
//  ThreadTrip
//
//  Created by Divy Patel on 12/9/2026.
//

import SwiftUI

struct GroupDecisionDashboardView: View {

    @ObservedObject var viewModel: GroupDecisionDashboardViewModel

    @Environment(\.colorScheme) private var colorScheme

    private let coral = Color(
        red: 0.88,
        green: 0.25,
        blue: 0.22
    )

    private let indigo = Color(
        red: 0.27,
        green: 0.24,
        blue: 0.57
    )

    private var cardColor: Color {
        Color(uiColor: .secondarySystemGroupedBackground)
    }

    private var canvas: Color {
        colorScheme == .dark
        ? Color(uiColor: .systemGroupedBackground)
        : Color(
            red: 0.97,
            green: 0.96,
            blue: 0.94
        )
    }

    var body: some View {
        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 20
            ) {

                header

                if let errorMessage = viewModel.errorMessage {

                    errorCard(errorMessage)

                } else {

                    summaryCard

                    decisionRuleCard

                    activityResults

                    nextStepCard
                }
            }
            .padding(20)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(
            canvas.ignoresSafeArea()
        )
        .navigationTitle("Group decisions")
        .navigationBarTitleDisplayMode(.inline)
        .tint(coral)
    }

    // MARK: - Header

    private var header: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            HStack {

                Text("THE GROUP HAS SPOKEN")
                    .font(.caption2.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(coral)

                Spacer()

                Text("3 of 4")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        coral.opacity(0.10),
                        in: Capsule()
                    )
            }

            Text("See what made the cut.")
                .font(.title2.bold())

            Text(
                "Every activity from your shared deck, with the whole group's votes."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        VStack(
            alignment: .leading,
            spacing: 22
        ) {

            VStack(
                alignment: .leading,
                spacing: 7
            ) {

                Text("YOUR GROUP RESULT")
                    .font(.caption2.bold())
                    .tracking(1.2)

                Text(
                    "\(viewModel.acceptedActivityCount) activities made the cut"
                )
                .font(.title.bold())

                Text(
                    "\(viewModel.travellerCount) travellers · \(viewModel.totalActivityCount) shared activities"
                )
                .font(.subheadline)
                .foregroundStyle(
                    .white.opacity(0.85)
                )
            }

            Rectangle()
                .fill(
                    .white.opacity(0.2)
                )
                .frame(height: 1)

            HStack(spacing: 30) {

                resultMetric(
                    value:
                        "\(viewModel.acceptedActivityCount)",
                    caption: "Made the cut",
                    symbol:
                        "checkmark.circle.fill"
                )

                resultMetric(
                    value:
                        "\(viewModel.rejectedActivityCount)",
                    caption: "Not selected",
                    symbol:
                        "xmark.circle.fill"
                )
            }
        }
        .foregroundStyle(.white)
        .padding(24)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            LinearGradient(
                colors: [
                    indigo,
                    Color(
                        red: 0.49,
                        green: 0.28,
                        blue: 0.53
                    )
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(
                cornerRadius: 26
            )
        )
        .shadow(
            color: indigo.opacity(0.20),
            radius: 16,
            y: 8
        )
    }

    private func resultMetric(
        value: String,
        caption: String,
        symbol: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 5
        ) {

            Label(
                value,
                systemImage: symbol
            )
            .font(.headline)

            Text(caption)
                .font(.caption)
                .foregroundStyle(
                    .white.opacity(0.85)
                )
        }
    }

    // MARK: - Decision Rule

    private var decisionRuleCard: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            HStack {

                Label(
                    "Decision rule",
                    systemImage:
                        "person.3.sequence.fill"
                )
                .font(.headline)

                Spacer()

                Text(
                    viewModel
                        .decisionPolicy
                        .title
                )
                .font(.caption.bold())
                .foregroundStyle(indigo)
                .padding(
                    .horizontal,
                    10
                )
                .padding(
                    .vertical,
                    6
                )
                .background(
                    indigo.opacity(0.10),
                    in: Capsule()
                )
            }

            Text(
                viewModel
                    .decisionPolicy
                    .explanation
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(
            cardColor,
            in: RoundedRectangle(
                cornerRadius: 18
            )
        )
    }

    // MARK: - Activity Results

    private var activityResults: some View {
        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text("EVERY ACTIVITY")
                .font(.caption2.bold())
                .tracking(0.8)
                .foregroundStyle(.secondary)

            ForEach(
                viewModel.decisions
            ) { decision in

                activityResultCard(
                    decision
                )
            }
        }
    }

    private func activityResultCard(
        _ decision: GroupActivityDecision
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            HStack(
                alignment: .top
            ) {

                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {

                    Text(
                        decision
                            .activity
                            .city
                            .uppercased()
                    )
                    .font(.caption2.bold())
                    .tracking(0.8)
                    .foregroundStyle(
                        .secondary
                    )

                    Text(
                        decision
                            .activity
                            .title
                    )
                    .font(.title3.bold())
                }

                Spacer(
                    minLength: 12
                )

                statusPill(
                    isAccepted:
                        decision
                            .isAccepted
                )
            }

            Label(
                decision
                    .activity
                    .category
                    .title,
                systemImage:
                    decision
                        .activity
                        .category
                        .symbolName
            )
            .font(.subheadline)
            .foregroundStyle(
                .secondary
            )

            ProgressView(
                value:
                    decision
                        .yesSupportFraction
            )
            .tint(
                decision.isAccepted
                ? indigo
                : coral
            )

            HStack {

                Label(
                    "\(decision.yesVoteCount) Yes",
                    systemImage:
                        "hand.thumbsup.fill"
                )
                .foregroundStyle(
                    indigo
                )

                Spacer()

                Label(
                    "\(decision.noVoteCount) No",
                    systemImage:
                        "hand.thumbsdown.fill"
                )
                .foregroundStyle(
                    coral
                )
            }
            .font(
                .subheadline.weight(
                    .semibold
                )
            )

            HStack {

                Text(
                    "\(supportPercentage(for: decision))% group support"
                )

                Spacer()

                Text(
                    "\(decision.eligibleTravellerCount) travellers"
                )
            }
            .font(.caption)
            .foregroundStyle(
                .secondary
            )
        }
        .padding(20)
        .background(
            cardColor,
            in: RoundedRectangle(
                cornerRadius: 22
            )
        )
    }

    private func statusPill(
        isAccepted: Bool
    ) -> some View {

        Text(
            isAccepted
            ? "MADE THE CUT"
            : "NOT SELECTED"
        )
        .font(.caption2.bold())
        .foregroundStyle(
            isAccepted
            ? indigo
            : coral
        )
        .padding(
            .horizontal,
            10
        )
        .padding(
            .vertical,
            7
        )
        .background(
            (
                isAccepted
                ? indigo
                : coral
            )
            .opacity(0.10),
            in: Capsule()
        )
    }

    private func supportPercentage(
        for decision:
            GroupActivityDecision
    ) -> Int {

        Int(
            (
                decision
                    .yesSupportFraction
                * 100
            )
            .rounded()
        )
    }

    // MARK: - Next Step

    private var nextStepCard: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Label(
                "Next: build the shared itinerary",
                systemImage:
                    "calendar.badge.plus"
            )
            .font(.headline)

            Text(
                "The activities your group accepted can now be organised across Tokyo, Kyoto and Osaka."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Text("SCREEN 4")
                .font(.caption2.bold())
                .tracking(0.8)
                .foregroundStyle(coral)
                .padding(.top, 4)
        }
        .padding(20)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            coral.opacity(0.08),
            in: RoundedRectangle(
                cornerRadius: 20
            )
        )
    }

    // MARK: - Error

    private func errorCard(
        _ message: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Label(
                "Group result isn't ready",
                systemImage:
                    "exclamationmark.triangle.fill"
            )
            .font(.headline)
            .foregroundStyle(coral)

            Text(message)
                .font(.subheadline)
        }
        .padding(20)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            cardColor,
            in: RoundedRectangle(
                cornerRadius: 20
            )
        )
    }
}
