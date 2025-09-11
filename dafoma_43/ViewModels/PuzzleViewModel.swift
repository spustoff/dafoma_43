//
//  PuzzleViewModel.swift
//  QuizzleQuest Road
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation
import SwiftUI

class PuzzleViewModel: ObservableObject {
    @Published var currentPuzzle: Puzzle?
    @Published var userAnswer = ""
    @Published var scrambledLetters: [String] = []
    @Published var selectedLetters: [String] = []
    @Published var showHint = false
    @Published var currentHintIndex = 0
    @Published var isPuzzleCompleted = false
    @Published var puzzleResult: PuzzleResult?
    @Published var showSolution = false
    @Published var timeRemaining: TimeInterval = 0
    @Published var isTimerActive = false
    @Published var showMemorySequence = false
    @Published var memoryPhase: MemoryPhase = .showing
    
    private var timer: Timer?
    private var puzzleStartTime: Date?
    private let puzzleService: PuzzleService
    
    enum MemoryPhase {
        case showing
        case hidden
        case answering
    }
    
    init(puzzleService: PuzzleService = PuzzleService()) {
        self.puzzleService = puzzleService
    }
    
    // MARK: - Puzzle Management
    
    func startPuzzle(_ puzzle: Puzzle) {
        currentPuzzle = puzzle
        userAnswer = ""
        showHint = false
        currentHintIndex = 0
        isPuzzleCompleted = false
        puzzleResult = nil
        showSolution = false
        puzzleStartTime = Date()
        
        setupPuzzleSpecifics(for: puzzle)
        
        if let timeLimit = puzzle.timeLimit {
            timeRemaining = timeLimit
            isTimerActive = true
            startTimer()
        }
    }
    
    private func setupPuzzleSpecifics(for puzzle: Puzzle) {
        switch puzzle.type {
        case .wordScramble:
            if let letters = puzzle.data.scrambledLetters {
                scrambledLetters = letters.shuffled()
                selectedLetters = []
            }
            
        case .memory:
            showMemorySequence = true
            memoryPhase = .showing
            
            // Show sequence for 3 seconds, then hide
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.memoryPhase = .hidden
                
                // Wait 1 second, then allow answering
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.memoryPhase = .answering
                    self.showMemorySequence = false
                }
            }
            
        default:
            break
        }
    }
    
    // MARK: - Answer Submission
    
    func submitAnswer() {
        guard let puzzle = currentPuzzle,
              let startTime = puzzleStartTime else { return }
        
        let timeSpent = Date().timeIntervalSince(startTime)
        let isCorrect = checkAnswer()
        
        puzzleResult = PuzzleResult(
            puzzleId: puzzle.id,
            isCorrect: isCorrect,
            timeSpent: timeSpent,
            hintsUsed: showHint ? currentHintIndex + 1 : 0,
            completedAt: Date(),
            userAnswer: userAnswer
        )
        
        isPuzzleCompleted = true
        timer?.invalidate()
        isTimerActive = false
        
        if let result = puzzleResult {
            puzzleService.submitPuzzleResult(result)
        }
        
        if !isCorrect {
            // Show solution after 2 seconds for incorrect answers
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.showSolution = true
            }
        }
    }
    
    private func checkAnswer() -> Bool {
        guard let puzzle = currentPuzzle else { return false }
        
        let userAnswerTrimmed = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let correctAnswer = puzzle.solution.lowercased()
        
        switch puzzle.type {
        case .wordScramble:
            return userAnswerTrimmed == correctAnswer
        case .numberSequence, .pattern:
            return userAnswerTrimmed == correctAnswer
        case .riddle:
            return userAnswerTrimmed == correctAnswer
        case .logicGrid:
            return userAnswerTrimmed == correctAnswer
        case .memory:
            return userAnswerTrimmed == correctAnswer
        }
    }
    
    // MARK: - Word Scramble Specific
    
    func addLetter(_ letter: String) {
        guard currentPuzzle?.type == .wordScramble else { return }
        
        if let index = scrambledLetters.firstIndex(of: letter) {
            scrambledLetters.remove(at: index)
            selectedLetters.append(letter)
            userAnswer = selectedLetters.joined()
        }
    }
    
    func removeLetter(_ letter: String) {
        guard currentPuzzle?.type == .wordScramble else { return }
        
        if let index = selectedLetters.lastIndex(of: letter) {
            selectedLetters.remove(at: index)
            scrambledLetters.append(letter)
            userAnswer = selectedLetters.joined()
        }
    }
    
    func clearWord() {
        guard currentPuzzle?.type == .wordScramble else { return }
        
        scrambledLetters.append(contentsOf: selectedLetters)
        selectedLetters.removeAll()
        userAnswer = ""
    }
    
    func shuffleLetters() {
        guard currentPuzzle?.type == .wordScramble else { return }
        scrambledLetters.shuffle()
    }
    
    // MARK: - Hint Management
    
    func showNextHint() {
        guard let puzzle = currentPuzzle,
              currentHintIndex < puzzle.hints.count - 1 else { return }
        
        currentHintIndex += 1
        showHint = true
    }
    
    func toggleHint() {
        showHint.toggle()
    }
    
    var currentHint: String? {
        guard let puzzle = currentPuzzle,
              showHint,
              currentHintIndex < puzzle.hints.count else { return nil }
        return puzzle.hints[currentHintIndex]
    }
    
    var hasMoreHints: Bool {
        guard let puzzle = currentPuzzle else { return false }
        return currentHintIndex < puzzle.hints.count - 1
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
        isTimerActive = false
        
        if !isPuzzleCompleted {
            // Auto-submit with current answer when time runs out
            submitAnswer()
        }
    }
    
    // MARK: - Helper Methods
    
    var timeRemainingFormatted: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var difficultyColor: Color {
        guard let puzzle = currentPuzzle else { return .gray }
        
        switch puzzle.difficulty {
        case .beginner:
            return .green
        case .intermediate:
            return .orange
        case .advanced:
            return .red
        case .expert:
            return .purple
        }
    }
    
    var performanceMessage: String {
        guard let result = puzzleResult else { return "" }
        
        if result.isCorrect {
            let hintsUsed = result.hintsUsed
            switch hintsUsed {
            case 0:
                return "Perfect! No hints needed! 🌟"
            case 1:
                return "Great job! 🎉"
            case 2:
                return "Good work! 👏"
            default:
                return "Well done! Keep practicing! 💪"
            }
        } else {
            return "Don't give up! Try again! 🔄"
        }
    }
    
    var memorySequenceText: String {
        guard let puzzle = currentPuzzle,
              puzzle.type == .memory else { return "" }
        
        if let sequence = puzzle.data.sequence {
            return sequence.map(String.init).joined(separator: ", ")
        }
        return puzzle.data.content
    }
    
    func resetPuzzle() {
        timer?.invalidate()
        currentPuzzle = nil
        userAnswer = ""
        scrambledLetters = []
        selectedLetters = []
        showHint = false
        currentHintIndex = 0
        isPuzzleCompleted = false
        puzzleResult = nil
        showSolution = false
        timeRemaining = 0
        isTimerActive = false
        showMemorySequence = false
        memoryPhase = .showing
        puzzleStartTime = nil
    }
    
    deinit {
        timer?.invalidate()
    }
}

