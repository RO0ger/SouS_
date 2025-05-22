import SwiftUI

// Generic view that arranges subviews horizontally, wrapping to the next line when needed.
struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content
    @State private var availableWidth: CGFloat = 0

    init(data: Data, spacing: CGFloat = 8, alignment: HorizontalAlignment = .leading, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.spacing = spacing
        self.alignment = alignment
        self.content = content
    }

    var body: some View {
        ZStack(alignment: Alignment(horizontal: alignment, vertical: .center)) {
            Color.clear // Use Color.clear to expand ZStack in GeometryReader
                .frame(height: 1)
                .readSize { size in
                    availableWidth = size.width
                }

            _FlexibleViewInternal(
                availableWidth: availableWidth,
                data: data,
                spacing: spacing,
                alignment: alignment,
                content: content
            )
        }
    }
}

// Internal helper struct to perform the layout calculation
private struct _FlexibleViewInternal<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let availableWidth: CGFloat
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content
    @State var elementsSize: [Data.Element: CGSize] = [:]

    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            ForEach(computeRows(), id: \.self) { rowElements in
                HStack(spacing: spacing) {
                    ForEach(rowElements, id: \.self) { element in
                        content(element)
                            .fixedSize()
                            .readSize { size in
                                elementsSize[element] = size
                            }
                    }
                }
            }
        }
    }

    // Calculates how to break the elements into rows based on available width
    func computeRows() -> [[Data.Element]] {
        var rows: [[Data.Element]] = [[]]
        var currentRow = 0
        var remainingWidth = availableWidth

        for element in data {
            let elementSize = elementsSize[element, default: CGSize(width: availableWidth, height: 1)]

            // Check if the element fits, considering spacing if it's not the first element in the row
            let widthNeeded = elementSize.width + (rows[currentRow].isEmpty ? 0 : spacing)

            if remainingWidth >= widthNeeded {
                 rows[currentRow].append(element)
                 remainingWidth -= widthNeeded
            } else {
                 // Start a new row if the element doesn't fit, even if it's the only thing on the line
                 currentRow += 1
                 rows.append([element])
                 remainingWidth = availableWidth - elementSize.width // Reset remaining width for the new row
            }
        }
        return rows
    }
}

// Helper view modifier to read the size of a view
extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

// Preference key for capturing view size
private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}
