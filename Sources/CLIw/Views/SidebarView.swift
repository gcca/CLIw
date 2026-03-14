import SwiftUI

struct SidebarView: View {
    @Binding var selection: SnippetEntry?
    let entries: [SnippetEntry]

    var body: some View {
        List(entries, selection: $selection) { entry in
            Label(entry.displayName, systemImage: "terminal")
                .tag(entry)
        }
        .listStyle(.sidebar)
        .navigationTitle("CLIw")
    }
}
