// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import PocketGraph

public struct BulletedListComponent: Codable, Equatable, Hashable {
    public let rows: [Row]

    public struct Row: Codable, Equatable, Hashable {
        public let content: Markdown
        public let level: UInt
    }
}

extension BulletedListComponent {
    init(_ marticle: MarticleBulletedListParts) {
        self.init(rows: marticle.rows.map(BulletedListComponent.Row.init))
    }
}

extension BulletedListComponent.Row {
    init(_ marticle: MarticleBulletedListParts.Row) {
        self.init(
            content: marticle.content,
            level: UInt(marticle.level)
        )
    }
}
