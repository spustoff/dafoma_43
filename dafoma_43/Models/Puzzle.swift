//
//  Puzzle.swift
//  QuizzleQuest Road
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation

struct Puzzle: Identifiable, Codable {
    let id = UUID()
    let title: String
    let type: PuzzleType
    let difficulty: DifficultyLevel
    let description: String
    let timeLimit: TimeInterval?
    let data: PuzzleData
    let hints: [String]
    let solution: String
}

enum PuzzleType: String, CaseIterable, Codable {
    case wordScramble = "Word Scramble"
    case numberSequence = "Number Sequence"
    case logicGrid = "Logic Grid"
    case riddle = "Riddle"
    case pattern = "Pattern Recognition"
    case memory = "Memory Challenge"
    
    var icon: String {
        switch self {
        case .wordScramble: return "textformat.abc"
        case .numberSequence: return "number"
        case .logicGrid: return "grid"
        case .riddle: return "questionmark.circle"
        case .pattern: return "square.grid.3x3"
        case .memory: return "brain.head.profile"
        }
    }
    
    var description: String {
        switch self {
        case .wordScramble: return "Unscramble letters to form words"
        case .numberSequence: return "Find the pattern in number sequences"
        case .logicGrid: return "Solve logic puzzles using grids"
        case .riddle: return "Think creatively to solve riddles"
        case .pattern: return "Identify patterns in sequences"
        case .memory: return "Test your memory with challenges"
        }
    }
}

struct PuzzleData: Codable {
    let content: String
    let options: [String]?
    let grid: [[String]]?
    let sequence: [Int]?
    let targetWord: String?
    let scrambledLetters: [String]?
}

struct PuzzleResult: Identifiable, Codable {
    let id = UUID()
    let puzzleId: UUID
    let isCorrect: Bool
    let timeSpent: TimeInterval
    let hintsUsed: Int
    let completedAt: Date
    let userAnswer: String
}

struct PuzzleProgress: Codable {
    var totalPuzzlesCompleted: Int = 0
    var totalPuzzlesSolved: Int = 0
    var averageTime: TimeInterval = 0
    var bestTime: TimeInterval = 0
    var typeProgress: [PuzzleType: PuzzleTypeProgress] = [:]
    var dailyStreak: Int = 0
    var lastPuzzleDate: Date?
}

struct PuzzleTypeProgress: Codable {
    var completed: Int = 0
    var solved: Int = 0
    var averageHints: Double = 0.0
    var bestTime: TimeInterval = 0
    var currentDifficulty: DifficultyLevel = .beginner
}

struct DailyChallenge: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let puzzle: Puzzle
    let quiz: Quiz
    let bonusMultiplier: Double
    let isCompleted: Bool
}

struct BrainTeaser: Identifiable, Codable {
    let id = UUID()
    let title: String
    let content: String
    let category: BrainTeaserCategory
    let difficulty: DifficultyLevel
    let estimatedTime: TimeInterval
    let tips: [String]
}

enum BrainTeaserCategory: String, CaseIterable, Codable {
    case lateral = "Lateral Thinking"
    case mathematical = "Mathematical"
    case verbal = "Verbal"
    case spatial = "Spatial"
    case logical = "Logical"
    
    var icon: String {
        switch self {
        case .lateral: return "lightbulb"
        case .mathematical: return "plus.forwardslash.minus"
        case .verbal: return "text.bubble"
        case .spatial: return "cube"
        case .logical: return "gearshape.2"
        }
    }
}

