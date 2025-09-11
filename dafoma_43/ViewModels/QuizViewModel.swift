//
//  QuizViewModel.swift
//  QuizzleQuest Road
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation
import SwiftUI

class QuizViewModel: ObservableObject {
    @Published var currentQuiz: Quiz?
    @Published var currentQuestionIndex = 0
    @Published var selectedAnswerIndex: Int?
    @Published var showAnswer = false
    @Published var timeRemaining: TimeInterval = 0
    @Published var isQuizCompleted = false
    @Published var quizResult: QuizResult?
    @Published var userAnswers: [Int] = []
    @Published var score = 0
    @Published var showExplanation = false
    
    private var timer: Timer?
    private var quizStartTime: Date?
    private let quizService: QuizService
    
    init(quizService: QuizService = QuizService()) {
        self.quizService = quizService
    }
    
    // MARK: - Quiz Management
    
    func startQuiz(_ quiz: Quiz) {
        currentQuiz = quiz
        currentQuestionIndex = 0
        selectedAnswerIndex = nil
        showAnswer = false
        isQuizCompleted = false
        quizResult = nil
        userAnswers = Array(repeating: -1, count: quiz.questions.count)
        score = 0
        showExplanation = false
        timeRemaining = quiz.timeLimit
        quizStartTime = Date()
        
        startTimer()
    }
    
    func selectAnswer(_ index: Int) {
        guard !showAnswer else { return }
        selectedAnswerIndex = index
    }
    
    func submitAnswer() {
        guard let selectedIndex = selectedAnswerIndex,
              let quiz = currentQuiz else { return }
        
        userAnswers[currentQuestionIndex] = selectedIndex
        
        let currentQuestion = quiz.questions[currentQuestionIndex]
        if selectedIndex == currentQuestion.correctAnswerIndex {
            score += currentQuestion.points
        }
        
        showAnswer = true
        showExplanation = true
        
        // Auto advance after showing explanation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.nextQuestion()
        }
    }
    
    func nextQuestion() {
        guard let quiz = currentQuiz else { return }
        
        showAnswer = false
        showExplanation = false
        selectedAnswerIndex = nil
        
        if currentQuestionIndex < quiz.questions.count - 1 {
            currentQuestionIndex += 1
        } else {
            completeQuiz()
        }
    }
    
    func skipQuestion() {
        userAnswers[currentQuestionIndex] = -1
        nextQuestion()
    }
    
    private func completeQuiz() {
        timer?.invalidate()
        isQuizCompleted = true
        
        guard let quiz = currentQuiz,
              let startTime = quizStartTime else { return }
        
        let timeSpent = Date().timeIntervalSince(startTime)
        let correctAnswers = userAnswers.enumerated().compactMap { index, answer in
            quiz.questions[index].correctAnswerIndex == answer ? index : nil
        }
        
        quizResult = QuizResult(
            quizId: quiz.id,
            score: score,
            totalQuestions: quiz.questions.count,
            timeSpent: timeSpent,
            completedAt: Date(),
            correctAnswers: correctAnswers
        )
        
        if let result = quizResult {
            quizService.submitQuizResult(result)
        }
    }
    
    // MARK: - Timer Management
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.timeUp()
            }
        }
    }
    
    private func timeUp() {
        timer?.invalidate()
        if !isQuizCompleted {
            completeQuiz()
        }
    }
    
    // MARK: - Helper Methods
    
    var currentQuestion: QuizQuestion? {
        guard let quiz = currentQuiz,
              currentQuestionIndex < quiz.questions.count else { return nil }
        return quiz.questions[currentQuestionIndex]
    }
    
    var progressPercentage: Double {
        guard let quiz = currentQuiz else { return 0 }
        return Double(currentQuestionIndex + 1) / Double(quiz.questions.count)
    }
    
    var timeRemainingFormatted: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var scorePercentage: Double {
        guard let quiz = currentQuiz else { return 0 }
        let totalPoints = quiz.questions.reduce(0) { $0 + $1.points }
        return totalPoints > 0 ? Double(score) / Double(totalPoints) * 100 : 0
    }
    
    var performanceMessage: String {
        let percentage = scorePercentage
        switch percentage {
        case 90...100:
            return "Outstanding! 🌟"
        case 80..<90:
            return "Excellent work! 🎉"
        case 70..<80:
            return "Good job! 👏"
        case 60..<70:
            return "Not bad! Keep learning! 📚"
        default:
            return "Keep practicing! You'll improve! 💪"
        }
    }
    
    func resetQuiz() {
        timer?.invalidate()
        currentQuiz = nil
        currentQuestionIndex = 0
        selectedAnswerIndex = nil
        showAnswer = false
        isQuizCompleted = false
        quizResult = nil
        userAnswers = []
        score = 0
        showExplanation = false
        timeRemaining = 0
        quizStartTime = nil
    }
    
    deinit {
        timer?.invalidate()
    }
}


