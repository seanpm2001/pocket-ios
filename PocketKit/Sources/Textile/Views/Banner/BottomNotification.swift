import SwiftUI
import UIKit

public struct BannerModifier: ViewModifier {
    enum Constants {
        static let imageMaxWidth: CGFloat = 83
        static let spacing: CGFloat = 20
        static let imagePadding: EdgeInsets = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8)
        static let titleStyle: Style = .header.sansSerif.p2.with(weight: .bold).with(color: .ui.black)
        static let detailStyle: Style = .header.sansSerif.p4.with(color: .ui.black)
    }

    public struct BannerData {
        var image: ImageAsset
        var title: String
        var detail: String
        var action: BannerAction?

        public struct BannerAction {
            var text: String
            var action: () -> Void
            var style: PocketButtonStyle

            public init(text: String, style: PocketButtonStyle, action: @escaping () -> Void) {
                self.text = text
                self.action = action
                self.style = style
            }
        }

        public init(image: ImageAsset, title: String, detail: String, action: BannerAction? = nil) {
            self.image = image
            self.title = title
            self.detail = detail
            self.action = action
        }
    }

    let data: BannerData
    @Binding var show: Bool

    public func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            if show {
                VStack {
                    HStack(spacing: 8) {
                        Image(asset: data.image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: Constants.imageMaxWidth)
                            .accessibilityIdentifier("banner-image")
                            .padding(Constants.imagePadding)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(data.title)
                                .style(Constants.titleStyle)
                                .accessibilityIdentifier("banner-title")
                            Text(data.detail)
                                .style(Constants.detailStyle)
                                .accessibilityIdentifier("banner-detail")
                            if let action = data.action {
                                Button(action.text) {
                                   action.action()
                                }.buttonStyle(action.style)
                            }
                        }
                        Spacer()
                    }
                    .padding(13)
                    .background(Color(.branding.amber5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color(.branding.amber3), lineWidth: 1)
                    )
                }
                .accessibilityIdentifier("banner")
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: show)
                .onTapGesture {
                    withAnimation {
                        self.show = false
                    }
                }
                .gesture(DragGesture(minimumDistance: 20, coordinateSpace: .global)
                    .onEnded { value in
                        let verticalAmount = value.translation.height
                        if verticalAmount > 0 {
                            withAnimation {
                                self.show = false
                            }
                        }
                    })
            }
        }
    }
}

extension View {
    public func banner(data: BannerModifier.BannerData, show: Binding<Bool>) -> some View {
        self.modifier(BannerModifier(data: data, show: show))
    }
}

private extension Style {
    static let title: Self = .header.sansSerif.p2.with(weight: .semibold).with(color: .ui.black).with { paragraph in
        paragraph.with(lineSpacing: 4)
    }
    static let subtitle: Self = .header.sansSerif.p4.with(weight: .regular).with(color: .ui.black).with { paragraph in
        paragraph.with(lineSpacing: 4)
    }
}

struct BannerModifier_PreviewProvider: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            Text("Some Screen!")
            Spacer()
        }
        .banner(data: BannerModifier.BannerData(image: .warning, title: "Title", detail: "Detail Message"), show: .constant(true))
        .previewDisplayName("Warning - Light")
        .preferredColorScheme(.light)

        VStack {
            Spacer()
            Text("Some Screen!")
            Spacer()
        }
        .banner(data: BannerModifier.BannerData(image: .warning, title: "Title", detail: "Detail Message"), show: .constant(true))
        .previewDisplayName("Warning - Dark")
        .preferredColorScheme(.dark)

        VStack {
            Spacer()
            Text("Some Screen!")
            Spacer()
        }
        .banner(data: BannerModifier.BannerData(image: .warning, title: "Title", detail: "Detail Message", action: BannerModifier.BannerData.BannerAction(text: "Click!", style: PocketButtonStyle(.primary)) {
        }), show: .constant(true))
        .previewDisplayName("Action - Light")
        .preferredColorScheme(.light)

        VStack {
            Spacer()
            Text("Some Screen!")
            Spacer()
        }
        .banner(data: BannerModifier.BannerData(image: .accountDeleted, title: "You’ve deleted your Pocket account", detail: "What could we have done better?", action: BannerModifier.BannerData.BannerAction(text: "Quick survey", style: PocketButtonStyle(.primary)) {
        }), show: .constant(true))
        .previewDisplayName("Action - Dark")
        .preferredColorScheme(.dark)
    }
}