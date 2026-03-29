# DHModels — Type Relationship Diagram

`DHModels` is the catalog layer. All types are value types
(`struct` or `enum`), `Codable`, `Sendable`, and Linux-safe.

```mermaid
classDiagram
    direction TB

    %% ── Adversary cluster ─────────────────────────────────────────────────
    class Adversary {
        +String id
        +String name
        +String source
        +Int tier
        +AdversaryType role
        +String flavorText
        +String? motivesAndTactics
        +Int difficulty
        +Int thresholdMajor
        +Int thresholdSevere
        +Int hp
        +Int stress
        +String attackModifier
        +String attackName
        +AttackRange attackRange
        +String damage
        +String? experience
        +[EncounterFeature] features
        +Bool isHomebrew
    }

    class AdversaryType {
        <<enumeration>>
        bruiser
        horde
        leader
        minion
        ranged
        skulk
        social
        solo
        standard
        support
    }

    class AttackRange {
        <<enumeration>>
        melee
        veryClose
        close
        far
        veryFar
    }

    class FeatureType {
        <<enumeration>>
        action
        reaction
        passive
        +inferred(from:) FeatureType$
    }

    class EncounterFeature {
        +String id
        +String name
        +String text
        +FeatureType kind
    }

    Adversary --> AdversaryType : role
    Adversary --> AttackRange : attackRange
    Adversary "1" *-- "0..*" EncounterFeature : features
    EncounterFeature --> FeatureType : kind

    %% ── Environment cluster ───────────────────────────────────────────────
    class DaggerheartEnvironment {
        +String id
        +String name
        +String source
        +String flavorText
        +[EncounterFeature] features
        +Bool isHomebrew
    }

    DaggerheartEnvironment "1" *-- "0..*" EncounterFeature : features

    %% ── Conditions ────────────────────────────────────────────────────────
    class Condition {
        <<enumeration>>
        hidden
        restrained
        vulnerable
        custom(String)
        +String displayName
    }

    %% ── Encounter definition (prep / save layer) ──────────────────────────
    class EncounterDefinition {
        +UUID id
        +String name
        +[String] adversaryIDs
        +[String] environmentIDs
        +[PlayerConfig] playerConfigs
        +String gmNotes
        +Date createdAt
        +Date modifiedAt
    }

    class PlayerConfig {
        +UUID id
        +String name
        +Int maxHP
        +Int maxStress
        +Int evasion
        +Int thresholdMajor
        +Int thresholdSevere
        +Int armorSlots
    }

    EncounterDefinition "1" *-- "0..*" PlayerConfig : playerConfigs

    %% ── Difficulty budget (static utility) ───────────────────────────────
    class DifficultyBudget {
        <<utility>>
        +cost(for: AdversaryType) Int$
        +baseBudget(playerCount:) Int$
        +totalCost(for: [AdversaryType]) Int$
        +rating(adversaryTypes:playerCount:budgetAdjustment:) Rating$
        +suggestedAdjustments(adversaryTypes:) [Adjustment]$
    }

    class DifficultyBudget_Rating {
        +Int cost
        +Int budget
        +Int remaining
    }

    class DifficultyBudget_Adjustment {
        <<enumeration>>
        easierFight
        multipleSolos
        boostedDamage
        lowerTierAdversary
        noBigThreats
        harderFight
        +Int pointValue
    }

    DifficultyBudget ..> AdversaryType : uses
    DifficultyBudget ..> DifficultyBudget_Rating : returns
    DifficultyBudget ..> DifficultyBudget_Adjustment : returns

    %% ── Content pack types ────────────────────────────────────────────────
    class DHPackContent {
        +[Adversary] adversaries
        +[DaggerheartEnvironment] environments
    }

    DHPackContent "1" *-- "0..*" Adversary : adversaries
    DHPackContent "1" *-- "0..*" DaggerheartEnvironment : environments

    class ContentSource {
        +UUID id
        +String? displayName
        +URL? url
        +Date addedAt
        +Date? lastFetchedAt
        +String? etag
        +Bool isThrottled(at:)
        +TimeInterval nextAllowedFetch(after:)
    }

    class ContentFingerprint {
        +String sha256
    }

    class ContentStoreError {
        <<enumeration>>
        fileNotFound
        decodingFailed
        downloadFailed
        invalidURL
    }
```

## Key relationships

| Relationship | Description |
|---|---|
| `EncounterDefinition` stores IDs | Holds `adversaryIDs` and `environmentIDs` as `[String]` slugs — resolved into live slots at session creation via `Compendium` (DHKit) |
| `PlayerConfig` → `PlayerSlot` | `PlayerConfig` is the serialisable prep-time form; `PlayerSlot` (DHKit) is the live runtime form created from it |
| `DifficultyBudget` | Stateless utility — call its static methods with a list of `AdversaryType` to estimate encounter difficulty |
| `DHPackContent` | Decoded form of a `.dhpack` file; fed into `Compendium.replaceSourceContent(sourceID:adversaries:environments:)` |
