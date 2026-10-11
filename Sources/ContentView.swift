import SwiftUI
import UIKit

private struct SavedSnippet: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var body: String
    var category: String
    var createdAt: Date = Date()
}

struct ContentView: View {
    @State private var snippets: [SavedSnippet] = []
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var showingEditor = false
    @State private var editingSnippet: SavedSnippet?
    @State private var copiedID: UUID?
    @State private var showingCopiedMessage = false

    private let storageKey = "PocketToolbox.savedSnippets"
    private let categories = ["All", "General", "Gaming", "Work", "Code"]

    private var filteredSnippets: [SavedSnippet] {
        snippets.filter { snippet in
            let matchesCategory = selectedCategory == "All" || snippet.category == selectedCategory
            let matchesSearch = searchText.isEmpty ||
                snippet.title.localizedCaseInsensitiveContains(searchText) ||
                snippet.body.localizedCaseInsensitiveContains(searchText) ||
                snippet.category.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { category in
                                Button {
                                    selectedCategory = category
                                } label: {
                                    Text(category)
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 9)
                                        .background(selectedCategory == category ? Color.blue : Color(uiColor: .secondarySystemGroupedBackground))
                                        .foregroundColor(selectedCategory == category ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }

                    if filteredSnippets.isEmpty {
                        emptyState
                    } else {
                        List {
                            ForEach(filteredSnippets) { snippet in
                                snippetCard(snippet)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            delete(snippet)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }

                                        Button {
                                            editingSnippet = snippet
                                            showingEditor = true
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingEditor, onDismiss: { editingSnippet = nil }) {
                SnippetEditor(existing: editingSnippet) { saved in
                    if let index = snippets.firstIndex(where: { $0.id == saved.id }) {
                        snippets[index] = saved
                    } else {
                        snippets.insert(saved, at: 0)
                    }
                    persist()
                }
            }
            .overlay(alignment: .bottom) {
                if showingCopiedMessage {
                    Label("Copied to clipboard", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.bottom, 18)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .onAppear(perform: load)
        }
        .navigationViewStyle(.stack)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("POCKET TOOLBOX")
                        .font(.caption.weight(.bold))
                        .tracking(1.8)
                        .foregroundColor(.blue)
                    Text("Your quick saves.")
                        .font(.largeTitle.bold())
                }
                Spacer()
                Button {
                    editingSnippet = nil
                    showingEditor = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .accessibilityLabel("Add snippet")
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search saved text...", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                }
            }
            .padding(13)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: searchText.isEmpty ? "tray.full" : "magnifyingglass")
                .font(.system(size: 42))
                .foregroundColor(.blue)
            Text(searchText.isEmpty ? "Nothing saved yet" : "No matches found")
                .font(.title3.bold())
            Text(searchText.isEmpty
                 ? "Save text you reuse often—game commands, notes, links, or code snippets."
                 : "Try another search or category.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            if searchText.isEmpty {
                Button {
                    editingSnippet = nil
                    showingEditor = true
                } label: {
                    Label("Create your first save", systemImage: "plus")
                        .font(.headline)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 50)
    }

    private func snippetCard(_ snippet: SavedSnippet) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(snippet.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(snippet.category.uppercased())
                        .font(.caption2.weight(.bold))
                        .tracking(1)
                        .foregroundColor(.blue)
                }
                Spacer()
                Button {
                    editingSnippet = snippet
                    showingEditor = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color(uiColor: .tertiarySystemGroupedBackground))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Edit \(snippet.title)")
            }

            Text(snippet.body)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)

            Button {
                UIPasteboard.general.string = snippet.body
                copiedID = snippet.id
                withAnimation { showingCopiedMessage = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                    withAnimation { showingCopiedMessage = false }
                    if copiedID == snippet.id { copiedID = nil }
                }
            } label: {
                Label(copiedID == snippet.id ? "Copied" : "Copy text",
                      systemImage: copiedID == snippet.id ? "checkmark" : "doc.on.doc")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(copiedID == snippet.id ? Color.green.opacity(0.14) : Color.blue.opacity(0.12))
                    .foregroundColor(copiedID == snippet.id ? .green : .blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([SavedSnippet].self, from: data) else {
            snippets = [
                SavedSnippet(title: "Example game command", body: "/time set day", category: "Gaming"),
                SavedSnippet(title: "Quick note", body: "Tap Edit to change this, or swipe a card to delete it.", category: "General")
            ]
            persist()
            return
        }
        snippets = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(snippets) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func delete(_ snippet: SavedSnippet) {
        snippets.removeAll { $0.id == snippet.id }
        persist()
    }
}

private struct SnippetEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var bodyText: String
    @State private var category: String
    private let existing: SavedSnippet?
    private let onSave: (SavedSnippet) -> Void

    private let categories = ["General", "Gaming", "Work", "Code"]

    init(existing: SavedSnippet?, onSave: @escaping (SavedSnippet) -> Void) {
        self.existing = existing
        self.onSave = onSave
        _title = State(initialValue: existing?.title ?? "")
        _bodyText = State(initialValue: existing?.body ?? "")
        _category = State(initialValue: existing?.category ?? "General")
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Title") {
                    TextField("e.g. Server address", text: $title)
                }

                Section("Text to save") {
                    TextEditor(text: $bodyText)
                        .frame(minHeight: 150)
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { item in
                            Text(item).tag(item)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section {
                    Text("Saved on this device. Tap Copy on a card whenever you need the text.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(existing == nil ? "New Save" : "Edit Save")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        let cleanBody = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !cleanTitle.isEmpty, !cleanBody.isEmpty else { return }
                        var saved = existing ?? SavedSnippet(title: cleanTitle, body: cleanBody, category: category)
                        saved.title = cleanTitle
                        saved.body = cleanBody
                        saved.category = category
                        onSave(saved)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
