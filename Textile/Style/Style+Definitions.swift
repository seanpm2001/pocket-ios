// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

public extension FontDescriptor.Family {
    static let graphik: Self = "Graphik LCG"
    static let blanco: Self = "Blanco OSF"
    static let doyle: Self = "Doyle"
}

public extension FontDescriptor.Size {
    static let h1: Self = 48
    static let h2: Self = 40
    static let h3: Self = 33
    static let h4: Self = 28
    static let h5: Self = 23
    static let h6: Self = 19
    static let h7: Self = 16
    static let p1: Self = 23
    static let p2: Self = 19
    static let p3: Self = 16
    static let p4: Self = 14
    static let body: Self = 19
}

public extension Style {
    static let header = Header()
    static let body = Body()

    struct Header {
        public let sansSerif = SansSerif()
        public let serif = Serif()
        public let display = Display()

        public struct SansSerif {
            public let h1 = Style(family: .graphik, size: .h1, weight: .semibold)
            public let h2 = Style(family: .graphik, size: .h2, weight: .semibold)
            public let h3 = Style(family: .graphik, size: .h3, weight: .semibold)
            public let h4 = Style(family: .graphik, size: .h4, weight: .semibold)
            public let h5 = Style(family: .graphik, size: .h5, weight: .semibold)
            public let h6 = Style(family: .graphik, size: .h6, weight: .semibold)
            public let h7 = Style(family: .graphik, size: .h7, weight: .semibold)
            public let p1 = Style(family: .graphik, size: .p1, weight: .regular)
            public let p2 = Style(family: .graphik, size: .p2, weight: .regular)
            public let p3 = Style(family: .graphik, size: .p3, weight: .regular)
            public let p4 = Style(family: .graphik, size: .p4, weight: .regular)
        }

        public struct Serif {
            public let h1 = Style(family: .blanco, size: .h1, weight: .bold)
            public let h2 = Style(family: .blanco, size: .h2, weight: .bold)
            public let h3 = Style(family: .blanco, size: .h3, weight: .bold)
            public let h4 = Style(family: .blanco, size: .h4, weight: .bold)
            public let h5 = Style(family: .blanco, size: .h5, weight: .bold)
            public let h6 = Style(family: .blanco, size: .h6, weight: .bold)
            public let p1 = Style(family: .blanco, size: .p1, weight: .regular)
            public let p2 = Style(family: .blanco, size: .p2, weight: .regular)
            public let p3 = Style(family: .blanco, size: .p3, weight: .regular)
            public let p4 = Style(family: .blanco, size: .p4, weight: .regular)
        }
    }

    struct Display {
        let medium = Medium()
        let regular = Regular()

        struct Medium {
            public let h1 = Style(family: .doyle, size: .h1, weight: .medium)
            public let h2 = Style(family: .doyle, size: .h2, weight: .medium)
            public let h3 = Style(family: .doyle, size: .h3, weight: .medium)
            public let h4 = Style(family: .doyle, size: .h4, weight: .medium)
            public let h5 = Style(family: .doyle, size: .h5, weight: .medium)
            public let h6 = Style(family: .doyle, size: .h6, weight: .medium)
        }

        struct Regular {
            public let h1 = Style(family: .doyle, size: .h1, weight: .regular)
            public let h2 = Style(family: .doyle, size: .h2, weight: .regular)
            public let h3 = Style(family: .doyle, size: .h3, weight: .regular)
            public let h4 = Style(family: .doyle, size: .h4, weight: .regular)
            public let h5 = Style(family: .doyle, size: .h5, weight: .regular)
            public let h6 = Style(family: .doyle, size: .h6, weight: .regular)
        }
    }

    struct Body {
        public let sansSerif = Style(family:  .graphik, size: .body, weight: .regular)
        public let serif = Style(family:  .blanco, size: .body, weight: .regular)
    }
}