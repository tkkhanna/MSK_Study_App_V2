import SwiftUI
import AppKit

struct MainView: View {
    @State private var selectedStudySubject: StudySubject? = nil
    @State private var showCategorySelection = false
    @State private var showModeSelection = false
    @State private var showFilterSelection = false
    @State private var studyFilters = StudyFilters()
    @State private var customMode = false
    @State private var selectedCategory: String? = nil
    @State private var startQuiz = false

    @State private var selectedQuestionCount = 10
    @State private var questionCountText = "10"

    @State private var showSettingsMenu = false
    @State private var showQuestionSubmenu = false
    @State private var showQuestionChoices = false
    @State private var showAppearanceSubmenu = false
    @AppStorage("appAppearance") private var appAppearance = "Dark"
    
    private func updateAppearance() {
        let appearance: NSAppearance?

        switch appAppearance {
        case "Light":
            appearance = NSAppearance(named: .aqua)
        case "Dark":
            appearance = NSAppearance(named: .darkAqua)
        default:
            appearance = nil
        }

        NSApp.appearance = appearance
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()
            if !showCategorySelection && !showModeSelection && !showFilterSelection && !startQuiz {
                VStack {
                    HStack {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showSettingsMenu.toggle()
                                if !showSettingsMenu {
                                    showQuestionSubmenu = false
                                    showQuestionChoices = false
                                    showAppearanceSubmenu = false
                                }
                            }
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundStyle(.primary)
                                .padding(12)
                                .background(Color.gray.opacity(0.25))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)

                    Spacer()

                    VStack(spacing: 30) {
                        Text("Select Quiz Type")
                            .font(.largeTitle)
                            .foregroundStyle(.primary)

                        ForEach(Array(StudyLibrary.subjects.enumerated()),id: \.element.id)
                        { index, subject in

                            Button("\(subject.displayName) Quiz") {
                                selectedStudySubject = subject
                                showModeSelection = true
                            }
                            .buttonStyle(
                                CustomButtonStyle(
                                    color: [.blue, .green, .orange][index % 3]
                                )
                            )
                        }
                    }

                    Spacer()
                }
            } else if showModeSelection && !startQuiz {
                VStack(spacing: 24) {
                    Text("Choose Study Mode").font(.largeTitle).foregroundStyle(.primary)
                    Button("Quick Study") {
                        studyFilters = StudyFilters()
                        customMode = false
                        showModeSelection = false
                        showFilterSelection = true
                    }.buttonStyle(CustomButtonStyle(color: .blue))
                    Button("Custom Study") {
                        studyFilters = StudyFilters()
                        customMode = true
                        showModeSelection = false
                        showFilterSelection = true
                    }.buttonStyle(CustomButtonStyle(color: .orange))
                    Button("Back") {
                        showModeSelection = false
                        selectedStudySubject = nil
                    }
                        .buttonStyle(CustomButtonStyle(color: .gray))
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if showFilterSelection && !startQuiz, let type = selectedStudySubject {
                StudyFilterView(quizType: type, customMode: customMode, filters: $studyFilters, onContinue: {
                    showFilterSelection = false
                    showCategorySelection = true
                }, onBack: {
                    showFilterSelection = false
                    showModeSelection = true
                })
            } else if showCategorySelection && !startQuiz, let type = selectedStudySubject {
                CategorySelectionView(
                    quizType: type,
                    filters: studyFilters,
                    onCategorySelected: { category in
                        selectedCategory = category
                        startQuiz = true
                        showCategorySelection = false
                    },
                    onBack: {
                        showCategorySelection = false
                        showFilterSelection = true
                    }
                )
            } else if startQuiz, let type = selectedStudySubject, let category = selectedCategory {
                QuizView(
                    manager: QuizManager<GenericQuizItem>(
                        type: type,
                        selectedCategory: category,
                        questionLimit: max(1, Int(questionCountText) ?? 10),
                        filters: studyFilters
                    ),
                    showMainScreen: $startQuiz,
                    showCategorySelection: $showCategorySelection
                )
            }

            if showSettingsMenu {
                Color.clear
                    .contentShape(Rectangle())
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSettingsMenu = false
                            showQuestionSubmenu = false
                            showQuestionChoices = false
                            showAppearanceSubmenu = false
                        }
                    }

                HStack(alignment: .top, spacing: 6) {
                    SettingsDropdownView(
                        showQuestionSubmenu: $showQuestionSubmenu,
                        showQuestionChoices: $showQuestionChoices,
                        showAppearanceSubmenu: $showAppearanceSubmenu
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))

                    if showQuestionSubmenu && !showAppearanceSubmenu {
                        QuestionSubmenuView(
                            questionCountText: $questionCountText,
                            showQuestionChoices: $showQuestionChoices,
                            onSubmit: {
                                if questionCountText.isEmpty {
                                    questionCountText = "10"
                                }

                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showSettingsMenu = false
                                    showQuestionSubmenu = false
                                    showQuestionChoices = false
                                    showAppearanceSubmenu = false
                                }
                            }
                        )
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                    if showAppearanceSubmenu {
                        AppearanceSubmenuView(
                            appAppearance: $appAppearance
                        )
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                }
                .padding(.top, 72)
                .padding(.leading, 20)
                .zIndex(1)
            }
        }
        .onAppear {
                    updateAppearance()
                }
                .onChange(of: appAppearance) { _ in
                    updateAppearance()
                }
    }
}


