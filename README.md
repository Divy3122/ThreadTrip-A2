# ThreadTrip — Assignment 2

ThreadTrip helps a group of friends turn scattered Instagram and TikTok travel ideas into a shared Japan trip plan across Tokyo, Kyoto and Osaka. The prototype uses a bundled activity catalogue instead of a social-media API.

This is a simplified rebuild of the original ThreadTrip prototype. The project is being developed screen by screen so the Git history shows the progression from trip setup, to voting, to group decisions, and finally itinerary planning.

## Current progress

| Screen | What it does | Status |
| --- | --- | --- |
| 1. Trip Overview | Set group interests, activity budget and decision rule; generate a locked deck | Implemented |
| 2. Activity Voting | Each traveller votes Yes or No on the identical ordered deck | Implemented |
| 3. Group Decision Dashboard | Show every activity with complete Yes/No results and determine what made the cut | Implemented |
| 4. Shared Itinerary | Schedule accepted activities into the trip | Planned |

The current prototype stores trip and voting state in memory. The traveller selector allows the group voting flow to be demonstrated on one device without pretending to provide authentication or online synchronisation.

## Open and run

1. Clone the repository.
2. Check out `feature/03-group-decision-dashboard` to view the Screen 3 milestone.
3. Open `ThreadTrip.xcodeproj` in Xcode.
4. Select the ThreadTrip scheme and an iPhone simulator.
5. Use Command-R to run and Command-U to run tests.

There are no external package dependencies. The app reads `japan_activities.json` from its bundle.

## Screen 1 — Trip Overview

Screen 1 creates the shared context that controls the rest of the trip planning flow.

1. The overview displays the Japan trip dates, destinations, travellers and trip budget.
2. The group chooses shared travel interests.
3. A maximum activity cost per traveller is selected.
4. The group chooses an acceptance rule:
   - Majority
   - 75% Yes
   - Everyone
5. The user generates the shared activity deck.
6. Matching activities are loaded from the bundled JSON catalogue.
7. Duplicate activity IDs are rejected and suitable activities are placed into a consistent order.
8. A `TripVotingRound` locks the activity IDs, their order and the eligible travellers.
9. Once the deck is created, the group can continue to Activity Voting.

The locked round is important because every traveller must receive the same activity choices in the same order.

**Code path:**  
`TripOverviewView` → `TripOverviewViewModel` → `GenerateGroupActivityDeckUseCase` → `TravelActivityCatalogue` → `GeneratedGroupActivityDeck`

## Screen 2 — Activity Voting

Screen 2 lets each eligible traveller respond to the same locked activity deck.

1. The activity voting screen opens using the exact deck generated on Screen 1.
2. The local traveller selector changes which group member is currently voting.
3. Each activity displays its title, city, category, cost, duration and description.
4. A traveller can swipe right or tap Yes.
5. A traveller can swipe left or tap No.
6. A valid response advances to that traveller's next unanswered activity.
7. Switching travellers does not change the activity deck or its order.
8. Returning to a traveller resumes their remaining activities.
9. The screen tracks each traveller's Yes and No totals.
10. The group can only continue once every eligible traveller has completed the voting round.

Each `ActivitySwipe` records the voting round, activity, traveller and Yes/No choice.

The recording Use Case prevents duplicate responses, votes from ineligible travellers, responses for activities outside the locked deck and responses after a round has been finalised.

**Code path:**  
`GroupSwipeDeckView` → `GroupSwipeDeckViewModel` → `RecordActivitySwipeUseCase` → `ActivitySwipe`

## Screen 3 — Group Decision Dashboard

Screen 3 turns the completed voting round into one group result.

The dashboard is not built from a new set of activities. It must use the exact locked deck created on Screen 1 and voted on during Screen 2.

1. Every eligible traveller must finish voting before the dashboard can be prepared.
2. Only responses belonging to the current voting round are counted.
3. Every activity from the locked deck is shown in the original order.
4. Each activity displays:
   - Yes vote count
   - No vote count
   - Number of eligible travellers
   - Group support percentage
   - Whether the activity made the cut
5. The dashboard displays the group's selected decision rule.
6. That decision rule determines whether each activity is accepted.
7. A summary shows how many activities were accepted and rejected.
8. Accepted activities become the activities available to the future shared itinerary.

The dashboard deliberately does not treat a missing response as a No vote. If voting is incomplete, the result is rejected instead of creating an inaccurate total.

The dashboard also rejects invalid group result data when:

- the locked activity deck has changed,
- a response belongs to a different traveller or activity,
- a traveller has more than one response for the same activity,
- or the required voting responses are incomplete.

Votes from a previous or different voting round are ignored rather than being mixed into the current result.

This keeps the decision dashboard tied to one specific shared voting round.

**Code path:**  
`GroupDecisionDashboardView` → `GroupDecisionDashboardViewModel` → `BuildGroupDecisionDashboardUseCase` → `GroupActivityDecision`

## Group decision rules

The group chooses its decision policy before the shared activity deck is generated.

The same policy is later applied by the Group Decision Dashboard.

### Majority

More than half of eligible travellers must vote Yes.

### 75% Yes

At least 75% of eligible travellers must vote Yes.

### Everyone

Every eligible traveller must vote Yes.

Keeping the decision rule inside the domain model means the dashboard does not contain its own separate interpretation of how an activity should be accepted.

## Domain-centred architecture

ThreadTrip separates interface code from travel-domain rules.

### Domain models

The main domain types represent concepts from collaborative trip planning rather than technical storage concepts.

Examples include:

- `GroupTrip`
- `TripMember`
- `TravelTasteProfile`
- `ActivityCandidate`
- `TripVotingRound`
- `ActivitySwipe`
- `GroupActivityDecision`
- `GroupDecisionPolicy`

### ViewModels

Each major screen owns a ViewModel that manages presentation state and calls the appropriate domain operation.

- `TripOverviewViewModel`
- `GroupSwipeDeckViewModel`
- `GroupDecisionDashboardViewModel`

### Use Cases

Business operations are separated from SwiftUI views.

- `GenerateGroupActivityDeckUseCase`
- `RecordActivitySwipeUseCase`
- `BuildGroupDecisionDashboardUseCase`

This keeps rules such as locked voting rounds, duplicate-response prevention and decision thresholds outside the interface layer.

## File structure

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
│   │
│   ├── GenerateGroupActivityDeckUseCase.swift
│   ├── RecordActivitySwipeUseCase.swift
│   ├── BuildGroupDecisionDashboardUseCase.swift
│   │
│   ├── TripOverviewViewModel.swift
│   ├── GroupSwipeDeckViewModel.swift
│   ├── GroupDecisionDashboardViewModel.swift
│   │
│   ├── TripOverviewView.swift
│   ├── GroupSwipeDeckView.swift
│   ├── GroupDecisionDashboardView.swift
│   │
│   ├── japan_activities.json
│   └── Assets.xcassets/
│
└── ThreadTripTests/
