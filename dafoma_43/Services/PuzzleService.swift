//
//  PuzzleService.swift
//  QuizzleQuest Road
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation

class PuzzleService: ObservableObject {
    @Published var availablePuzzles: [Puzzle] = []
    @Published var puzzleProgress: PuzzleProgress = PuzzleProgress()
    @Published var dailyBrainTeasers: [BrainTeaser] = []
    
    private let userDefaults = UserDefaults.standard
    private let progressKey = "puzzleProgress"
    
    init() {
        loadPuzzleProgress()
        generatePuzzles()
        generateDailyBrainTeasers()
    }
    
    // MARK: - Puzzle Management
    
    func generatePuzzles() {
        availablePuzzles = [
            createWordScramblePuzzles(),
            createNumberSequencePuzzles(),
            createLogicGridPuzzles(),
            createRiddlePuzzles(),
            createPatternPuzzles(),
            createMemoryPuzzles()
        ].flatMap { $0 }
    }
    
    func getPuzzlesByType(_ type: PuzzleType) -> [Puzzle] {
        return availablePuzzles.filter { $0.type == type }
    }
    
    func getPuzzlesByDifficulty(_ difficulty: DifficultyLevel) -> [Puzzle] {
        return availablePuzzles.filter { $0.difficulty == difficulty }
    }
    
    func getRecommendedPuzzles() -> [Puzzle] {
        let userLevel = determineUserLevel()
        return availablePuzzles.filter { $0.difficulty == userLevel }.shuffled().prefix(4).map { $0 }
    }
    
    func generateRandomPuzzle() -> Puzzle {
        return availablePuzzles.randomElement() ?? createWordScramblePuzzles().first!
    }
    
    // MARK: - Puzzle Results
    
    func submitPuzzleResult(_ result: PuzzleResult) {
        updatePuzzleProgress(with: result)
        savePuzzleProgress()
    }
    
    private func updatePuzzleProgress(with result: PuzzleResult) {
        puzzleProgress.totalPuzzlesCompleted += 1
        
        if result.isCorrect {
            puzzleProgress.totalPuzzlesSolved += 1
        }
        
        // Update average time
        let totalTime = puzzleProgress.averageTime * Double(puzzleProgress.totalPuzzlesCompleted - 1) + result.timeSpent
        puzzleProgress.averageTime = totalTime / Double(puzzleProgress.totalPuzzlesCompleted)
        
        // Update best time if correct
        if result.isCorrect && (puzzleProgress.bestTime == 0 || result.timeSpent < puzzleProgress.bestTime) {
            puzzleProgress.bestTime = result.timeSpent
        }
        
        // Update type-specific progress
        if let puzzle = availablePuzzles.first(where: { $0.id == result.puzzleId }) {
            updateTypeProgress(for: puzzle.type, with: result)
        }
        
        updatePuzzleStreak()
    }
    
    private func updateTypeProgress(for type: PuzzleType, with result: PuzzleResult) {
        var typeProgress = puzzleProgress.typeProgress[type] ?? PuzzleTypeProgress()
        
        typeProgress.completed += 1
        if result.isCorrect {
            typeProgress.solved += 1
        }
        
        // Update average hints
        let totalHints = typeProgress.averageHints * Double(typeProgress.completed - 1) + Double(result.hintsUsed)
        typeProgress.averageHints = totalHints / Double(typeProgress.completed)
        
        // Update best time for this type
        if result.isCorrect && (typeProgress.bestTime == 0 || result.timeSpent < typeProgress.bestTime) {
            typeProgress.bestTime = result.timeSpent
        }
        
        // Level up logic for puzzle types
        let successRate = Double(typeProgress.solved) / Double(typeProgress.completed)
        if successRate > 0.8 && typeProgress.completed >= 5 {
            typeProgress.currentDifficulty = getNextLevel(typeProgress.currentDifficulty)
        }
        
        puzzleProgress.typeProgress[type] = typeProgress
    }
    
    private func updatePuzzleStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastPuzzleDate = puzzleProgress.lastPuzzleDate {
            let lastPuzzleDay = Calendar.current.startOfDay(for: lastPuzzleDate)
            let daysBetween = Calendar.current.dateComponents([.day], from: lastPuzzleDay, to: today).day ?? 0
            
            if daysBetween == 1 {
                puzzleProgress.dailyStreak += 1
            } else if daysBetween > 1 {
                puzzleProgress.dailyStreak = 1
            }
        } else {
            puzzleProgress.dailyStreak = 1
        }
        
