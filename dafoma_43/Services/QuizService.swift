//
//  QuizService.swift
//  QuizzleQuest Road
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation
import UserNotifications

class QuizService: ObservableObject {
    @Published var availableQuizzes: [Quiz] = []
    @Published var userProgress: UserProgress = UserProgress()
    @Published var dailyChallenge: DailyChallenge?
    
    private let userDefaults = UserDefaults.standard
    private let progressKey = "userProgress"
    private let dailyChallengeKey = "dailyChallenge"
    
    init() {
        loadUserProgress()
        loadDailyChallenge()
        generateQuizzes()
        scheduleNotifications()
    }
    
    // MARK: - Quiz Management
    
    func generateQuizzes() {
        availableQuizzes = [
            createHistoryQuiz(),
            createScienceQuiz(),
            createTechnologyQuiz(),
            createGeographyQuiz(),
            createLiteratureQuiz(),
            createMathematicsQuiz()
        ]
    }
    
    func getQuizzesByCategory(_ category: QuizCategory) -> [Quiz] {
        return availableQuizzes.filter { $0.category == category }
    }
    
    func getQuizzesByDifficulty(_ difficulty: DifficultyLevel) -> [Quiz] {
        return availableQuizzes.filter { $0.difficulty == difficulty }
    }
    
    func getRecommendedQuizzes() -> [Quiz] {
        // Return quizzes based on user's progress and preferences
        let userLevel = determineUserLevel()
        return availableQuizzes.filter { $0.difficulty == userLevel }.shuffled().prefix(3).map { $0 }
    }
    
    // MARK: - Quiz Results
    
    func submitQuizResult(_ result: QuizResult) {
        updateUserProgress(with: result)
        checkForAchievements(result)
        saveUserProgress()
    }
    
    private func updateUserProgress(with result: QuizResult) {
        userProgress.totalQuizzesCompleted += 1
        userProgress.totalScore += result.score
        
        if let quiz = availableQuizzes.first(where: { $0.id == result.quizId }) {
            var categoryProgress = userProgress.categoryProgress[quiz.category] ?? CategoryProgress()
            categoryProgress.quizzesCompleted += 1
            
            let newAverage = (categoryProgress.averageScore * Double(categoryProgress.quizzesCompleted - 1) + Double(result.score)) / Double(categoryProgress.quizzesCompleted)
            categoryProgress.averageScore = newAverage
            
            if result.score > categoryProgress.bestScore {
                categoryProgress.bestScore = result.score
            }
            
            // Level up logic
            if categoryProgress.averageScore > 80 && categoryProgress.quizzesCompleted >= 5 {
                categoryProgress.currentLevel = getNextLevel(categoryProgress.currentLevel)
            }
            
            userProgress.categoryProgress[quiz.category] = categoryProgress
        }
        
        updateStreak()
    }
    
    private func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastPlayed = userProgress.lastPlayedDate {
            let lastPlayedDay = Calendar.current.startOfDay(for: lastPlayed)
            let daysBetween = Calendar.current.dateComponents([.day], from: lastPlayedDay, to: today).day ?? 0
            
            if daysBetween == 1 {
                userProgress.streakDays += 1
            } else if daysBetween > 1 {
                userProgress.streakDays = 1
            }
        } else {
            userProgress.streakDays = 1
        }
        
