import SwiftUI

struct AddPlaylistView: View {
    let onAdd: (URL, String, URL?) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var m3uURLText = ""
    @State private var nameText = ""
    @State private var epgURLText = ""
    @State private var isAdding = false
    @State private var validationError: String?

    @FocusState private var focusedField: Field?

    private enum Field: Hashable { case name, m3uURL, epgURL }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text("Add Playlist")
                .font(.title2)
                .bold()

            VStack(alignment: .leading, spacing: Spacing.sm) {
                TextField("Name (optional)", text: $nameText)
                    .focused($focusedField, equals: .name)

                TextField("M3U URL (required)", text: $m3uURLText)
                    .focused($focusedField, equals: .m3uURL)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    TextField("EPG/XMLTV URL (optional)", text: $epgURLText)
                        .focused($focusedField, equals: .epgURL)

                    Text("Leave blank to auto-detect from playlist header.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let validationError {
                Text(validationError)
                    .foregroundStyle(.red)
                    .font(.callout)
            }

            HStack(spacing: Spacing.md) {
                Button("Cancel") { dismiss() }

                Button("Add Playlist") {
                    Task { await submit() }
                }
                .disabled(m3uURLText.trimmingCharacters(in: .whitespaces).isEmpty || isAdding)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(Spacing.xl)
        .frame(minWidth: TVSize.sheetMinWidth)
        .overlay {
            if isAdding {
                ProgressView("Adding playlist…")
                    .padding(Spacing.lg)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: TVSize.thumbnailCornerRadius))
            }
        }
        .onAppear { focusedField = .m3uURL }
        .onExitCommand { dismiss() }
    }

    private func submit() async {
        let rawURL = m3uURLText.trimmingCharacters(in: .whitespaces)
        guard let url = URL(string: rawURL), ["http", "https"].contains(url.scheme) else {
            validationError = "Enter a valid http or https URL."
            return
        }

        let epgURL: URL?
        let rawEPG = epgURLText.trimmingCharacters(in: .whitespaces)
        if rawEPG.isEmpty {
            epgURL = nil
        } else if let parsed = URL(string: rawEPG), ["http", "https"].contains(parsed.scheme) {
            epgURL = parsed
        } else {
            validationError = "EPG URL must be a valid http or https URL."
            return
        }

        let name = nameText.trimmingCharacters(in: .whitespaces).isEmpty
            ? (url.host ?? "Playlist")
            : nameText.trimmingCharacters(in: .whitespaces)

        validationError = nil
        isAdding = true

        do {
            try await onAdd(url, name, epgURL)
            dismiss()
        } catch {
            validationError = AppError(error).errorDescription ?? error.localizedDescription
            isAdding = false
        }
    }
}
