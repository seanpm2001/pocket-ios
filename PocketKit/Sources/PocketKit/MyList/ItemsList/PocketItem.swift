// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import PocketGraph

struct PocketItem {
    private let item: ItemsListItem
    private let itemPresenter: ItemsListItemPresenter

    init(item: ItemsListItem) {
        self.item = item
        self.itemPresenter = ItemsListItemPresenter(item: item)
    }

    var id: String? {
        item.id
    }

    var isFavorite: Bool {
        item.isFavorite
    }

    var title: NSAttributedString {
        itemPresenter.attributedTitle
    }

    var detail: NSAttributedString {
        itemPresenter.attributedDetail
    }

    var tags: [NSAttributedString]? {
        itemPresenter.attributedTags
    }

    var tagCount: NSAttributedString? {
        itemPresenter.attributedTagCount
    }

    var thumbnailURL: URL? {
        itemPresenter.thumbnailURL
    }

    var remoteItemParts: SavedItemParts? {
        item.remoteItemParts
    }
}