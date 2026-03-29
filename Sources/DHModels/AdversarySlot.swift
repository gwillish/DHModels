//
//  AdversarySlot.swift
//  DHModels
//
//  A single adversary participant in a live encounter.
//

import Foundation

/// A single adversary participant in a live encounter.
///
/// Wraps a reference to a catalog ``Adversary`` with runtime state:
/// current HP, current Stress, defeat status, and an optional individual name
/// (useful when running multiple copies of the same adversary).
///
/// `maxHP` and `maxStress` are snapshotted from the catalog at slot-creation
/// time so that HP/stress clamping works correctly even if the source adversary
/// is later edited or removed from the ``Compendium`` (homebrew orphan safety).
///
/// All properties are immutable. Mutations are performed by ``EncounterSession``,
/// which replaces slots wholesale (copy-with-update pattern).
public struct AdversarySlot: CombatParticipant, Sendable, Equatable, Hashable {
  public let id: UUID
  /// The slug that identifies this adversary in the ``Compendium``.
  public let adversaryID: String
  /// Display name override (e.g. "Grimfang" for a named bandit leader).
  /// Falls back to the catalog name when `nil`.
  public let customName: String?

  // MARK: Stat Snapshot (from catalog at creation time)
  public let maxHP: Int
  public let maxStress: Int

  // MARK: Tracked Stats
  public let currentHP: Int
  public let currentStress: Int
  public let isDefeated: Bool
  public let conditions: Set<Condition>

  // MARK: - Init

  public init(
    id: UUID = UUID(),
    adversaryID: String,
    customName: String? = nil,
    maxHP: Int,
    maxStress: Int,
    currentHP: Int? = nil,
    currentStress: Int = 0,
    isDefeated: Bool = false,
    conditions: Set<Condition> = []
  ) {
    self.id = id
    self.adversaryID = adversaryID
    self.customName = customName
    self.maxHP = maxHP
    self.maxStress = maxStress
    self.currentHP = currentHP ?? maxHP
    self.currentStress = currentStress
    self.isDefeated = isDefeated
    self.conditions = conditions
  }
}
