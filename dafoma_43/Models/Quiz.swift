//
//  Quiz.swift
//  QuizzleQuest Road
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation

struct Quiz: Identifiable, Codable {
    let id = UUID()
    let title: String
    let category: QuizCategory
    let difficulty: DifficultyLevel
    let questions: [QuizQuestion]
    let timeLimit: TimeInterval
    let description: String
}

struct QuizQuestion: Identifiable, Codable {
    let id = UUID()
    let question: String
    let options: [String]
    let correctAnswerIndex: Int
    let explanation: String
    let points: Int
}

enum QuizCategory: String, CaseIterable, Codable {
    case history = "History"
    case science = "Science"
    case technology = "Technology"
    case geography = "Geography"
    case literature = "Literature"
    case mathematics = "Mathematics"
    
    var icon: String {
        switch self {
        case .history: return "clock"
        case .science: return "atom"
        case .technology: return "laptopcomputer"
        case .geography: return "globe"
        case .literature: return "book"
        case .mathematics: return "function"
        }
    }
    
    var color: String {
        switch self {
        case .history: return "HistoryColor"
        case .science: return "ScienceColor"
        case .technology: return "TechnologyColor"
        case .geography: return "GeographyColor"
        case .literature: return "LiteratureColor"
        case .mathematics: return "MathematicsColor"
        }
    }
}

enum DifficultyLevel: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"
    
    var multiplier: Double {
        switch self {
        case .beginner: return 1.0
        case .intermediate: return 1.5
        case .advanced: return 2.0
        case .expert: return 3.0
        }
    }
    
    var color: String {
        switch self {
        case .beginner: return "BeginnerColor"
        case .intermediate: return "IntermediateColor"
        case .advanced: return "AdvancedColor"
        case .expert: return "ExpertColor"
        }
    }
}

struct QuizResult: Identifiable, Codable {
    let id = UUID()
    let quizId: UUID
    let score: Int
    let totalQuestions: Int
    let timeSpent: TimeInterval
    let completedAt: Date
    let correctAnswers: [Int]
}

struct UserProgress: Codable {
    var totalQuizzesCompleted: Int = 0
    var totalScore: Int = 0
    var streakDays: Int = 0
    var lastPlayedDate: Date?
    var categoryProgress: [QuizCategory: CategoryProgress] = [:]
    var achievements: [Achievement] = []
}

struct CategoryProgress: Codable {
    var quizzesCompleted: Int = 0
    var averageScore: Double = 0.0
    var bestScore: Int = 0
    var currentLevel: DifficultyLevel = .beginner
}

struct Achievement: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let unlockedAt: Date
    let category: AchievementCategory
}

enum AchievementCategory: String, CaseIterable, Codable {
    case streak = "Streak"
    case mastery = "Mastery"
    case explorer = "Explorer"
    case speed = "Speed"
}


