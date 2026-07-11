import SwiftUI

struct CategorySidebarView: View {
    let categories: [Category]
    @Binding var selectedCategory: Category?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.xs) {
                allChannelsRow
                Divider().padding(.vertical, Spacing.xs)
                ForEach(categories, id: \.groupTitle) { category in
                    categoryRow(category)
                }
            }
            .padding(.vertical, Spacing.sm)
        }
        .frame(minWidth: TVSize.channelCardWidth)
        .focusSection()
    }

    private var allChannelsRow: some View {
        Button {
            selectedCategory = nil
        } label: {
            HStack {
                Text("All Channels")
                    .font(.body)
                Spacer()
                if selectedCategory == nil {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
        }
        .buttonStyle(.plain)
    }

    private func categoryRow(_ category: Category) -> some View {
        Button {
            selectedCategory = category
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.groupTitle)
                        .font(.body)
                    Text("\(category.channelCount) channels")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if selectedCategory?.id == category.id {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
        }
        .buttonStyle(.plain)
    }
}
