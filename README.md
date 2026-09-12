# ThreadTrip — Assignment 2

ThreadTrip helps six friends turn scattered Instagram and TikTok travel ideas into a shared Japan trip plan across Tokyo, Kyoto and Osaka. The prototype uses a bundled activity catalogue instead of a social-media API.

This is a simplified rebuild of the [original ThreadTrip prototype](https://github.com/Divy3122/ThreadTrip). The history records this rebuild, with separate stages for Screens 1 and 2. The original repository has not been deleted or rewritten.

## Current progress

| Screen | What it does | Status |
| --- | --- | --- |
| 1. Trip Overview | Set group interests, activity budget and decision rule; generate a locked deck | Implemented |
| 2. Activity Voting | Each traveller votes Yes or No on the identical ordered deck | Implemented |
| 3. Group Decision Dashboard | Show every activity and its complete Yes/No counts for one round | Next |
| 4. Shared Itinerary | Schedule accepted activities | Planned |

The current prototype stores votes in memory. Returning to the overview or changing travellers preserves them; closing the app starts a new session. The traveller selector demonstrates group voting on one device, without pretending to provide authentication or online synchronisation.

## Open and run

1. Clone this repository and check out `feature/activity-voting` to see both screens while the feature branches await integration.
2. Open `ThreadTrip.xcodeproj` in Xcode 16 or newer.
3. Select the **ThreadTrip** scheme and an iPhone simulator running iOS 17 or newer.
4. Use **Command-R** to run and **Command-U** to test.

There are no external package dependencies. The app reads `japan_activities.json` from its bundle.

## Screen 1 — complete walkthrough

1. Open ThreadTrip. The overview shows the Japan dates, three cities, trip budget and six travellers.
2. Choose the group's shared interests. These preferences apply to everyone.
3. Set the maximum activity cost per traveller, from AUD 25 to AUD 300.
4. Choose the acceptance rule: majority, 75% Yes, or everyone. This is stored for the future dashboard.
5. Tap **Generate shared activity deck**.
6. The app validates the trip, loads matching activities from JSON, removes duplicate IDs, sorts by city/title and takes up to twelve activities. At least six matches are required.
7. A `TripVotingRound` locks the candidate IDs, their order and eligible traveller IDs. The preferences become read-only.
8. Tap **Open activity voting** to continue to Screen 2.

If no interests are selected, the app explains what to change. If fewer than six activities match, increase the activity budget or select another interest and try again. A failed attempt does not replace an existing deck.

**Code path:** `TripOverviewView` → `TripOverviewViewModel` → `GenerateGroupActivityDeckUseCase` → `TravelActivityCatalogue` → `GeneratedGroupActivityDeck`.

## Screen 2 — complete walkthrough

1. The voting screen opens with the exact deck generated on Screen 1.
2. Check **Voting as** before responding. The selector is a local prototype control for trying each traveller's experience.
3. Review the activity's description, city, category, estimated cost and duration.
4. Swipe right or tap **Yes**. Swipe left or tap **No**. A short drag records nothing.
5. Each valid response advances to that traveller's next unanswered activity.
6. Switch travellers: they start with the same first activity and follow the same order. Return to the first traveller to resume where they stopped.
7. Return to the overview and reopen voting: the same ViewModel retains the group's responses.
8. After finishing the deck, see that traveller's Yes/No totals and how many travellers have finished. Repeat for all six travellers.

Every `ActivitySwipe` carries its voting-round ID, activity ID and member ID. The recording Use Case rejects duplicate responses, ineligible travellers, activities outside the deck and finalised rounds. It does not confuse a vote from an earlier round with a duplicate in the current one.

The future dashboard must count only votes belonging to this locked round, include every candidate, and distinguish missing votes from No votes. It has not been implemented in this milestone.

**Code path:** `GroupSwipeDeckView` → `GroupSwipeDeckViewModel` → `RecordActivitySwipeUseCase` → `ActivitySwipe`.

## Small, flat file structure

There are **11 app Swift files**, reduced from 20 in the original prototype. Related domain types share a file; business operations and screen responsibilities remain distinct.

```text
ThreadTrip-A2/
├── README.md
├── ASSIGNMENT_REQUIREMENTS.md
├── ThreadTrip.xcodeproj/
├── ThreadTrip/
│   ├── ThreadTripApp.swift
│   ├── GroupTrip.swift
│   ├── ActivityCandidate.swift
│   ├── TripVotingRound.swift
│   ├── TravelActivityCatalogue.swift
│   ├── GenerateGroupActivityDeckUseCase.swift
│   ├── RecordActivitySwipeUseCase.swift
│   ├── TripOverviewViewModel.swift
│   ├── TripOverviewView.swift
│   ├── GroupSwipeDeckViewModel.swift
│   ├── GroupSwipeDeckView.swift
│   ├── japan_activities.json
│   └── Assets.xcassets/
└── ThreadTripTests/
    ├── GenerateGroupActivityDeckUseCaseTests.swift
    └── RecordActivitySwipeUseCaseTests.swift
```

- `GroupTrip.swift` contains the trip, members, interests, preferences, decision policy and sample Japan trip.
- `TripVotingRound.swift` contains the locked round, generated deck and individual swipe types.
- `TravelActivityCatalogue.swift` contains the catalogue protocol and its local JSON implementation.
- Each screen has one View and one ViewModel. Small layout elements stay in their screen file.
- Each Use Case keeps its typed domain errors in the same file.

## Why this meets the architecture brief

Views display state and receive gestures. ViewModels hold shared screen state and call Use Cases. Use Cases protect business rules. Domain structs describe travel concepts and document their rules with DocC comments.

The catalogue protocol describes a real domain behaviour: finding suitable travel activities. It also lets tests substitute a small catalogue without reading JSON. Domain records use structs; ViewModels use classes because SwiftUI screens share mutable state. No inheritance hierarchy is needed for this problem.

**Still required for the full assignment:** the dashboard and itinerary, at least one additional Use Case with happy/failure tests, the one-page human-system architecture diagram and the 600–800 word reflective report. Two working screens alone do not complete the assignment.

## Development process on GitHub

Read the [commit history](https://github.com/Divy3122/ThreadTrip-A2/commits/feature/activity-voting) in chronological order:

1. `chore: start simplified ThreadTrip assignment project` — runnable app shell, Xcode configuration and brief.
2. `feat: build trip overview and lock a shared Japan activity deck` — Screen 1 and its domain operation.
3. `test: verify shared deck rules and locked trip preferences` — Screen 1 business-rule coverage.
4. `feat: add activity voting with shared round state for every traveller` — Screen 2 and retained group responses.
5. `test: cover traveller switching and voting round isolation` — Screen 2 business-rule coverage.
6. `docs: explain both screen workflows and simplified architecture` — this walkthrough and validation notes.

The screen branches are [feature/trip-overview](https://github.com/Divy3122/ThreadTrip-A2/tree/feature/trip-overview) and [feature/activity-voting](https://github.com/Divy3122/ThreadTrip-A2/tree/feature/activity-voting). Screen 2 is temporarily stacked on Screen 1 while merge approval is pending. Both trace back to `develop`; `main` retains the built app shell until a tested milestone is approved for integration. No merges or force-pushes have been made.

## Validation

Checked with Xcode 26.2 and the iPhone 17 Pro / iOS 26.2 simulator:

- Initial app shell: build passed.
- Screen 1: build passed; 10 Swift Testing tests passed.
- Screen 2: build passed; full suite covers 20 tests across both Use Cases and their ViewModels.
- Tests cover all four swipe errors, shared deck order for all travellers, traveller switching, round isolation, retained votes, locked preferences and catalogue/trip validation.

Manual UI interaction has **not** been verified by the agent because Computer Use permissions were unavailable. Use the two walkthroughs above to check drag gestures, navigation, text sizing and appearance in Xcode's simulator before merging.
