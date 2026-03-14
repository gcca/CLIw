import SwiftUI

struct ContentView: View {
    @State private var store = ScriptStore()
    @State private var selection: SnippetEntry?

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection, entries: store.entries)
        } detail: {
            if let entry = selection, let snippet = store.snippet(for: entry) {
                DetailView(snippet: snippet)
                    .id(entry.id)
            } else {
                ContentUnavailableView(
                    "Select a Command",
                    systemImage: "terminal",
                    description: Text("Choose a snippet from the sidebar.")
                )
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}
