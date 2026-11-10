//
//  protocol.swift
//  MSK Study App V2
//
//  Created by Trevor Khanna on 9/11/25.
//


import SwiftUI
import Foundation

// MARK: - QuizItem protocol
protocol QuizItem: Identifiable {
    var id: UUID { get }
    var name: String { get }
    var categories: [String: String] { get }
}

// MARK: - Study sets and subjects

struct StudySubject: Identifiable, Hashable {
    let id: String
    let displayName: String
    let fileName: String
    let studySetID: String
}

struct StudySet: Decodable {
    let id: String
    let name: String
    let subjects: [SubjectDefinition]

    struct SubjectDefinition: Decodable {
        let id: String
        let name: String
        let file: String
    }
}

enum StudyLibrary {

    // Discover all bundled StudySet*.json files
    static var subjects: [StudySubject] {

        let manifests = (
            Bundle.main.urls(
                forResourcesWithExtension: "json",
                subdirectory: nil
            ) ?? []
        )
        .filter {
            $0.deletingPathExtension()
                .lastPathComponent
                .hasPrefix("StudySet")
        }
        .sorted {
            $0.lastPathComponent < $1.lastPathComponent
        }

        var result: [StudySubject] = []

        for url in manifests {

            guard let data = try? Data(contentsOf: url),
                  let studySet = try? JSONDecoder().decode(
                    StudySet.self,
                    from: data
                  ) else {
                continue
            }

            for subject in studySet.subjects {

                let base = (subject.file as NSString)
                    .deletingPathExtension

                guard Bundle.main.url(
                    forResource: base,
                    withExtension: "txt"
                ) != nil else {
                    continue
                }

                result.append(
                    StudySubject(
                        id: "\(studySet.id).\(subject.id)",
                        displayName: subject.name,
                        fileName: base,
                        studySetID: studySet.id
                    )
                )
            }
        }

        return result
    }

    // Any field beginning with filter. is a filter
    static func isFilter(_ key: String) -> Bool {
        key.hasPrefix("filter.")
    }

    // Generate readable filter titles
    static func filterTitle(_ key: String) -> String {
        String(key.dropFirst("filter.".count))
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    // Discover answer categories automatically
    static func answerCategories(
        in items: [GenericQuizItem]
    ) -> [String] {

        Array(Set(items.flatMap { $0.categories.keys }))
            .filter {
                $0 != "description" && !isFilter($0)
            }
            .sorted()
    }

    // Discover filter groups and their options
    static func filterGroups(
        in items: [GenericQuizItem]
    ) -> [String: [String]] {

        var groups: [String: Set<String>] = [:]

        for item in items {

            for (key, value) in item.categories
            where isFilter(key) {

                let values = value
                    .split(separator: ",")
                    .map {
                        $0.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                    }
                    .filter { !$0.isEmpty }

                groups[key, default: []]
                    .formUnion(values)
            }
        }

        return groups.mapValues { $0.sorted() }
    }

    // Preserve the order of filters in the text file
    static func orderedFilterKeys(
        for subject: StudySubject
    ) -> [String] {

        guard let url = Bundle.main.url(
            forResource: subject.fileName,
            withExtension: "txt"
        ),
        let text = try? String(
            contentsOf: url,
            encoding: .utf8
        ) else {
            return []
        }

        var keys: [String] = []

        for line in text.components(separatedBy: .newlines) {

            for field in line
                .components(separatedBy: ";")
                .dropFirst(2) {

                guard let colon = field.firstIndex(of: ":")
                else {
                    continue
                }

                let key = String(field[..<colon])
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .lowercased()

                if isFilter(key) && !keys.contains(key) {
                    keys.append(key)
                }
            }
        }

        return keys
    }
}

// MARK: - GenericQuizItem
struct GenericQuizItem: QuizItem {
    let id = UUID()
    var name: String
    var categories: [String: String]
}

// MARK: - Study filters

struct StudyFilters {
    var selections: [String: Set<String>] = [:]
    var isEmpty: Bool {
        selections.values.allSatisfy { $0.isEmpty }
    }
    func matches(_ item: GenericQuizItem) -> Bool {
        selections.allSatisfy { entry in
            let key = entry.key
            let selected = entry.value
            if selected.isEmpty {
                return true
            }
            let values = Set(
                (item.categories[key] ?? "")
                    .split(separator: ",")
                    .map {
                        $0.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                    }
            )
            return !selected.isDisjoint(with: values)
        }
    }
}

// MARK: - QuizManager
class QuizManager<T: QuizItem>: ObservableObject {
    @Published private(set) var items: [T] = []
    @Published private(set) var remainingItems: [T] = []
    @Published private(set) var askedItems: [T] = []
    @Published var currentItem: T? = nil
    @Published var quizOver = false
    @Published var userAnswers: [UUID: String] = [:]

