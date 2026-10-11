
import SwiftUI
import UIKit

struct ToolboxSnippet: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var content: String
    var category: String
    var createdAt: Date = Date()
}

struct ContentView: View {
    @State private var snippets: [ToolboxSnippet] = []
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var showingEditor = false
    @State private var editingSnippet: ToolboxSnippet? = nil

    private let categories = [
        "All", "Code", "Notes", "Commands", "Ideas", "Other"
    ]

    private let storageKey = "PocketToolbox.Snippets"

    private var filteredSnippets: [ToolboxSnippet] {
        snippets
            .filter { snippet in
                let matchesCategory =
                    selectedCategory == "All" ||
                    snippet.category == selectedCategory

                let matchesSearch =
                    searchText.isEmpty ||
                    snippet.title.localizedCaseInsensitiveContains(searchText) ||
                    snippet.content.localizedCaseInsensitiveContains(searchText) ||
                    snippet.category.localizedCaseInsensitiveContains(searchText)

                return matchesCategory && matchesSearch
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                header

                searchBar

                categoryPicker

                if filteredSnippets.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(filteredSnippets) { snippet in
                            snippetRow(snippet)
                                .listRowInsets(
                                    EdgeInsets(
                                        top: 8,
                                        leading: 16,
                                        bottom: 8,
                                        trailing: 16
                                    )
                                )
                                .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: deleteSnippets)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarHidden(true)
            .sheet(isPresented: $showingEditor) {
                SnippetEditorView(
                    snippet: editingSnippet,
                    onSave: { savedSnippet in
                        saveSnippet(savedSnippet)
                    }
                )
            }
            .onAppear {
                loadSnippets()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(Color.indigo)
                .cornerRadius(14)

            VStack(alignment: .leading, spacing: 3) {
                Text("Pocket Toolbox")
                    .font(.title2.bold())

                Text("\(snippets.count) saved snippet\(snippets.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                editingSnippet = nil
                showingEditor = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.indigo)
                    .cornerRadius(14)
            }
            .accessibilityLabel("Add snippet")
        }
        .padding(16)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search snippets...", text: $searchText)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(14)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Text(category)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 15)
                            .padding(.vertical, 9)
                            .foregroundColor(
                                selectedCategory == category
                                    ? .white
                                    : .primary
                            )
                            .background(
                                selectedCategory == category
                                    ? Color.indigo
                                    : Color(uiColor: .secondarySystemGroupedBackground)
                            )
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()

            Image(systemName: searchText.isEmpty ? "tray" : "magnifyingglass")
                .font(.system(size: 42))
                .foregroundColor(.secondary)

            Text(searchText.isEmpty ? "Nothing here yet" : "No results found")
                .font(.title3.bold())

            Text(
                searchText.isEmpty
                    ? "Save code, commands, notes, and ideas in one place."
                    : "Try another search or choose a different category."
            )
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)

            if searchText.isEmpty {
                Button {
                    editingSnippet = nil
                    showingEditor = true
                } label: {
                    Label("Create your first snippet", systemImage: "plus")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(Color.indigo)
                        .cornerRadius(14)
                }
                .padding(.top, 6)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func snippetRow(_ snippet: ToolboxSnippet) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(snippet.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(snippet.category)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.indigo)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Color.indigo.opacity(0.12))
                        .cornerRadius(8)
                }

                Spacer()

                Button {
                    UIPasteboard.general.string = snippet.content
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.indigo)
                        .frame(width: 38, height: 38)
                        .background(Color.indigo.opacity(0.10))
                        .cornerRadius(11)
                }
                .accessibilityLabel("Copy \(snippet.title)")
            }

            Text(snippet.content)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Text(snippet.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Button("Edit") {
                    editingSnippet = snippet
                    showingEditor = true
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(.indigo)
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .contentShape(Rectangle())
    }

    private func saveSnippet(_ snippet: ToolboxSnippet) {
        if let index = snippets.firstIndex(where: { $0.id == snippet.id }) {
            snippets[index] = snippet
        } else {
            snippets.append(snippet)
        }

        persistSnippets()
    }

    private func deleteSnippets(at offsets: IndexSet) {
        let idsToDelete = offsets.map { filteredSnippets[$0].id }
        snippets.removeAll { idsToDelete.contains($0.id) }
        persistSnippets()
    }

    private func loadSnippets() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return
        }

        do {
            snippets = try JSONDecoder().decode(
                [ToolboxSnippet].self,
                from: data
            )
        } catch {
            print("Could not load saved snippets: \(error)")
        }
    }

    private func persistSnippets() {
        do {
            let data = try JSONEncoder().encode(snippets)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Could not save snippets: \(error)")
        }
    }
}

struct SnippetEditorView: View {
    @Environment(\.presentationMode) private var presentationMode

    @State private var title: String
    @State private var content: String
    @State private var category: String

    private let existingID: UUID?
    private let existingDate: Date

    private let categories = [
        "Code", "Notes", "Commands", "Ideas", "Other"
    ]

    let onSave: (ToolboxSnippet) -> Void

    init(
        snippet: ToolboxSnippet?,
        onSave: @escaping (ToolboxSnippet) -> Void
    ) {
        self.existingID = snippet?.id
        self.existingDate = snippet?.createdAt ?? Date()
        self.onSave = onSave

        _title = State(initialValue: snippet?.title ?? "")
        _content = State(initialValue: snippet?.content ?? "")
        _category = State(initialValue: snippet?.category ?? "Code")
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("DETAILS")) {
                    TextField("Snippet title", text: $title)

                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { item in
                            Text(item).tag(item)
                        }
                    }
                }

                Section(header: Text("CONTENT")) {
                    TextEditor(text: $content)
                        .frame(minHeight: 220)
                }

                Section {
                    Text("Your snippets are saved locally on this device.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(existingID == nil ? "New Snippet" : "Edit Snippet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let snippet = ToolboxSnippet(
                            id: existingID ?? UUID(),
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            content: content,
                            category: category,
                            createdAt: existingDate
                        )

                        onSave(snippet)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(
                        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
