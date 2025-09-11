//
//  QuizView.swift
//  QuizzleQuest Road
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI

struct QuizView: View {
    @StateObject private var viewModel = QuizViewModel()
    @StateObject private var quizService = QuizService()
    @State private var selectedQuiz: Quiz?
    @State private var showingQuizSelection = true
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                
                if showingQuizSelection {
                    QuizSelectionView(
                        quizzes: quizService.availableQuizzes,
                        onQuizSelected: { quiz in
                            selectedQuiz = quiz
                            viewModel.startQuiz(quiz)
                            showingQuizSelection = false
                        }
                    )
                } else if viewModel.isQuizCompleted {
                    QuizResultView(
                        result: viewModel.quizResult,
                        quiz: viewModel.currentQuiz,
                        onRestartQuiz: {
                            if let quiz = selectedQuiz {
                                viewModel.startQuiz(quiz)
                            }
                        },
                        onSelectNewQuiz: {
                            viewModel.resetQuiz()
                            showingQuizSelection = true
                        }
                    )
                } else {
                    QuizQuestionView(viewModel: viewModel)
                }
            }
            .navigationTitle(showingQuizSelection ? "Select Quiz" : (viewModel.currentQuiz?.title ?? "Quiz"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !showingQuizSelection && !viewModel.isQuizCompleted {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Exit") {
                            viewModel.resetQuiz()
                            showingQuizSelection = true
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

struct QuizSelectionView: View {
    let quizzes: [Quiz]
    let onQuizSelected: (Quiz) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                ForEach(QuizCategory.allCases, id: \.self) { category in
                    let categoryQuizzes = quizzes.filter { $0.category == category }
                    
                    if !categoryQuizzes.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(Color("ButtonColor"))
                                Text(category.rawValue)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(categoryQuizzes) { quiz in
                                        QuizCard(quiz: quiz) {
                                            onQuizSelected(quiz)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

struct QuizCard: View {
    let quiz: Quiz
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: quiz.category.icon)
                        .font(.title2)
                        .foregroundColor(Color("ButtonColor"))
                    
                    Spacer()
                    
                    Text(quiz.difficulty.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(difficultyColor(quiz.difficulty))
                        .cornerRadius(8)
                }
                
                Text(quiz.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Text(quiz.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Label("\(quiz.questions.count) questions", systemImage: "questionmark.circle")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Label(timeString(quiz.timeLimit), systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding()
            .frame(width: 250, height: 160)
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func difficultyColor(_ difficulty: DifficultyLevel) -> Color {
        switch difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        case .expert: return .purple
        }
    }
    
    private func timeString(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        return "\(minutes) min"
    }
}

struct QuizQuestionView: View {
    @ObservedObject var viewModel: QuizViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress and timer
            VStack(spacing: 15) {
                HStack {
                    Text("Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.currentQuiz?.questions.count ?? 0)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text(viewModel.timeRemainingFormatted)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(viewModel.timeRemaining < 30 ? .red : .white)
                }
                
                ProgressView(value: viewModel.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color("ButtonColor")))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            
            ScrollView {
                VStack(spacing: 25) {
                    // Question
                    if let question = viewModel.currentQuestion {
                        Text(question.question)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(15)
                    }
                    
                    // Answer options
                    if let question = viewModel.currentQuestion {
                        VStack(spacing: 12) {
                            ForEach(0..<question.options.count, id: \.self) { index in
                                AnswerButton(
                                    text: question.options[index],
                                    isSelected: viewModel.selectedAnswerIndex == index,
                                    isCorrect: viewModel.showAnswer && index == question.correctAnswerIndex,
                                    isIncorrect: viewModel.showAnswer && viewModel.selectedAnswerIndex == index && index != question.correctAnswerIndex,
                                    showAnswer: viewModel.showAnswer
                                ) {
                                    if !viewModel.showAnswer {
                                        viewModel.selectAnswer(index)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Explanation
                    if viewModel.showExplanation, let question = viewModel.currentQuestion {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Explanation")
                                .font(.headline)
                                .foregroundColor(Color("ButtonColor"))
                            
                            Text(question.explanation)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding()
            }
            
            // Action buttons
            if !viewModel.showAnswer && viewModel.selectedAnswerIndex != nil {
                Button("Submit Answer") {
                    viewModel.submitAnswer()
                }
                .foregroundColor(.black)
                .fontWeight(.semibold)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(Color("ButtonColor"))
                .cornerRadius(25)
                .padding()
            } else if !viewModel.showAnswer {
                Button("Skip Question") {
                    viewModel.skipQuestion()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.2))
                .cornerRadius(20)
                .padding()
            }
        }
    }
}

struct AnswerButton: View {
    let text: String
    let isSelected: Bool
    let isCorrect: Bool
    let isIncorrect: Bool
    let showAnswer: Bool
    let action: () -> Void
    
    var backgroundColor: Color {
        if showAnswer {
            if isCorrect {
                return Color("SuccessColor")
            } else if isIncorrect {
                return .red
            }
        } else if isSelected {
            return Color("ButtonColor").opacity(0.3)
        }
        return Color.white.opacity(0.1)
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if showAnswer && isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                } else if showAnswer && isIncorrect {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                } else if isSelected {
                    Image(systemName: "circle.fill")
                        .foregroundColor(Color("ButtonColor"))
                        .font(.caption)
                }
            }
            .padding()
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        showAnswer && isCorrect ? Color("SuccessColor") :
                        showAnswer && isIncorrect ? Color.red :
                        isSelected ? Color("ButtonColor") : Color.white.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(showAnswer)
    }
}

struct QuizResultView: View {
    let result: QuizResult?
    let quiz: Quiz?
    let onRestartQuiz: () -> Void
    let onSelectNewQuiz: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Result header
                VStack(spacing: 15) {
                    Image(systemName: resultIcon)
                        .font(.system(size: 60))
                        .foregroundColor(resultColor)
                    
                    Text(resultTitle)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(resultMessage)
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
                
                // Statistics
                if let result = result, let quiz = quiz {
                    VStack(spacing: 15) {
                        Text("Quiz Statistics")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        VStack(spacing: 12) {
                            StatRow(label: "Score", value: "\(result.score) points")
                            StatRow(label: "Correct Answers", value: "\(result.correctAnswers.count)/\(result.totalQuestions)")
                            StatRow(label: "Accuracy", value: String(format: "%.1f%%", Double(result.correctAnswers.count) / Double(result.totalQuestions) * 100))
                            StatRow(label: "Time Spent", value: timeString(result.timeSpent))
                            StatRow(label: "Category", value: quiz.category.rawValue)
                            StatRow(label: "Difficulty", value: quiz.difficulty.rawValue)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(15)
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button("Try Again") {
                        onRestartQuiz()
                    }
                    .foregroundColor(.black)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(Color("ButtonColor"))
                    .cornerRadius(25)
                    
                    Button("Select New Quiz") {
                        onSelectNewQuiz()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                }
            }
            .padding()
        }
    }
    
    private var resultIcon: String {
        guard let result = result else { return "questionmark" }
        let percentage = Double(result.correctAnswers.count) / Double(result.totalQuestions) * 100
        
        if percentage >= 90 { return "crown.fill" }
        else if percentage >= 70 { return "star.fill" }
        else if percentage >= 50 { return "hand.thumbsup.fill" }
        else { return "arrow.clockwise" }
    }
    
    private var resultColor: Color {
        guard let result = result else { return .gray }
        let percentage = Double(result.correctAnswers.count) / Double(result.totalQuestions) * 100
        
        if percentage >= 90 { return .yellow }
        else if percentage >= 70 { return Color("SuccessColor") }
        else if percentage >= 50 { return .orange }
        else { return .red }
    }
    
    private var resultTitle: String {
        guard let result = result else { return "Quiz Complete" }
        let percentage = Double(result.correctAnswers.count) / Double(result.totalQuestions) * 100
        
        if percentage >= 90 { return "Outstanding!" }
        else if percentage >= 70 { return "Well Done!" }
        else if percentage >= 50 { return "Good Effort!" }
        else { return "Keep Learning!" }
    }
    
    private var resultMessage: String {
        guard let result = result else { return "" }
        let percentage = Double(result.correctAnswers.count) / Double(result.totalQuestions) * 100
        
        if percentage >= 90 { return "You're a quiz master! 🌟" }
        else if percentage >= 70 { return "Great job! You're doing well! 🎉" }
        else if percentage >= 50 { return "Good start! Practice makes perfect! 👏" }
        else { return "Don't give up! Every expert was once a beginner! 💪" }
    }
    
    private func timeString(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    QuizView()
}