        puzzleProgress.lastPuzzleDate = Date()
    }
    
    // MARK: - Daily Brain Teasers
    
    func generateDailyBrainTeasers() {
        dailyBrainTeasers = [
            BrainTeaser(
                title: "The Missing Number",
                content: "What comes next in this sequence: 2, 6, 12, 20, 30, ?",
                category: .mathematical,
                difficulty: .intermediate,
                estimatedTime: 120,
                tips: ["Look at the differences between consecutive numbers", "Consider the pattern in the differences"]
            ),
            BrainTeaser(
                title: "The Logical Door",
                content: "You have two doors. One leads to freedom, one to danger. There are two guards: one always tells the truth, one always lies. You can ask one question to one guard. What do you ask?",
                category: .logical,
                difficulty: .advanced,
                estimatedTime: 300,
                tips: ["Think about what question would give you the same answer from both guards", "Consider asking about what the other guard would say"]
            ),
            BrainTeaser(
                title: "Word Transformation",
                content: "Change COLD to WARM in 4 steps, changing one letter at a time, with each step being a valid word.",
                category: .verbal,
                difficulty: .intermediate,
                estimatedTime: 180,
                tips: ["Think of intermediate words", "Consider common 4-letter words"]
            )
        ]
    }
    
    // MARK: - Data Persistence
    
    private func loadPuzzleProgress() {
        if let data = userDefaults.data(forKey: progressKey),
           let progress = try? JSONDecoder().decode(PuzzleProgress.self, from: data) {
            puzzleProgress = progress
        }
    }
    
    private func savePuzzleProgress() {
        if let data = try? JSONEncoder().encode(puzzleProgress) {
            userDefaults.set(data, forKey: progressKey)
        }
    }
    
    // MARK: - Helper Methods
    
    private func determineUserLevel() -> DifficultyLevel {
        let successRate = puzzleProgress.totalPuzzlesCompleted > 0 ? 
            Double(puzzleProgress.totalPuzzlesSolved) / Double(puzzleProgress.totalPuzzlesCompleted) : 0.0
        
        if puzzleProgress.totalPuzzlesCompleted < 3 {
            return .beginner
        } else if successRate > 0.8 && puzzleProgress.totalPuzzlesCompleted >= 10 {
            return .advanced
        } else if successRate > 0.6 {
            return .intermediate
        } else {
            return .beginner
        }
    }
    
    private func getNextLevel(_ currentLevel: DifficultyLevel) -> DifficultyLevel {
        switch currentLevel {
        case .beginner: return .intermediate
        case .intermediate: return .advanced
        case .advanced: return .expert
        case .expert: return .expert
        }
    }
}

// MARK: - Puzzle Generation Methods

extension PuzzleService {
    private func createWordScramblePuzzles() -> [Puzzle] {
        return [
            Puzzle(
                title: "Animal Scramble",
                type: .wordScramble,
                difficulty: .beginner,
                description: "Unscramble these letters to form an animal name",
                timeLimit: 60,
                data: PuzzleData(
                    content: "TELNHAPE",
                    options: ["ELEPHANT", "LEOPARD", "PANTHER", "ANTELOPE"],
                    grid: nil,
                    sequence: nil,
                    targetWord: "ELEPHANT",
                    scrambledLetters: ["E", "L", "E", "P", "H", "A", "N", "T"]
                ),
                hints: ["It's a large mammal", "It has a trunk", "Found in Africa and Asia"],
                solution: "ELEPHANT"
            ),
            Puzzle(
                title: "Technology Terms",
                type: .wordScramble,
                difficulty: .intermediate,
                description: "Unscramble this technology-related word",
                timeLimit: 90,
                data: PuzzleData(
                    content: "MHTIROGLA",
                    options: ["ALGORITHM", "LOGARITHM", "RHYTHMIC", "MAGNETIC"],
                    grid: nil,
                    sequence: nil,
                    targetWord: "ALGORITHM",
                    scrambledLetters: ["A", "L", "G", "O", "R", "I", "T", "H", "M"]
                ),
                hints: ["Used in computer science", "A set of rules or instructions", "Essential for programming"],
                solution: "ALGORITHM"
            )
        ]
    }
    
    private func createNumberSequencePuzzles() -> [Puzzle] {
        return [
            Puzzle(
                title: "Fibonacci Sequence",
                type: .numberSequence,
                difficulty: .intermediate,
                description: "Find the next number in the sequence",
                timeLimit: 120,
                data: PuzzleData(
                    content: "1, 1, 2, 3, 5, 8, 13, ?",
                    options: ["20", "21", "22", "23"],
                    grid: nil,
                    sequence: [1, 1, 2, 3, 5, 8, 13],
                    targetWord: nil,
                    scrambledLetters: nil
                ),
                hints: ["Each number is the sum of the two preceding ones", "This is a famous mathematical sequence", "Named after an Italian mathematician"],
                solution: "21"
            ),
            Puzzle(
                title: "Square Numbers",
                type: .numberSequence,
                difficulty: .beginner,
                description: "Identify the pattern in these numbers",
                timeLimit: 90,
                data: PuzzleData(
                    content: "1, 4, 9, 16, 25, ?",
                    options: ["30", "32", "36", "40"],
                    grid: nil,
                    sequence: [1, 4, 9, 16, 25],
                    targetWord: nil,
                    scrambledLetters: nil
                ),
                hints: ["These are perfect squares", "1×1, 2×2, 3×3, etc.", "What's 6×6?"],
                solution: "36"
            )
        ]
    }
    
