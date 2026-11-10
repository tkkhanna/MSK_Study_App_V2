import SwiftUI

struct StudyFilterView: View {
    let quizType: StudySubject
    let customMode: Bool
    @Binding var filters: StudyFilters
    let onContinue: () -> Void
    let onBack: () -> Void

    private var loadedItems: [GenericQuizItem] {
        QuizManager<GenericQuizItem>.loadItems(
            for: quizType
        ) as! [GenericQuizItem]
    }

    private var groups: [String: [String]] {
        StudyLibrary.filterGroups(in: loadedItems)
    }

    private var orderedKeys: [String] {
        StudyLibrary.orderedFilterKeys(for: quizType)
            .filter { groups[$0] != nil }
    }

    private var visibleKeys: [String] {
        customMode
            ? orderedKeys
            : Array(orderedKeys.prefix(1))
    }

    private var matchingCount: Int {

        loadedItems.filter {
            filters.matches($0) &&
            !StudyLibrary.answerCategories(in: [$0]).isEmpty
        }
        .count
    }
    
    private func isOptionAvailable(
        _ option: String,
        in key: String
    ) -> Bool {

        var trial = filters

        if customMode {
            trial.selections[key, default: []].insert(option)
        } else {
            trial.selections[key] = [option]
        }

        return loadedItems.contains {
            trial.matches($0) &&
            !StudyLibrary.answerCategories(in: [$0]).isEmpty
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(customMode ? "Custom Study" : "Quick Study")
                    .font(.largeTitle).bold().foregroundStyle(.primary)
                Text(customMode ? "Choose any combination. Multiple choices within a group include all of the selected options. Multiple choices across groups include only topics that fulfill all of the selected options. To choose all, do not select any options." : "Choose a region, or leave all unselected to study everything.")
                    .foregroundStyle(.secondary)
                
                ForEach(visibleKeys, id: \.self) { key in
                    section(
                        key,
                        options: groups[key] ?? []
                    )
                }
                
                Text("\(matchingCount) matching study entries")
                    .font(.headline)
                    .foregroundColor(matchingCount == 0 ? .orange : .green)
                if matchingCount == 0 {
                    Text("No matching entries. Remove one or more filters to continue.")
                        .foregroundColor(.orange)
                }
                Button("Continue to Question Type") { onContinue() }
                    .buttonStyle(CustomButtonStyle(color: .blue))
                    .disabled(matchingCount == 0)
                    .opacity(matchingCount == 0 ? 0.5 : 1)
                Button("Back") { onBack() }
                    .buttonStyle(CustomButtonStyle(color: .gray))
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background {Color(nsColor: .windowBackgroundColor).ignoresSafeArea()}
    }

    private func section(
        _ key: String,
        options: [String]
    ) -> some View {

        let selection = Binding<Set<String>>(
            get: {
                filters.selections[key] ?? []
            },
            set: {
                filters.selections[key] = $0
            }
        )

        return VStack(alignment: .leading, spacing: 10) {

            HStack {

                Text(StudyLibrary.filterTitle(key))
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Button("Clear") {
                    selection.wrappedValue = []
                }
                .foregroundColor(.accentColor)
            }

            ForEach(options, id: \.self) { option in

                let selected = selection.wrappedValue.contains(option)
                let available = !customMode ||
                    isOptionAvailable(option, in: key)

                Button {

                    if selected {
                        selection.wrappedValue.remove(option)
                    } else {

                        if !customMode {
                            selection.wrappedValue = []
                        }

                        selection.wrappedValue.insert(option)
                    }

                } label: {

                    HStack {

                        Image(
                            systemName: selected
                                ? "checkmark.square.fill"
                                : "square"
                        )

                        Text(option)

                        Spacer()
                    }
                    .foregroundStyle(.primary)
                    .padding(10)
                    .background(Color.primary.opacity(0.08))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(!available && !selected)
                .opacity(
                    available || selected ? 1.0 : 0.3
                )
            }
        }
    }
}
