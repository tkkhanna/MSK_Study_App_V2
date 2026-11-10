import SwiftUI

struct ResultsView<T: QuizItem>: View {
    @ObservedObject var manager: QuizManager<T>
    @Binding var showMainScreen: Bool
    @Binding var showCategorySelection: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Quiz Results")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.primary)

                // Table headers
                HStack {
                    Text("Question")
                        .bold()
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Your Answer")
                        .bold()
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text("Correct Answer")
                        .bold()
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal)

                Divider()

                // Results rows
                ForEach(manager.askedItems) { item in
                    let correct = item.categories[manager.currentCategory()] ?? ""
                    let user = manager.userAnswers[item.id] ?? "—"
                    HStack {
                        Text(item.name)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(user)
                            .foregroundColor(user == correct ? .green : .red)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text(correct)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal)
                }

                Divider()

                Button(action: {
                    manager.resetQuiz()
                    showMainScreen = true
                }) {
                    Text("Restart Quiz")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                Button(action: {
                    manager.resetQuiz()
                    showMainScreen = false
                    showCategorySelection = false
                }) {
                    Text("Home")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .padding(.top)
            }
            .padding()
        }
        .background {Color(nsColor: .windowBackgroundColor).ignoresSafeArea()}
    }
}