    private func createLogicGridPuzzles() -> [Puzzle] {
        return [
            Puzzle(
                title: "Color Logic",
                type: .logicGrid,
                difficulty: .intermediate,
                description: "Use logic to determine the correct arrangement",
                timeLimit: 300,
                data: PuzzleData(
                    content: "Three friends (Alice, Bob, Carol) each have a different favorite color (Red, Blue, Green). Alice doesn't like Red. Bob's favorite isn't Blue. Carol doesn't like Green. What color does each person like?",
                    options: ["Alice-Blue, Bob-Green, Carol-Red", "Alice-Green, Bob-Red, Carol-Blue", "Alice-Red, Bob-Blue, Carol-Green", "Alice-Blue, Bob-Red, Carol-Green"],
                    grid: [["Alice", "Bob", "Carol"], ["Red", "Blue", "Green"]],
                    sequence: nil,
                    targetWord: nil,
                    scrambledLetters: nil
                ),
                hints: ["Use process of elimination", "If Alice doesn't like Red, what are her options?", "Work through each constraint systematically"],
                solution: "Alice-Blue, Bob-Green, Carol-Red"
            )
        ]
    }
    
    private func createRiddlePuzzles() -> [Puzzle] {
        return [
            Puzzle(
                title: "The Silent Speaker",
                type: .riddle,
                difficulty: .intermediate,
                description: "Think outside the box to solve this riddle",
                timeLimit: 180,
                data: PuzzleData(
                    content: "I speak without a mouth and hear without ears. I have no body, but come alive with wind. What am I?",
                    options: ["Echo", "Shadow", "Mirror", "Thought"],
                    grid: nil,
                    sequence: nil,
                    targetWord: nil,
                    scrambledLetters: nil
                ),
                hints: ["Think about sounds in nature", "It repeats what you say", "Found in mountains and empty buildings"],
                solution: "Echo"
            ),
            Puzzle(
                title: "The Growing Paradox",
                type: .riddle,
                difficulty: .advanced,
                description: "A classic riddle that challenges logic",
                timeLimit: 240,
                data: PuzzleData(
                    content: "The more you take away from me, the bigger I become. What am I?",
                    options: ["Hole", "Debt", "Problem", "Mystery"],
                    grid: nil,
                    sequence: nil,
                    targetWord: nil,
                    scrambledLetters: nil
                ),
                hints: ["Think about physical spaces", "Digging makes it larger", "Can be found in the ground"],
                solution: "Hole"
            )
        ]
    }
    
    private func createPatternPuzzles() -> [Puzzle] {
        return [
            Puzzle(
                title: "Shape Sequence",
                type: .pattern,
                difficulty: .beginner,
                description: "Identify the next shape in the pattern",
                timeLimit: 120,
                data: PuzzleData(
                    content: "Circle, Square, Triangle, Circle, Square, ?",
                    options: ["Triangle", "Circle", "Square", "Pentagon"],
                    grid: nil,
                    sequence: nil,
                    targetWord: nil,
                    scrambledLetters: nil
                ),
                hints: ["Look at the repeating sequence", "Count how many shapes repeat", "What comes after Square in the pattern?"],
                solution: "Triangle"
            )
        ]
    }
    
    private func createMemoryPuzzles() -> [Puzzle] {
        return [
            Puzzle(
                title: "Number Memory",
                type: .memory,
                difficulty: .beginner,
                description: "Remember the sequence of numbers",
                timeLimit: 30,
                data: PuzzleData(
                    content: "7, 3, 9, 1, 5, 2, 8",
                    options: ["7, 3, 9, 1, 5, 2, 8", "7, 3, 9, 1, 5, 8, 2", "3, 7, 9, 1, 5, 2, 8", "7, 3, 1, 9, 5, 2, 8"],
                    grid: nil,
                    sequence: [7, 3, 9, 1, 5, 2, 8],
                    targetWord: nil,
                    scrambledLetters: nil
                ),
                hints: ["Take your time to memorize", "Try to find patterns or group numbers", "Repeat the sequence in your mind"],
                solution: "7, 3, 9, 1, 5, 2, 8"
            )
        ]
    }
}

