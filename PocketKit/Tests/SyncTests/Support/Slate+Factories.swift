@testable import Sync


extension Slate {
    static func build(
        id: String = "slate-1",
        name: String = "A slate",
        description: String = "For use in tests",
        recommendations: [Slate.Recommendation] = []
    ) -> Slate {
        Slate(
            id: id,
            name: name,
            description: description,
            recommendations: recommendations
        )
    }
}

extension Slate.Recommendation {
    static func build(
        id: String? = "recommendation-1",
        item: Slate.Item = .build()
    ) -> Slate.Recommendation {
        return Slate.Recommendation(id: id, item: item)
    }
}

extension Slate.Item {
    static func build(id: String = "item-1") -> Slate.Item {
        return Slate.Item(
            id: id,
            givenURL: nil,
            resolvedURL: nil,
            title: nil,
            language: nil,
            topImageURL: nil,
            timeToRead: nil,
            particleJSON: nil,
            excerpt: nil,
            domain: nil,
            domainMetadata: nil
        )
    }
}