//
//  QuizView.swift
//  MSK Study App V2
//
//  Created by Trevor Khanna on 9/11/25.
//


import SwiftUI

struct QuizView<T: QuizItem>: View {
    @ObservedObject var manager: QuizManager<T>
    @Binding var showMainScreen: Bool
    @Binding var showCategorySelection: Bool

    @State private var selectedAnswer: String? = nil
    @State private var showFeedback = false
    @State private var currentOptions: [String] = []
    @State private var currentItemID: UUID? = nil
    @State private var showEndQuizConfirmation = false

    var body: some View {
        Group {
            if let item = manager.currentItem {
                let category = manager.currentCategory()
                VStack(spacing: 20) {
                    HStack {
                            Spacer()

                            Button("Skip to Results") {
                                showEndQuizConfirmation = true
                            }
                            .buttonStyle(.bordered)
                            .disabled(showFeedback)
                        }
                    // Question text
                    Text("What is the \(category) for:")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(item.name)
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(.primary)

                    // Options buttons
                    ForEach(currentOptions, id: \.self) { option in
                        Button(action: {
                            handleSelection(option, correctAnswer: item.categories[category] ?? "")
                        }) {
                            HStack {
                                Text(option)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if showFeedback {
                                    let correctAnswer = item.categories[category] ?? ""
                                    if option == correctAnswer {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    } else if selectedAnswer == option {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.primary.opacity(0.08))
                            .cornerRadius(8)
                        }
                        .disabled(showFeedback)
                        .buttonStyle(.plain)
                    }

                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .windowBackgroundColor))
                // Initialize options when the view appears
                .onAppear {
                    currentOptions = manager.options(for: category)
                    currentItemID = item.id
                }
                // Update options when a new question appears
                .onChange(of: item.id) { newID in
                    currentOptions = manager.options(for: category)
                    currentItemID = newID
                }
                .alert("End quiz early?", isPresented: $showEndQuizConfirmation) {
                    Button("Cancel", role: .cancel) { }

                    Button("View Results") {
                        finishQuizEarly()
                    }
                } message: {
                    Text("Your answered questions will be counted. Remaining questions will be skipped.")
                }
            }
            else if manager.quizOver {
                ResultsView(manager: manager, showMainScreen: $showMainScreen, showCategorySelection: $showCategorySelection)
            }
            else {
                Text("Loading...")
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Selection handling
    private func handleSelection(_ option: String, correctAnswer: String) {

        // Prevent another selection while processing an answer
        guard !showFeedback, !manager.quizOver else { return }

        // Capture the question being answered
        guard let questionID = manager.currentItem?.id else { return }

        selectedAnswer = option
        showFeedback = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {

            // Only submit if we're still on the same question
            guard !manager.quizOver,
                  manager.currentItem?.id == questionID else {
                return
            }

            manager.submitAnswer(option)

            selectedAnswer = nil
            showFeedback = false
        }
    }
    // NEW: End quiz early
    private func finishQuizEarly() {
        manager.endQuizEarly()
    }
}
