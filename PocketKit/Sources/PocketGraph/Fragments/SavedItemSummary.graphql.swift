// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public struct SavedItemSummary: PocketGraph.SelectionSet, Fragment {
  public static var fragmentDefinition: StaticString { """
    fragment SavedItemSummary on SavedItem {
      __typename
      url
      remoteID: id
      isArchived
      isFavorite
      _deletedAt
      _createdAt
      archivedAt
      tags {
        __typename
        name
      }
      item {
        __typename
        ...ItemSummary
      }
    }
    """ }

  public let __data: DataDict
  public init(_dataDict: DataDict) { __data = _dataDict }

  public static var __parentType: ApolloAPI.ParentType { PocketGraph.Objects.SavedItem }
  public static var __selections: [ApolloAPI.Selection] { [
    .field("__typename", String.self),
    .field("url", String.self),
    .field("id", alias: "remoteID", PocketGraph.ID.self),
    .field("isArchived", Bool.self),
    .field("isFavorite", Bool.self),
    .field("_deletedAt", Int?.self),
    .field("_createdAt", Int.self),
    .field("archivedAt", Int?.self),
    .field("tags", [Tag]?.self),
    .field("item", Item.self),
  ] }

  /// The url the user saved to their list
  public var url: String { __data["url"] }
  /// Surrogate primary key. This is usually generated by clients, but will be generated by the server if not passed through creation
  public var remoteID: PocketGraph.ID { __data["remoteID"] }
  /// Helper property to indicate if the SavedItem is archived
  public var isArchived: Bool { __data["isArchived"] }
  /// Helper property to indicate if the SavedItem is favorited
  public var isFavorite: Bool { __data["isFavorite"] }
  /// Unix timestamp of when the entity was deleted, 30 days after this date this entity will be HARD deleted from the database and no longer exist
  public var _deletedAt: Int? { __data["_deletedAt"] }
  /// Unix timestamp of when the entity was created
  public var _createdAt: Int { __data["_createdAt"] }
  /// Timestamp that the SavedItem became archied, null if not archived
  public var archivedAt: Int? { __data["archivedAt"] }
  /// The Tags associated with this SavedItem
  public var tags: [Tag]? { __data["tags"] }
  /// Link to the underlying Pocket Item for the URL
  public var item: Item { __data["item"] }

  public init(
    url: String,
    remoteID: PocketGraph.ID,
    isArchived: Bool,
    isFavorite: Bool,
    _deletedAt: Int? = nil,
    _createdAt: Int,
    archivedAt: Int? = nil,
    tags: [Tag]? = nil,
    item: Item
  ) {
    self.init(_dataDict: DataDict(data: [
      "__typename": PocketGraph.Objects.SavedItem.typename,
      "url": url,
      "remoteID": remoteID,
      "isArchived": isArchived,
      "isFavorite": isFavorite,
      "_deletedAt": _deletedAt,
      "_createdAt": _createdAt,
      "archivedAt": archivedAt,
      "tags": tags._fieldData,
      "item": item._fieldData,
      "__fulfilled": Set([
        ObjectIdentifier(Self.self)
      ])
    ]))
  }

  /// Tag
  ///
  /// Parent Type: `Tag`
  public struct Tag: PocketGraph.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: ApolloAPI.ParentType { PocketGraph.Objects.Tag }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("__typename", String.self),
      .field("name", String.self),
    ] }

    /// The actual tag string the user created for their list
    public var name: String { __data["name"] }

    public init(
      name: String
    ) {
      self.init(_dataDict: DataDict(data: [
        "__typename": PocketGraph.Objects.Tag.typename,
        "name": name,
        "__fulfilled": Set([
          ObjectIdentifier(Self.self)
        ])
      ]))
    }
  }

  /// Item
  ///
  /// Parent Type: `ItemResult`
  public struct Item: PocketGraph.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: ApolloAPI.ParentType { PocketGraph.Unions.ItemResult }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("__typename", String.self),
      .inlineFragment(AsItem.self),
    ] }

    public var asItem: AsItem? { _asInlineFragment() }

    public init(
      __typename: String
    ) {
      self.init(_dataDict: DataDict(data: [
        "__typename": __typename,
        "__fulfilled": Set([
          ObjectIdentifier(Self.self)
        ])
      ]))
    }

    /// Item.AsItem
    ///
    /// Parent Type: `Item`
    public struct AsItem: PocketGraph.InlineFragment {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public typealias RootEntityType = SavedItemSummary.Item
      public static var __parentType: ApolloAPI.ParentType { PocketGraph.Objects.Item }
      public static var __selections: [ApolloAPI.Selection] { [
        .fragment(ItemSummary.self),
      ] }

      /// The Item entity is owned by the Parser service.
      /// We only extend it in this service to make this service's schema valid.
      /// The key for this entity is the 'itemId'
      public var remoteID: String { __data["remoteID"] }
      /// key field to identify the Item entity in the Parser service
      public var givenUrl: PocketGraph.Url { __data["givenUrl"] }
      /// If the givenUrl redirects (once or many times), this is the final url. Otherwise, same as givenUrl
      public var resolvedUrl: PocketGraph.Url? { __data["resolvedUrl"] }
      /// The title as determined by the parser.
      public var title: String? { __data["title"] }
      /// The detected language of the article
      public var language: String? { __data["language"] }
      /// The page's / publisher's preferred thumbnail image
      @available(*, deprecated, message: "use the topImage object")
      public var topImageUrl: PocketGraph.Url? { __data["topImageUrl"] }
      /// How long it will take to read the article (TODO in what time unit? and by what calculation?)
      public var timeToRead: Int? { __data["timeToRead"] }
      /// The domain, such as 'getpocket.com' of the {.resolved_url}
      public var domain: String? { __data["domain"] }
      /// The date the article was published
      public var datePublished: PocketGraph.DateString? { __data["datePublished"] }
      /// true if the item is an article
      public var isArticle: Bool? { __data["isArticle"] }
      /// 0=no images, 1=contains images, 2=is an image
      public var hasImage: GraphQLEnum<PocketGraph.Imageness>? { __data["hasImage"] }
      /// 0=no videos, 1=contains video, 2=is a video
      public var hasVideo: GraphQLEnum<PocketGraph.Videoness>? { __data["hasVideo"] }
      /// Number of words in the article
      public var wordCount: Int? { __data["wordCount"] }
      /// List of Authors involved with this article
      public var authors: [ItemSummary.Author?]? { __data["authors"] }
      /// A snippet of text from the article
      public var excerpt: String? { __data["excerpt"] }
      /// Additional information about the item domain, when present, use this for displaying the domain name
      public var domainMetadata: DomainMetadata? { __data["domainMetadata"] }
      /// Array of images within an article
      public var images: [ItemSummary.Image?]? { __data["images"] }
      /// If the item has a syndicated counterpart the syndication information
      public var syndicatedArticle: ItemSummary.SyndicatedArticle? { __data["syndicatedArticle"] }

      public struct Fragments: FragmentContainer {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public var itemSummary: ItemSummary { _toFragment() }
      }

      public init(
        remoteID: String,
        givenUrl: PocketGraph.Url,
        resolvedUrl: PocketGraph.Url? = nil,
        title: String? = nil,
        language: String? = nil,
        topImageUrl: PocketGraph.Url? = nil,
        timeToRead: Int? = nil,
        domain: String? = nil,
        datePublished: PocketGraph.DateString? = nil,
        isArticle: Bool? = nil,
        hasImage: GraphQLEnum<PocketGraph.Imageness>? = nil,
        hasVideo: GraphQLEnum<PocketGraph.Videoness>? = nil,
        wordCount: Int? = nil,
        authors: [ItemSummary.Author?]? = nil,
        excerpt: String? = nil,
        domainMetadata: DomainMetadata? = nil,
        images: [ItemSummary.Image?]? = nil,
        syndicatedArticle: ItemSummary.SyndicatedArticle? = nil
      ) {
        self.init(_dataDict: DataDict(data: [
          "__typename": PocketGraph.Objects.Item.typename,
          "remoteID": remoteID,
          "givenUrl": givenUrl,
          "resolvedUrl": resolvedUrl,
          "title": title,
          "language": language,
          "topImageUrl": topImageUrl,
          "timeToRead": timeToRead,
          "domain": domain,
          "datePublished": datePublished,
          "isArticle": isArticle,
          "hasImage": hasImage,
          "hasVideo": hasVideo,
          "wordCount": wordCount,
          "authors": authors._fieldData,
          "excerpt": excerpt,
          "domainMetadata": domainMetadata._fieldData,
          "images": images._fieldData,
          "syndicatedArticle": syndicatedArticle._fieldData,
          "__fulfilled": Set([
            ObjectIdentifier(Self.self),
            ObjectIdentifier(SavedItemSummary.Item.self),
            ObjectIdentifier(ItemSummary.self)
          ])
        ]))
      }

      /// Item.AsItem.DomainMetadata
      ///
      /// Parent Type: `DomainMetadata`
      public struct DomainMetadata: PocketGraph.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: ApolloAPI.ParentType { PocketGraph.Objects.DomainMetadata }

        /// The name of the domain (e.g., The New York Times)
        public var name: String? { __data["name"] }
        /// Url for the logo image
        public var logo: PocketGraph.Url? { __data["logo"] }

        public struct Fragments: FragmentContainer {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public var domainMetadataParts: DomainMetadataParts { _toFragment() }
        }

        public init(
          name: String? = nil,
          logo: PocketGraph.Url? = nil
        ) {
          self.init(_dataDict: DataDict(data: [
            "__typename": PocketGraph.Objects.DomainMetadata.typename,
            "name": name,
            "logo": logo,
            "__fulfilled": Set([
              ObjectIdentifier(Self.self),
              ObjectIdentifier(DomainMetadataParts.self)
            ])
          ]))
        }
      }
    }
  }
}