struct SettingsDropdownView: View {

    @Binding var showQuestionSubmenu: Bool
    @Binding var showQuestionChoices: Bool
    @Binding var showAppearanceSubmenu: Bool

    @Environment(\.colorScheme) private var colorScheme

    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var menuBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.12, green: 0.12, blue: 0.12)
            : Color(red: 0.94, green: 0.94, blue: 0.94)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("Settings")
                .font(.headline)
                .foregroundColor(textColor)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showQuestionSubmenu.toggle()
                    showAppearanceSubmenu = false

                    if !showQuestionSubmenu {
                        showQuestionChoices = false
                    }
                }
            } label: {
                HStack {
                    Text("Number of questions per quiz")
                        .foregroundColor(textColor)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(textColor.opacity(0.06))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showAppearanceSubmenu.toggle()
                    showQuestionSubmenu = false
                    showQuestionChoices = false
                }
            } label: {
                HStack {
                    Text("Appearance")
                        .foregroundColor(textColor)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(textColor.opacity(0.06))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(width: 260, alignment: .leading)
        .background(menuBackground)
        .cornerRadius(12)
        .shadow(radius: 10)
        .onTapGesture { }
    }
}

struct AppearanceSubmenuView: View {

    @Binding var appAppearance: String

    @Environment(\.colorScheme) private var colorScheme

    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var menuBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.12, green: 0.12, blue: 0.12)
            : Color(red: 0.94, green: 0.94, blue: 0.94)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("Choose Appearance")
                .font(.headline)
                .foregroundColor(textColor)

            ForEach(["System", "Light", "Dark"], id: \.self) { mode in

                Button {
                    appAppearance = mode
                } label: {
                    HStack {
                        Text(mode == "System"
                             ? "System"
                             : "\(mode) Mode")
                            .foregroundColor(textColor)

                        Spacer()

                        if appAppearance == mode {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(textColor.opacity(0.06))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(width: 220, alignment: .leading)
        .background(menuBackground)
        .cornerRadius(12)
        .shadow(radius: 10)
        .onTapGesture { }
    }
}

struct QuestionSubmenuView: View {
    @Binding var questionCountText: String
    @Binding var showQuestionChoices: Bool
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showQuestionChoices.toggle()
                }
            }) {
                HStack {
                    Text("Set number of questions")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: showQuestionChoices ? "chevron.down" : "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(Color.white.opacity(0.06))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)

            if showQuestionChoices {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter number of questions")
                        .foregroundStyle(.primary)
                        .font(.subheadline)

                    TextField("e.g. 10", text: Binding(
                        get: { questionCountText },
                        set: { newValue in
                            questionCountText = newValue.filter { $0.isNumber }
                        }
                    ))
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(10)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(8)
#if os(iOS)
                    .keyboardType(.numberPad)
#endif
                    .onSubmit {
                        onSubmit()
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(width: 220, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 10)
        .onTapGesture { }
    }
}

struct CustomButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: 220)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
