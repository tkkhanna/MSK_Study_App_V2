//  Testing
//  CategorySelectionView.swift
//  MSK Study App V2
//
//  Created by Trevor Khanna on 9/11/25.
//
import SwiftUI

struct CategorySelectionView: View {
    let quizType: StudySubject
    let filters: StudyFilters
    var onCategorySelected: (String) -> Void
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Text("Select Category")
                .font(.largeTitle)
                .foregroundStyle(.primary)

            HStack(spacing: 20) {
                ForEach(categories(for: quizType), id: \.self) { category in
                    Button(category.capitalized) {
                        onCategorySelected(category)
                    }
                    .buttonStyle(CustomButtonStyle(color: .orange))
                }
            }

            Button("Back") {
                onBack()
            }
            .buttonStyle(CustomButtonStyle(color: .gray))
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {Color(nsColor: .windowBackgroundColor).ignoresSafeArea()}
    }

    func categories(for type: StudySubject) -> [String] {

        let items = (
            QuizManager<GenericQuizItem>.loadItems(for: type)
                as! [GenericQuizItem]
        )
        .filter {
            filters.matches($0)
        }

        return StudyLibrary.answerCategories(in: items)
    }
}
