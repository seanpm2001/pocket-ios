import Foundation
import Sync

extension SharedWithYouHighlight {
    var bestImageURL: URL? {
        guard let topImageURL = item.syndicatedArticle?.imageURL ?? item.topImageURL ?? (item.images?.firstObject as? Image)?.source else {
            return nil
        }

        return imageCacheURL(for: topImageURL)
    }

    var bestDomain: String? {
        item.syndicatedArticle?.publisherName ?? item.domainMetadata?.name ?? item.domain ?? item.bestURL.host
    }

    var bestTitle: String? {
        item.syndicatedArticle?.title ?? item.title
    }

    var bestExcerpt: String? {
        item.syndicatedArticle?.excerpt ?? item.excerpt
    }
}