        userProgress.lastPlayedDate = Date()
    }
    
    // MARK: - Daily Challenge
    
    func generateDailyChallenge() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let existingChallenge = dailyChallenge,
           Calendar.current.isDate(existingChallenge.date, inSameDayAs: today) {
            return // Already have today's challenge
        }
        
        let randomQuiz = availableQuizzes.randomElement()!
        let bonusMultiplier = Double.random(in: 1.5...2.5)
        
        dailyChallenge = DailyChallenge(
            date: today,
            puzzle: PuzzleService().generateRandomPuzzle(),
            quiz: randomQuiz,
            bonusMultiplier: bonusMultiplier,
            isCompleted: false
        )
        
        saveDailyChallenge()
    }
    
    // MARK: - Achievements
    
    private func checkForAchievements(_ result: QuizResult) {
        var newAchievements: [Achievement] = []
        
        // First quiz achievement
        if userProgress.totalQuizzesCompleted == 1 {
            newAchievements.append(Achievement(
                title: "First Steps",
                description: "Complete your first quiz",
                icon: "star.fill",
                unlockedAt: Date(),
                category: .explorer
            ))
        }
        
        // Streak achievements
        if userProgress.streakDays == 7 {
            newAchievements.append(Achievement(
                title: "Week Warrior",
                description: "Play for 7 days in a row",
                icon: "flame.fill",
                unlockedAt: Date(),
                category: .streak
            ))
        }
        
        // Perfect score achievement
        if result.score == result.totalQuestions * 100 {
            newAchievements.append(Achievement(
                title: "Perfect Score",
                description: "Get 100% on a quiz",
                icon: "crown.fill",
                unlockedAt: Date(),
                category: .mastery
            ))
        }
        
        userProgress.achievements.append(contentsOf: newAchievements)
    }
    
    // MARK: - Notifications
    
    private func scheduleNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                self.scheduleDailyReminder()
            }
        }
    }
    
    private func scheduleDailyReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Daily Brain Teaser"
        content.body = "Ready for today's challenge? Test your knowledge with QuizzleQuest!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 19 // 7 PM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Data Persistence
    
    private func loadUserProgress() {
        if let data = userDefaults.data(forKey: progressKey),
           let progress = try? JSONDecoder().decode(UserProgress.self, from: data) {
            userProgress = progress
        }
    }
    
    private func saveUserProgress() {
        if let data = try? JSONEncoder().encode(userProgress) {
            userDefaults.set(data, forKey: progressKey)
        }
    }
    
    private func loadDailyChallenge() {
        if let data = userDefaults.data(forKey: dailyChallengeKey),
           let challenge = try? JSONDecoder().decode(DailyChallenge.self, from: data) {
            dailyChallenge = challenge
        }
    }
    
    private func saveDailyChallenge() {
        if let challenge = dailyChallenge,
           let data = try? JSONEncoder().encode(challenge) {
            userDefaults.set(data, forKey: dailyChallengeKey)
        }
    }
    
    // MARK: - Helper Methods
    
    private func determineUserLevel() -> DifficultyLevel {
        if userProgress.totalQuizzesCompleted < 5 {
            return .beginner
        } else if userProgress.totalQuizzesCompleted < 15 {
            return .intermediate
        } else if userProgress.totalQuizzesCompleted < 30 {
            return .advanced
        } else {
            return .expert
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

// MARK: - Quiz Generation Methods

extension QuizService {
    private func createHistoryQuiz() -> Quiz {
        let questions = [
            QuizQuestion(
                question: "Which ancient civilization built Machu Picchu?",
                options: ["Aztecs", "Incas", "Mayans", "Olmecs"],
                correctAnswerIndex: 1,
                explanation: "Machu Picchu was built by the Inca civilization around 1450 AD in Peru.",
                points: 10
            ),
            QuizQuestion(
                question: "In which year did World War II end?",
                options: ["1944", "1945", "1946", "1947"],
                correctAnswerIndex: 1,
                explanation: "World War II ended in 1945 with the surrender of Japan in September.",
                points: 10
            ),
            QuizQuestion(
                question: "Who was the first person to walk on the moon?",
                options: ["Buzz Aldrin", "Neil Armstrong", "John Glenn", "Alan Shepard"],
                correctAnswerIndex: 1,
                explanation: "Neil Armstrong was the first person to walk on the moon on July 20, 1969.",
                points: 10
            )
        ]
        
        return Quiz(
            title: "Ancient Civilizations & Modern History",
            category: .history,
            difficulty: .intermediate,
            questions: questions,
            timeLimit: 300,
            description: "Test your knowledge of historical events and civilizations"
        )
    }
    
    private func createScienceQuiz() -> Quiz {
        let questions = [
            QuizQuestion(
                question: "What is the chemical symbol for gold?",
                options: ["Go", "Gd", "Au", "Ag"],
                correctAnswerIndex: 2,
                explanation: "Au comes from the Latin word 'aurum' meaning gold.",
                points: 10
            ),
            QuizQuestion(
                question: "How many bones are there in an adult human body?",
                options: ["206", "208", "210", "212"],
                correctAnswerIndex: 0,
                explanation: "An adult human body has 206 bones, while babies are born with about 270.",
                points: 10
            ),
            QuizQuestion(
                question: "What is the speed of light in a vacuum?",
                options: ["299,792,458 m/s", "300,000,000 m/s", "299,800,000 m/s", "298,000,000 m/s"],
                correctAnswerIndex: 0,
                explanation: "The speed of light in a vacuum is exactly 299,792,458 meters per second.",
                points: 15
            )
        ]
        
        return Quiz(
            title: "Science Fundamentals",
            category: .science,
            difficulty: .intermediate,
            questions: questions,
            timeLimit: 240,
            description: "Explore the fascinating world of science"
        )
    }
    
    private func createTechnologyQuiz() -> Quiz {
        let questions = [
            QuizQuestion(
                question: "What does 'HTTP' stand for?",
                options: ["HyperText Transfer Protocol", "High Tech Transfer Process", "Home Tool Transfer Protocol", "HyperText Technical Process"],
                correctAnswerIndex: 0,
                explanation: "HTTP stands for HyperText Transfer Protocol, used for transferring web pages.",
                points: 10
            ),
            QuizQuestion(
                question: "Which company developed the Swift programming language?",
                options: ["Google", "Microsoft", "Apple", "Facebook"],
                correctAnswerIndex: 2,
                explanation: "Swift was developed by Apple and introduced in 2014 for iOS and macOS development.",
                points: 10
            ),
            QuizQuestion(
                question: "What does 'AI' stand for in technology?",
                options: ["Automated Intelligence", "Artificial Intelligence", "Advanced Integration", "Algorithmic Interface"],
                correctAnswerIndex: 1,
                explanation: "AI stands for Artificial Intelligence, simulating human intelligence in machines.",
                points: 10
            )
        ]
        
        return Quiz(
            title: "Technology Essentials",
            category: .technology,
            difficulty: .beginner,
            questions: questions,
            timeLimit: 180,
            description: "Test your tech knowledge"
        )
    }
    
    private func createGeographyQuiz() -> Quiz {
        let questions = [
            QuizQuestion(
                question: "What is the capital of Australia?",
                options: ["Sydney", "Melbourne", "Canberra", "Perth"],
                correctAnswerIndex: 2,
                explanation: "Canberra is the capital city of Australia, located between Sydney and Melbourne.",
                points: 10
            ),
            QuizQuestion(
                question: "Which is the longest river in the world?",
                options: ["Amazon River", "Nile River", "Mississippi River", "Yangtze River"],
                correctAnswerIndex: 1,
                explanation: "The Nile River is the longest river in the world at approximately 6,650 kilometers.",
                points: 10
            ),
            QuizQuestion(
                question: "How many continents are there?",
                options: ["5", "6", "7", "8"],
                correctAnswerIndex: 2,
                explanation: "There are 7 continents: Asia, Africa, North America, South America, Antarctica, Europe, and Australia.",
                points: 10
            )
        ]
        
        return Quiz(
            title: "World Geography",
            category: .geography,
            difficulty: .beginner,
            questions: questions,
            timeLimit: 200,
            description: "Explore the world's geography"
        )
    }
    
    private func createLiteratureQuiz() -> Quiz {
        let questions = [
            QuizQuestion(
                question: "Who wrote 'Romeo and Juliet'?",
                options: ["Charles Dickens", "William Shakespeare", "Jane Austen", "Mark Twain"],
                correctAnswerIndex: 1,
                explanation: "Romeo and Juliet was written by William Shakespeare around 1594-1596.",
                points: 10
            ),
            QuizQuestion(
                question: "Which novel begins with 'It was the best of times, it was the worst of times'?",
                options: ["Great Expectations", "Oliver Twist", "A Tale of Two Cities", "David Copperfield"],
                correctAnswerIndex: 2,
                explanation: "This famous opening line is from 'A Tale of Two Cities' by Charles Dickens.",
                points: 15
            ),
            QuizQuestion(
                question: "Who wrote '1984'?",
                options: ["Aldous Huxley", "George Orwell", "Ray Bradbury", "Kurt Vonnegut"],
                correctAnswerIndex: 1,
                explanation: "1984 was written by George Orwell and published in 1949.",
                points: 10
            )
        ]
        
        return Quiz(
            title: "Classic Literature",
            category: .literature,
            difficulty: .intermediate,
            questions: questions,
            timeLimit: 250,
            description: "Test your knowledge of classic literature"
        )
    }
    
    private func createMathematicsQuiz() -> Quiz {
        let questions = [
            QuizQuestion(
                question: "What is the value of π (pi) to two decimal places?",
                options: ["3.14", "3.15", "3.16", "3.13"],
                correctAnswerIndex: 0,
                explanation: "π (pi) is approximately 3.14159, which rounds to 3.14 to two decimal places.",
                points: 10
            ),
            QuizQuestion(
                question: "What is 15% of 200?",
                options: ["25", "30", "35", "40"],
                correctAnswerIndex: 1,
                explanation: "15% of 200 = 0.15 × 200 = 30.",
                points: 10
            ),
            QuizQuestion(
                question: "What is the square root of 144?",
                options: ["11", "12", "13", "14"],
                correctAnswerIndex: 1,
                explanation: "The square root of 144 is 12, because 12 × 12 = 144.",
                points: 10
            )
        ]
        
        return Quiz(
            title: "Mathematics Basics",
            category: .mathematics,
            difficulty: .beginner,
            questions: questions,
            timeLimit: 180,
            description: "Test your mathematical skills"
        )
    }
}

