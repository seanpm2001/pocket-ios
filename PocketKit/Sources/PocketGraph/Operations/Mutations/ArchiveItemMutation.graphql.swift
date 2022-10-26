// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class ArchiveItemMutation: GraphQLMutation {
  public static let operationName: String = "ArchiveItem"
  public static let document: DocumentType = .notPersisted(
    definition: .init(
      """
      mutation ArchiveItem($itemID: ID!) {
        updateSavedItemArchive(id: $itemID) {
          __typename
          id
        }
      }
      """
    ))

  public var itemID: ID

  public init(itemID: ID) {
    self.itemID = itemID
  }

  public var __variables: Variables? { ["itemID": itemID] }

  public struct Data: PocketGraph.SelectionSet {
    public let __data: DataDict
    public init(data: DataDict) { __data = data }

    public static var __parentType: ParentType { PocketGraph.Objects.Mutation }
    public static var __selections: [Selection] { [
      .field("updateSavedItemArchive", UpdateSavedItemArchive.self, arguments: ["id": .variable("itemID")]),
    ] }

    /// Archives a SavedItem
    public var updateSavedItemArchive: UpdateSavedItemArchive { __data["updateSavedItemArchive"] }

    /// UpdateSavedItemArchive
    ///
    /// Parent Type: `SavedItem`
    public struct UpdateSavedItemArchive: PocketGraph.SelectionSet {
      public let __data: DataDict
      public init(data: DataDict) { __data = data }

      public static var __parentType: ParentType { PocketGraph.Objects.SavedItem }
      public static var __selections: [Selection] { [
        .field("id", ID.self),
      ] }

      /// Surrogate primary key. This is usually generated by clients, but will be generated by the server if not passed through creation
      public var id: ID { __data["id"] }
    }
  }
}