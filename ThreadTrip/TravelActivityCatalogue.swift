import Foundation

/// Supplies travel activities matching a group's destinations and taste profile.
///
/// A local JSON catalogue fulfils this behaviour for the MVP. A future remote
/// catalogue can conform without changing the deck-generation Use Case.
protocol TravelActivityCatalogue {
    func activityCandidates(
        for trip: GroupTrip,
        matching tasteProfile: TravelTasteProfile
    ) throws -> [ActivityCandidate]
}

enum LocalJSONTravelActivityCatalogueError: Error {
    case resourceMissing
    case unreadableData
    case decodingFailed
}

/// Reads the MVP Japan activity catalogue from the application bundle.
struct LocalJSONTravelActivityCatalogue: TravelActivityCatalogue {
    private let bundle: Bundle
    private let resourceName: String

    init(
        bundle: Bundle = .main,
        resourceName: String = "japan_activities"
    ) {
        self.bundle = bundle
        self.resourceName = resourceName
    }

    func activityCandidates(
        for trip: GroupTrip,
        matching tasteProfile: TravelTasteProfile
    ) throws -> [ActivityCandidate] {
        guard let url = bundle.url(
            forResource: resourceName,
            withExtension: "json"
        ) else {
            throw LocalJSONTravelActivityCatalogueError.resourceMissing
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw LocalJSONTravelActivityCatalogueError.unreadableData
        }

        let allCandidates: [ActivityCandidate]
        do {
            allCandidates = try JSONDecoder().decode(
                [ActivityCandidate].self,
                from: data
            )
        } catch {
            throw LocalJSONTravelActivityCatalogueError.decodingFailed
        }

        let selectedCities = Set(
            trip.destinationCities.map { $0.lowercased() }
        )

        return allCandidates.filter { candidate in
            selectedCities.contains(candidate.city.lowercased())
                && tasteProfile.interests.contains(candidate.category)
                && candidate.estimatedCostPerTraveller
                    <= tasteProfile.maximumActivityCostPerTraveller
        }
    }
}