    private var quizCategory: String
    private var quizType: StudySubject

    init(type: StudySubject, selectedCategory: String, questionLimit: Int, filters: StudyFilters = StudyFilters()){
        
        let loadedItems = Self.loadItems(for: type) as! [T]

        let filteredItems = loadedItems.filter {
            filters.matches($0 as! GenericQuizItem) &&
            !($0.categories[selectedCategory] ?? "")
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty
        }

        // NEW: Track questions already included
        var seenQuestions = Set<String>()

        // NEW: Remove duplicate question-and-answer pairs
        let uniqueItems = filteredItems.filter { item in
            let question = item.name
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            let answer = (item.categories[selectedCategory] ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            let key = "\(question)|\(answer)"

            return seenQuestions.insert(key).inserted
        }

        // Shuffle the unique questions
        let shuffledItems = uniqueItems.shuffled()

        // Apply the selected question limit
        let limitedItems = Array(
            shuffledItems.prefix(min(questionLimit, shuffledItems.count))
        )


        self.items = limitedItems
        self.remainingItems = limitedItems
        self.quizCategory = selectedCategory
        self.quizType = type
        self.nextItem()
    }

    func currentCategory() -> String {
        return quizCategory
    }

    func options(for category: String) -> [String] {

        guard let current = currentItem,
              let correct = current.categories[category]
        else {
            return []
        }

        var options = Set<String>()
        options.insert(correct)

        // Only load answers from the selected subject
        let allItems = Self.loadItems(for: quizType) as! [T]

        func normalized(_ value: String) -> String {
            value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .lowercased()
        }

        // Find all known correct answers for this question
        let validAnswers = Set(
            allItems
                .filter {
                    normalized($0.name) ==
                    normalized(current.name)
                }
                .compactMap {
                    $0.categories[category]
                }
                .map(normalized)
        )
        .union([normalized(correct)])

        // Exclude every known correct answer from distractors
        let otherOptions = Set(
            allItems.compactMap {
                $0.categories[category]
            }
        )
        .filter {
            !validAnswers.contains(normalized($0))
        }

        Array(otherOptions.shuffled().prefix(3))
            .forEach {
                options.insert($0)
            }

        return Array(options).shuffled()
    }

    func submitAnswer(_ answer: String) {
        guard !quizOver, let current = currentItem else { return }
        guard userAnswers[current.id] == nil else { return }
        userAnswers[current.id] = answer
        nextItem()
    }

    func nextItem() {
        if remainingItems.isEmpty {
            quizOver = true
            currentItem = nil
        } else {
            let next = remainingItems.removeFirst()
            currentItem = next
            askedItems.append(next)
        }
    }

    func endQuizEarly() {
        // Prevent any more questions from appearing
        remainingItems = []

        // Clear the current question
        currentItem = nil

        // Trigger the existing ResultsView
        quizOver = true
    }
    
    func resetQuiz() {
        remainingItems = items.shuffled()
        askedItems = []
        quizOver = false
        userAnswers = [:]
        nextItem()
    }

    static func loadItems(for type: StudySubject) -> [any QuizItem] {

        guard let url = Bundle.main.url(
            forResource: type.fileName,
            withExtension: "txt"
        ),
        let contents = try? String(
            contentsOf: url,
            encoding: .utf8
        ) else {

            print("Study file not found: \(type.fileName).txt")
            return []
        }

        return contents
            .components(separatedBy: .newlines)
            .compactMap { line -> GenericQuizItem? in

                let parts = line
                    .components(separatedBy: ";")
                    .map {
                        $0.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                    }

                guard parts.count >= 2,
                      !parts[0].isEmpty else {
                    return nil
                }

                var categories = [
                    "description": parts[1]
                ]

                // Read any number of additional fields
                for field in parts.dropFirst(2) {

                    guard let colon = field.firstIndex(of: ":")
                    else {
                        continue
                    }

                    let key = String(field[..<colon])
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                        .lowercased()

                    let value = String(
                        field[field.index(after: colon)...]
                    )
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                    if !key.isEmpty && !value.isEmpty {
                        categories[key] = value
                    }
                }

                return GenericQuizItem(
                    name: parts[0],
                    categories: categories
                )
            }
    }

}
