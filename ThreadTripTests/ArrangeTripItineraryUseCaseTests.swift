//
//  ArrangeTripItineraryUseCaseTests.swift
//  ThreadTrip
//
//  Created by Divy Patel on 12/9/2026.
//

import Foundation
import Testing
@testable import ThreadTrip

struct ArrangeTripItineraryUseCaseTests {

    @Test
    func itinerary_schedulesAcceptedActivity() throws {
        let trip = JapanTripSample.japanTrip
        let activity = makeActivity(
            title: "Tokyo Food Tour",
            durationMinutes: 90
        )

        let scheduled = try ArrangeTripItineraryUseCase().schedule(
            activity: activity,
            acceptedActivityIDs: Set([activity.id]),
            date: trip.startDate,
            startMinutes: 9 * 60,
            trip: trip,
            existingActivities: []
        )

        #expect(scheduled.activity.id == activity.id)
        #expect(scheduled.startMinutes == 540)
        #expect(scheduled.durationMinutes == 90)

        #expect(
            Calendar.current.isDate(
                scheduled.date,
                inSameDayAs: trip.startDate
            )
        )
    }

    @Test
    func itinerary_rejectsActivityThatWasNotAccepted() {
        let trip = JapanTripSample.japanTrip
        let activity = makeActivity(
            title: "Rejected Activity"
        )

        #expect(
            throws: ArrangeTripItineraryError.activityWasNotAccepted
        ) {
            try ArrangeTripItineraryUseCase().schedule(
                activity: activity,
                acceptedActivityIDs: Set<UUID>(),
                date: trip.startDate,
                startMinutes: 9 * 60,
                trip: trip,
                existingActivities: []
            )
        }
    }

    @Test
    func itinerary_rejectsOverlappingActivities() throws {
        let trip = JapanTripSample.japanTrip

        let firstActivity = makeActivity(
            title: "Tokyo Food Tour",
            durationMinutes: 90
        )

        let secondActivity = makeActivity(
            title: "Tokyo Museum",
            durationMinutes: 60
        )

        let acceptedIDs = Set([
            firstActivity.id,
            secondActivity.id
        ])

        let useCase = ArrangeTripItineraryUseCase()

        let firstScheduled = try useCase.schedule(
            activity: firstActivity,
            acceptedActivityIDs: acceptedIDs,
            date: trip.startDate,
            startMinutes: 9 * 60,
            trip: trip,
            existingActivities: []
        )

        #expect(
            throws: ArrangeTripItineraryError.overlappingActivity
        ) {
            try useCase.schedule(
                activity: secondActivity,
                acceptedActivityIDs: acceptedIDs,
                date: trip.startDate,
                startMinutes: 9 * 60 + 30,
                trip: trip,
                existingActivities: [firstScheduled]
            )
        }
    }

    @Test
    func itinerary_rejectsInvalidTimeBlock() {
        let trip = JapanTripSample.japanTrip
        let activity = makeActivity(
            title: "Tokyo Activity"
        )

        #expect(
            throws: ArrangeTripItineraryError.invalidTimeBlock
        ) {
            try ArrangeTripItineraryUseCase().schedule(
                activity: activity,
                acceptedActivityIDs: Set([activity.id]),
                date: trip.startDate,
                startMinutes: 9 * 60 + 15,
                trip: trip,
                existingActivities: []
            )
        }
    }

    private func makeActivity(
        title: String,
        durationMinutes: Int = 60
    ) -> ActivityCandidate {
        ActivityCandidate(
            id: UUID(),
            title: title,
            activityDescription: "Accepted group activity",
            city: "Tokyo",
            category: .sightseeing,
            estimatedCostPerTraveller: 50,
            currencyCode: "AUD",
            suggestedDurationMinutes: durationMinutes,
            symbolName: "mappin"
        )
    }
}
