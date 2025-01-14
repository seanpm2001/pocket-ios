// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Sync
import UIKit

class UnsupportedComponentPresenter: ArticleComponentPresenter {
    private let readableViewModel: ReadableViewModel?

    init(readableViewModel: ReadableViewModel?) {
        self.readableViewModel = readableViewModel
    }

    func cell(for indexPath: IndexPath, in collectionView: UICollectionView) -> UICollectionViewCell {
        let cell: UnsupportedComponentCell = collectionView.dequeueCell(for: indexPath)
        cell.action = { [weak self] in
            self?.handleShowInWebReaderButtonTap()
        }
        readableViewModel?.trackUnsupportedContentViewed()
        return cell
    }

    func size(for availableWidth: CGFloat) -> CGSize {
        CGSize(width: availableWidth, height: 86)
    }

    func clearCache() {
        // no op
    }

    private func handleShowInWebReaderButtonTap() {
        readableViewModel?.showWebReader()
        readableViewModel?.trackUnsupportedContentButtonTapped()
    }
}
