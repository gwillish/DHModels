# DHKit — Type Relationship Diagram

`DHKit` is the observable store layer. All top-level store classes
are `@Observable @MainActor`. Slot types are `nonisolated` value types so they
can be passed freely across isolation boundaries.

```mermaid
classDiagram
    direction TB

    %% ── Protocols ─────────────────────────────────────────────────────────
    class EncounterParticipant {
        <<protocol>>
        +UUID id
    }

    class CombatParticipant {
        <<protocol>>
        +Int currentHP
        +Int maxHP
        +Int currentStress
        +Int maxStress
        +Set~Condition~ conditions
    }

    EncounterParticipant <|-- CombatParticipant

    %% ── Slot value types ─────────────────────────────────────────────────
    class AdversarySlot {
        +UUID id
        +String adversaryID
        +String? customName
        +Int maxHP
        +Int maxStress
        +Int currentHP
        +Int currentStress
        +Bool isDefeated
        +Set~Condition~ conditions
        +init(from: Adversary, customName:)
        +applying(currentHP:currentStress:isDefeated:conditions:) AdversarySlot
    }

    class PlayerSlot {
        +UUID id
        +String name
        +Int maxHP
        +Int currentHP
        +Int maxStress
        +Int currentStress
        +Int evasion
        +Int thresholdMajor
        +Int thresholdSevere
        +Int armorSlots
        +Int currentArmorSlots
        +Set~Condition~ conditions
        +applying(currentHP:currentStress:currentArmorSlots:conditions:) PlayerSlot
    }

    class EnvironmentSlot {
        +UUID id
        +String environmentID
        +Bool isActive
        +applying(isActive:) EnvironmentSlot
    }

    CombatParticipant <|.. AdversarySlot
    CombatParticipant <|.. PlayerSlot
    EncounterParticipant <|.. EnvironmentSlot

    %% ── EncounterSession ─────────────────────────────────────────────────
    class EncounterSession {
        <<Observable, MainActor>>
        +UUID id
        +String name
        +[AdversarySlot] adversarySlots
        +[PlayerSlot] playerSlots
        +[EnvironmentSlot] environmentSlots
        +Int fearPool
        +Int hopePool
        +UUID? spotlightedSlotID
        +Int spotlightCount
        +String gmNotes
        +[AdversarySlot] activeAdversaries
        +Bool isOver
        +add(adversary: Adversary, customName:)
        +add(environment: DaggerheartEnvironment)
        +add(player: PlayerSlot)
        +removeAdversary(withID:)
        +removePlayer(withID:)
        +spotlight(id:)
        +yieldSpotlight()
        +applyDamage(_:to:)
        +applyHealing(_:to:)
        +applyStress(_:to:)
        +reduceStress(_:from:)
        +applyCondition(_:to:)
        +removeCondition(_:from:)
        +markArmorSlot(for:)
        +restoreArmorSlot(for:)
        +incrementFear(by:)
        +spendFear(by:)
        +incrementHope(by:)
        +spendHope(by:)
        +make(from: EncounterDefinition, using: Compendium) EncounterSession$
    }

    EncounterSession "1" *-- "0..*" AdversarySlot : adversarySlots
    EncounterSession "1" *-- "0..*" PlayerSlot : playerSlots
    EncounterSession "1" *-- "0..*" EnvironmentSlot : environmentSlots

    %% ── Compendium ───────────────────────────────────────────────────────
    class Compendium {
        <<Observable, MainActor>>
        +[String: Adversary] adversariesByID
        +[String: DaggerheartEnvironment] environmentsByID
        +[Adversary] adversaries
        +[DaggerheartEnvironment] environments
        +[Adversary] homebrewAdversaries
        +[DaggerheartEnvironment] homebrewEnvironments
        +Bool isLoading
        +CompendiumError? loadError
        +init(bundle: Bundle?)
        +load() async throws
        +adversary(id:) Adversary?
        +environment(id:) DaggerheartEnvironment?
        +adversaries(ofTier:) [Adversary]
        +adversaries(ofRole:) [Adversary]
        +adversaries(matching:) [Adversary]
        +addAdversary(_:)
        +removeHomebrewAdversary(id:)
        +addEnvironment(_:)
        +removeHomebrewEnvironment(id:)
        +replaceSRDContent(adversaries:environments:)
        +replaceSourceContent(sourceID:adversaries:environments:)
        +removeSourceContent(sourceID:)
    }

    class CompendiumError {
        <<enumeration>>
        fileNotFound(resourceName:)
        decodingFailed(resourceName:underlying:)
    }

    Compendium ..> CompendiumError : throws

    %% ── EncounterStore ───────────────────────────────────────────────────
    class EncounterStore {
        <<Observable, MainActor>>
        +[EncounterDefinition] definitions
        +URL directory
        +Bool isLoading
        +Error? loadError
        +init(directory: URL)
        +defaultDirectory() URL$ async
        +localDirectory URL$
        +relocate(to:)
        +load() async
        +create(name:) async throws
        +save(_:) async throws
        +delete(id:) async throws
        +duplicate(id:) async throws
    }

    class EncounterStoreError {
        <<enumeration>>
        notFound(UUID)
        saveFailed(UUID, String)
        deleteFailed(UUID, String)
    }

    EncounterStore ..> EncounterStoreError : throws

    %% ── SessionRegistry ──────────────────────────────────────────────────
    class SessionRegistry {
        <<Observable, MainActor>>
        +[UUID: EncounterSession] sessions
        +init()
        +session(for:definition:compendium:) EncounterSession
        +clearSession(for:)
        +resetSession(for:definition:compendium:) EncounterSession
    }

    SessionRegistry "1" o-- "0..*" EncounterSession : sessions

    %% ── Cross-type dependencies ──────────────────────────────────────────
    EncounterSession ..> Compendium : make(from:using:)
    SessionRegistry ..> Compendium : session(for:definition:compendium:)
    SessionRegistry ..> EncounterSession : creates / owns
```

## Typical usage flow

```mermaid
sequenceDiagram
    participant App
    participant Compendium
    participant EncounterStore
    participant SessionRegistry
    participant EncounterSession

    App->>Compendium: init() + load()
    Note over Compendium: Decodes SRD JSON from bundle

    App->>EncounterStore: init(directory:) + load()
    Note over EncounterStore: Reads .encounter.json files from disk

    App->>EncounterStore: create(name:)
    EncounterStore-->>App: definitions updated

    App->>SessionRegistry: session(for:definition:compendium:)
    SessionRegistry->>EncounterSession: make(from:using:)
    Note over EncounterSession: Resolves adversary/environment IDs<br>via Compendium; builds slots

    App->>EncounterSession: add(player:) / spotlight(id:)
    App->>EncounterSession: applyDamage(_:to:) / applyCondition(_:to:)
    App->>EncounterStore: save(definition) when prep changes
```

## Key design points

| Concern | Approach |
|---|---|
| Default isolation | `@MainActor` on all `@Observable` classes; slots are `nonisolated` structs |
| Mutation pattern | Slots are immutable; `EncounterSession` replaces them wholesale via `applying(...)` |
| Catalog vs. runtime | `Compendium` holds static catalog data; `EncounterSession` holds live session state |
| Persistence | `EncounterStore` persists `EncounterDefinition` (prep); sessions are in-memory only |
| Session lifecycle | `SessionRegistry` holds sessions keyed by definition ID; `clearSession` / `resetSession` to restart |
| Homebrew priority | Compendium merges: homebrew → source packs → SRD (last writer wins on ID conflict) |
