// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import Textile
import Sync


struct TextContentView: View {
    private let text: TextContent
    private let style: Style

    @EnvironmentObject
    private var articleState: ArticleViewState

    init(_ text: TextContent, style: Style) {
        self.text = text
        self.style = style
    }

    var attributedText: NSAttributedString {
        text.attributedString(baseStyle: style)
    }

    var tappedURL: Binding<URL?> {
        $articleState.url
    }

    var body: some View {
        AttributedStringView(
            content: attributedText,
            tappedURL: tappedURL
        )
    }
}