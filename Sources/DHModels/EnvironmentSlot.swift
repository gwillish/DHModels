//
//  EnvironmentSlot.swift
//  DHModels
//
//  An environment element active in the current encounter scene.
//

import Foundation

/// An environment element active in the current encounter scene.
///
/// Environments have no HP or Stress — they are tracked only for
/// their features and activation state.
///
/// All properties are immutable. Mutations are performed by ``EncounterSession``,
/// which replaces slots wholesale (copy-with-update pattern).
public struct EnvironmentSlot: EncounterParticipant, Sendable, Equatable, Hashable {
  public let id: UUID
  /// The slug identifying this environment in the ``Compendium``.
  public let environmentID: String
  /// Whether this environment element is currently active/visible to players.
  public let isActive: Bool

  public init(
    id: UUID = UUID(),
    environmentID: String,
    isActive: Bool = true
  ) {
    self.id = id
    self.environmentID = environmentID
    self.isActive = isActive
  }
}
