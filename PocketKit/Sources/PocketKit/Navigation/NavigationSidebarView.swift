import SwiftUI
import Textile


struct NavigationSidebarView: View {

    @ObservedObject
    private var model: MainViewModel

    init(model: MainViewModel) {
        self.model = model
    }

    var body: some View {
        NavigationView {
            List(MainViewModel.AppSection.allCases) { section in
                Section {
                    Button(action: { model.selectedSection = section }) {
                        Text(section.navigationTitle).style(Style.header.sansSerif.h7)
                    }
                }.listRowBackground(sectionColor(section))
            }
            .navigationTitle("Pocket")
            .listStyle(.insetGrouped)
            .accessibilityIdentifier("navigation-sidebar")
        }
    }

    private func sectionColor(_ section: MainViewModel.AppSection) -> Color {
        return model.selectedSection == section ? Color(.ui.grey4).opacity(0.4) : Color(.ui.grey6).opacity(0.5)
    }
}