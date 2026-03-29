//
//  EnvironmentSlot.swift
//  DHKit
//
//  An environment element active in the current encounter scene.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// An environment element active in the current encounter scene.
///
/// Environments have no HP or Stress — they are tracked only for
/// their features and activation state.
///
/// All properties are immutable. Mutations are performed by ``EncounterSession``,
/// which replaces slots wholesale (copy-with-update pattern).
nonisolated public struct EnvironmentSlot: EncounterParticipant, Sendable, Equatable, Hashable {
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

  /// Returns a copy of this slot with the specified mutable fields replaced.
  ///
  /// Omit any parameter to preserve the existing value.
  public func applying(isActive: Bool? = nil) -> EnvironmentSlot {
    EnvironmentSlot(
      id: id,
      environmentID: environmentID,
      isActive: isActive ?? self.isActive
    )
  }
}
