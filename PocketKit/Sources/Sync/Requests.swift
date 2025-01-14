// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import CoreData

public enum Requests {
    public static func fetchSavedItems(limit: Int? = nil) -> NSFetchRequest<SavedItem> {
        let request = fetchAllSavedItems()
        request.predicate = Predicates.savedItems()
        if let limit = limit {
            request.fetchLimit = limit
        }
        return request
    }

    public static func fetchArchivedItems(filters: [NSPredicate] = []) -> NSFetchRequest<SavedItem> {
        let request: NSFetchRequest<SavedItem> = SavedItem.fetchRequest()
        request.predicate = Predicates.archivedItems(filters: filters)

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \SavedItem.archivedAt, ascending: false),
            NSSortDescriptor(key: "item.title", ascending: true)
        ]

        return request
    }

    public static func fetchAllSavedItems() -> NSFetchRequest<SavedItem> {
        let request: NSFetchRequest<SavedItem> = SavedItem.fetchRequest()

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \SavedItem.createdAt, ascending: false),
            NSSortDescriptor(key: "item.title", ascending: true)
        ]

        return request
    }

    public static func fetchSavedItem(byURL url: String) -> NSFetchRequest<SavedItem> {
        let request = SavedItem.fetchRequest()
        request.predicate = NSPredicate(format: "url = %@", url as CVarArg)
        request.fetchLimit = 1
        return request
    }

    public static func fetchSavedItems(bySearchTerm searchTerm: String, userPremium isPremium: Bool) -> NSFetchRequest<SavedItem> {
        let request = SavedItem.fetchRequest()
        let urlPredicate = NSPredicate(format: "url CONTAINS %@", searchTerm)
        let titlePredicate = NSPredicate(format: "item.title CONTAINS %@", searchTerm)
        let urlTitlePredicate = NSCompoundPredicate(type: .or, subpredicates: [urlPredicate, titlePredicate])
        let unarchivedPredicate = NSPredicate(format: "isArchived = false")
        var allPredicate = NSCompoundPredicate(type: .and, subpredicates: [urlTitlePredicate, unarchivedPredicate])
        if isPremium {
            let tagsPredicate = NSPredicate(format: "%@ IN tags.name", searchTerm)
            let premiumPredicate = NSCompoundPredicate(type: .or, subpredicates: [urlTitlePredicate, tagsPredicate])
            allPredicate = NSCompoundPredicate(type: .and, subpredicates: [premiumPredicate, unarchivedPredicate])
        }
        request.predicate = allPredicate
        return request
    }

    public static func fetchPersistentSyncTasks() -> NSFetchRequest<PersistentSyncTask> {
        let request = PersistentSyncTask.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PersistentSyncTask.createdAt, ascending: true)]

        return request
    }

    public static func fetchSavedItemUpdatedNotifications() -> NSFetchRequest<SavedItemUpdatedNotification> {
        return SavedItemUpdatedNotification.fetchRequest()
    }

    public static func fetchUnresolvedSavedItems() -> NSFetchRequest<UnresolvedSavedItem> {
        UnresolvedSavedItem.fetchRequest()
    }

    public static func fetchSlateLineups() -> NSFetchRequest<SlateLineup> {
        SlateLineup.fetchRequest()
    }

    public static func fetchSlateLineup(byID id: String) -> NSFetchRequest<SlateLineup> {
        let request = Self.fetchSlateLineups()
        request.predicate = NSPredicate(format: "remoteID = %@", id)
        request.fetchLimit = 1
        return request
    }

    public static func fetchSlates() -> NSFetchRequest<Slate> {
        Slate.fetchRequest()
    }

    public static func fetchRecomendations(by lineupIdentifier: String) -> RichFetchRequest<Recommendation> {
        let request = RichFetchRequest<Recommendation>(entityName: "Recommendation")
        // We only search for valid recommendations without specifying a lineup, since the lineup will be only 1 (from unified home)
        request.predicate = NSPredicate(format: "item != NULL")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Recommendation.slate?.sortIndex, ascending: true),
            NSSortDescriptor(keyPath: \Recommendation.sortIndex, ascending: true),
        ]
        request.relationshipKeyPathsForRefreshing = [
            #keyPath(Recommendation.slate.sortIndex),
            // Reload the cell when the image finishes downloading. Kingfisher has a bug where the cell is not always reloaded with the image.
            #keyPath(Recommendation.image.isDownloaded),
            #keyPath(Recommendation.item.title),
            #keyPath(Recommendation.item.savedItem.archivedAt),
            #keyPath(Recommendation.item.savedItem.isFavorite),
            #keyPath(Recommendation.item.savedItem.createdAt),
        ]
        return request
    }

    public static func fetchSlate(byID id: String) -> NSFetchRequest<Slate> {
        let request = Self.fetchSlates()
        request.predicate = NSPredicate(format: "remoteID = %@", id)
        request.fetchLimit = 1
        return request
    }

    public static func fetchRecommendations() -> NSFetchRequest<Recommendation> {
        Recommendation.fetchRequest()
    }

    public static func fetchItems() -> NSFetchRequest<Item> {
        Item.fetchRequest()
    }

    public static func fetchSyndicatedArticles() -> NSFetchRequest<SyndicatedArticle> {
        SyndicatedArticle.fetchRequest()
    }

    public static func fetchSyndicatedArticle(byItemId id: String) -> NSFetchRequest<SyndicatedArticle> {
        let request = self.fetchSyndicatedArticles()
        request.predicate = NSPredicate(format: "itemID = %@", id)
        request.fetchLimit = 1
        return request
    }

    public static func fetchCollection(by slug: String) -> NSFetchRequest<Collection> {
        let request = Collection.fetchRequest()
        request.predicate = NSPredicate(format: "slug = %@", slug)
        request.fetchLimit = 1
        return request
    }

    public static func fetchCollectionAuthor(by name: String) -> NSFetchRequest<CollectionAuthor> {
        let request = CollectionAuthor.fetchRequest()
        request.predicate = NSPredicate(format: "name = %@", name)
        request.fetchLimit = 1
        return request
    }

    public static func fetchCollectionAuthors(by slug: String) -> NSFetchRequest<CollectionAuthor> {
        let request = CollectionAuthor.fetchRequest()
        request.predicate = NSPredicate(format: "collection.slug = %@", slug)
        return request
    }

    public static func fetchCollectionStory(by url: String) -> NSFetchRequest<CollectionStory> {
        let request = CollectionStory.fetchRequest()
        request.predicate = NSPredicate(format: "url = %@", url)
        request.fetchLimit = 1
        return request
    }

    public static func fetchCollectionStories(by slug: String) -> RichFetchRequest<CollectionStory> {
        let request = RichFetchRequest<CollectionStory>(entityName: "CollectionStory")
        request.predicate = NSPredicate(format: "collection.slug = %@", slug)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CollectionStory.sortOrder, ascending: true)]

        request.relationshipKeyPathsForRefreshing = [
            #keyPath(CollectionStory.item.savedItem.archivedAt),
            #keyPath(CollectionStory.item.savedItem.isFavorite),
            #keyPath(CollectionStory.item.savedItem.createdAt),
        ]

        return request
    }

    public static func fetchTags() -> NSFetchRequest<Tag> {
        return Tag.fetchRequest()
    }

    public static func fetchSavedTags() -> NSFetchRequest<Tag> {
        let request = fetchTags()
        request.predicate = NSPredicate(format: "ANY savedItems.isArchived = false")
        return request
    }

    public static func fetchArchivedTags() -> NSFetchRequest<Tag> {
        let request = fetchTags()
        request.predicate = NSPredicate(format: "ANY savedItems.isArchived = true")
        return request
    }

    public static func fetchTag(byName name: String) -> NSFetchRequest<Tag> {
        let request = fetchTags()
        request.predicate = NSPredicate(format: "name = %@", name)
        request.fetchLimit = 1
        return request
    }

    public static func fetchTag(byID id: String) -> NSFetchRequest<Tag> {
        let request = fetchTags()
        request.predicate = NSPredicate(format: "remoteID = %@", id)
        request.fetchLimit = 1
        return request
    }

    public static func fetchTagsWithNoSavedItems() -> NSFetchRequest<Tag> {
        let request = fetchTags()
        request.predicate = NSPredicate(format: "savedItems.@count = 0")
        return request
    }

    public static func fetchTags(excluding tags: [String]) -> NSFetchRequest<Tag> {
        let request = fetchTags()
        request.predicate = NSPredicate(format: "NOT (self.name IN %@)", tags)
        return request
    }

    public static func filterTags(with input: String, excluding tags: [String]) -> NSFetchRequest<Tag> {
        let request = fetchTags()
        let filterPredicate = NSPredicate(format: "name BEGINSWITH %@", input)
        let excludePredicate = NSPredicate(format: "NOT (self.name IN %@)", tags)
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [filterPredicate, excludePredicate])
        return request
    }

    public static func fetchUnsavedItems() -> NSFetchRequest<Item> {
        let request = self.fetchItems()
        request.predicate = NSPredicate(format: "savedItem = nil")
        return request
    }

    public static func fetchUndownloadedImages() -> NSFetchRequest<Image> {
        return Image.fetchRequest()
    }

    public static func fetchSavedItem(for item: Item) -> NSFetchRequest<SavedItem> {
        let request = fetchAllSavedItems()
        request.predicate = Predicates.savedItems(filters: [NSPredicate(format: "item = %@", item)])

        return request
    }

    public static func fetchItem(byURL url: String) -> NSFetchRequest<Item> {
        let request = fetchItems()
        request.predicate = NSPredicate(format: "givenURL = %@", url)
        request.fetchLimit = 1
        return request
    }

    public static func fetchFeatureFlags() -> NSFetchRequest<FeatureFlag> {
        FeatureFlag.fetchRequest()
    }

    public static func fetchFeatureFlag(byName name: String) -> NSFetchRequest<FeatureFlag> {
        let request = fetchFeatureFlags()
        request.predicate = NSPredicate(format: "name = %@", name)
        request.fetchLimit = 1
        return request
    }
}

public enum Predicates {
    public static func savedItems(filters: [NSPredicate] = []) -> NSPredicate {
        let predicates = filters + [NSPredicate(format: "isArchived = false && deletedAt = nil")]
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    public static func archivedItems(filters: [NSPredicate] = []) -> NSPredicate {
        let predicates = filters + [NSPredicate(format: "isArchived = true && deletedAt = nil")]
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    public static func allItems(filters: [NSPredicate] = []) -> NSPredicate {
        let predicates = filters + [NSPredicate(format: "deletedAt = nil")]
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}
