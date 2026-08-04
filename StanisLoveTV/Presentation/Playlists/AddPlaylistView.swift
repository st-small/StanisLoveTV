import SwiftUI

struct AddPlaylistView: View {
    let onAdd: (URL, String, URL?) async throws -> Void
    var isDismissable: Bool = true

    @Environment(\.dismiss) private var dismiss
    @State private var m3uURLText = ""
    @State private var nameText = ""
    @State private var epgURLText = ""
    @State private var isAdding = false
    @State private var validationError: String?

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case name, m3uURL, epgURL
    }

    var body: some View {
        VStack(spacing: DSSpacing.xxl) {
            Text("Add Playlist")
                .font(.ds.largeTitle)

            VStack(alignment: .leading, spacing: DSSpacing.s) {
                DSTextField(placeholder: "Name (optional)", text: $nameText, isFocused: focusedField == .name)
                    .focused($focusedField, equals: .name)

                DSTextField(placeholder: "M3U URL (required)", text: $m3uURLText, isFocused: focusedField == .m3uURL)
                    .focused($focusedField, equals: .m3uURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    DSTextField(placeholder: "EPG/XMLTV URL (optional)", text: $epgURLText, isFocused: focusedField == .epgURL)
                        .focused($focusedField, equals: .epgURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Text("Leave blank to auto-detect from playlist header.")
                        .font(.caption)
                        .foregroundStyle(Color.ds.text.secondary)
                }
            }

            if let validationError {
                Text(validationError)
                    .foregroundStyle(Color.ds.accent.error)
                    .font(.callout)
            }

            HStack(spacing: DSSpacing.l) {
                if isDismissable {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(DSButtonStyle(variant: .ghost))
                }

                Button("Add Playlist") {
                    Task { await submit() }
                }
                .disabled(m3uURLText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAdding)
                .buttonStyle(DSButtonStyle(variant: .primary, isLoading: isAdding))
            }
        }
        .padding(DSSpacing.xxxl)
        .frame(maxWidth: DSSize.sheetMaxWidth)
        .overlay {
            if isAdding {
                ProgressView("Adding playlist…")
                    .padding(DSSpacing.xxl)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: DSRadius.s))
            }
        }
        .onAppear { focusedField = .name }
        .onExitCommand {
            guard isDismissable else { return }
            dismiss()
        }
    }

    private func submit() async {
        let rawURL = m3uURLText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: rawURL), ["http", "https"].contains(url.scheme) else {
            validationError = "Enter a valid http or https URL."
            return
        }

        let epgURL: URL?
        let rawEPG = epgURLText.trimmingCharacters(in: .whitespacesAndNewlines)
        if rawEPG.isEmpty {
            epgURL = nil
        } else if let parsed = URL(string: rawEPG), ["http", "https"].contains(parsed.scheme) {
            epgURL = parsed
        } else {
            validationError = "EPG URL must be a valid http or https URL."
            return
        }

        let name = nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? (url.host ?? "Playlist")
            : nameText.trimmingCharacters(in: .whitespacesAndNewlines)

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

#if DEBUG
#Preview {
    AddPlaylistView(onAdd: { _,_,_ in })
}
#endif
