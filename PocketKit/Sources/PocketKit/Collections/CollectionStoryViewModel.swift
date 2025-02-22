// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import PocketGraph
import Textile
import Localization
import Sync
import Analytics

// Contains logic to present story data in RecommendationCell
struct CollectionStoryViewModel: Hashable {
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(collectionStory)
    }

    public static func == (lhs: CollectionStoryViewModel, rhs: CollectionStoryViewModel) -> Bool {
        return lhs.collectionStory == rhs.collectionStory
    }

    private(set) var collectionStory: CollectionStory
    private let source: Source?
    private let tracker: Tracker
    let overflowActions: [ItemAction]?

    init(collectionStory: CollectionStory, source: Source? = nil, tracker: Tracker, overflowActions: [ItemAction]?) {
        self.collectionStory = collectionStory
        self.source = source
        self.tracker = tracker
        self.overflowActions = overflowActions
    }
}

extension CollectionStoryViewModel: RecommendationCellViewModel {
    var attributedCollection: NSAttributedString? {
        guard collectionStory.item?.isCollection == true else { return nil }
        return NSAttributedString(string: Localization.Constants.collection, style: .recommendation.collection)
    }

    var attributedTitle: NSAttributedString {
        NSAttributedString(string: title ?? "", style: .recommendation.title)
    }

    var attributedDomain: NSAttributedString {
        let detailString = NSMutableAttributedString(string: domain ?? "", style: .recommendation.domain)
        return collectionStory.item?.isSyndicated == true ? detailString.addSyndicatedIndicator(with: .recommendation.domain) : detailString
    }

    var attributedExcerpt: NSAttributedString? {
        guard let str = NSAttributedString.styled(
                markdown: excerpt,
                styler: NSMutableAttributedString.collectionStyler(bodyStyle: .recommendation.excerpt)
              )
        else {
            return nil
        }
        let mutable = NSMutableAttributedString(attributedString: str)
        // Down seems to be replacing double newline characters with paragraph separators, so we are reversing that here
        // https://github.com/johnxnguyen/Down/issues/269
        mutable.mutableString.replaceOccurrences(of: "\u{2029}", with: "\n\n", range: NSRange(location: 0, length: mutable.string.count))
        return mutable
     }

    var attributedTimeToRead: NSAttributedString {
        NSAttributedString(string: timeToRead ?? "", style: .recommendation.timeToRead)
    }

    var title: String? {
        collectionStory.title
    }

    var imageURL: URL? {
        guard let imageURL = collectionStory.imageUrl else { return nil }
        return URL(string: imageURL)
    }

    var saveButtonMode: RecommendationSaveButton.Mode {
        collectionStory.isSaved ? .saved : .save
    }

    var excerpt: Markdown {
        collectionStory.excerpt
    }

    var domain: String? {
        collectionStory.publisher
    }

    var timeToRead: String? {
        guard let timeToRead = collectionStory.item?.timeToRead,
              Int(truncating: timeToRead) > 0 else {
            return nil
        }

        return Localization.Home.Recommendation.readTime(timeToRead)
    }

    var primaryAction: ItemAction? {
        .recommendationPrimary { _ in
            if !self.collectionStory.isSaved {
                trackStorySave()
                self.source?.save(collectionStory: self.collectionStory)
            } else {
                trackStoryUnSave()
                self.source?.archive(collectionStory: self.collectionStory)
            }
        }
    }
}

// MARK: - Analytics
private extension CollectionStoryViewModel {
    /// track user saving a story
    func trackStorySave() {
        tracker.track(event: Events.Collection.storySaveClicked(url: collectionStory.url))
    }

    /// track user unsaving a story
    func trackStoryUnSave() {
        tracker.track(event: Events.Collection.storyUnSaveClicked(url: collectionStory.url))
    }
}
