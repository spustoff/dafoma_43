//
//  SettingsView.swift
//  QuizzleQuest Road
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @StateObject private var quizService = QuizService()
    @StateObject private var puzzleService = PuzzleService()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled = true
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @State private var showingResetAlert = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // User Progress Section
                        ProgressSummaryView(
                            quizProgress: quizService.userProgress,
                            puzzleProgress: puzzleService.puzzleProgress
                        )
                        
                        // Settings Sections
                        VStack(spacing: 15) {
                            // Notifications Section
                            SettingsSection(title: "Notifications", icon: "bell") {
                                SettingsToggle(
                                    title: "Daily Reminders",
                                    description: "Get notified about daily challenges",
                                    isOn: $notificationsEnabled
                                ) {
                                    toggleNotifications()
                                }
                            }
                            
                            // Audio & Haptics Section
                            SettingsSection(title: "Audio & Haptics", icon: "speaker.wave.2") {
                                SettingsToggle(
                                    title: "Sound Effects",
                                    description: "Play sounds for interactions",
                                    isOn: $soundEffectsEnabled
                                )
                                
                                SettingsToggle(
                                    title: "Haptic Feedback",
                                    description: "Feel vibrations for interactions",
                                    isOn: $hapticFeedbackEnabled
                                )
                            }
                            
                            // Data Section
                            SettingsSection(title: "Data", icon: "chart.bar") {
                                NavigationLink(destination: StatisticsView(
                                    quizProgress: quizService.userProgress,
                                    puzzleProgress: puzzleService.puzzleProgress
                                )) {
                                    SettingsRow(
                                        title: "View Statistics",
                                        description: "See your detailed progress",
                                        icon: "chart.line.uptrend.xyaxis",
                                        showChevron: true
                                    )
                                }
                                
                                Button(action: { showingResetAlert = true }) {
                                    SettingsRow(
                                        title: "Reset Progress",
                                        description: "Clear all data and start fresh",
                                        icon: "trash",
                                        showChevron: false,
                                        isDestructive: true
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            // App Section
                            SettingsSection(title: "App", icon: "gear") {
                                Button(action: { hasCompletedOnboarding = false }) {
                                    SettingsRow(
                                        title: "Show Onboarding",
                                        description: "Replay the welcome tutorial",
                                        icon: "play.circle",
                                        showChevron: false
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: { showingAbout = true }) {
                                    SettingsRow(
                                        title: "About",
                                        description: "App information and credits",
                                        icon: "info.circle",
                                        showChevron: true
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        // App Version
                        VStack(spacing: 5) {
                            Text("QuizzleQuest Road")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("Version 1.0.0")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 30)
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Reset All Progress", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will permanently delete all your quiz and puzzle progress. This action cannot be undone.")
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
    
    private func toggleNotifications() {
        if notificationsEnabled {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                DispatchQueue.main.async {
                    if !granted {
                        notificationsEnabled = false
                    }
                }
            }
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
    
    private func resetAllData() {
        // Reset quiz progress
        quizService.userProgress = UserProgress()
        
        // Reset puzzle progress
        puzzleService.puzzleProgress = PuzzleProgress()
        
        // Reset onboarding
        hasCompletedOnboarding = false
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "userProgress")
        UserDefaults.standard.removeObject(forKey: "puzzleProgress")
        UserDefaults.standard.removeObject(forKey: "dailyChallenge")
    }
}

struct ProgressSummaryView: View {
    let quizProgress: UserProgress
    let puzzleProgress: PuzzleProgress
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Your Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
            }
            
            HStack(spacing: 15) {
                ProgressCard(
                    title: "Quizzes",
                    value: "\(quizProgress.totalQuizzesCompleted)",
                    subtitle: "Completed",
                    icon: "questionmark.circle.fill",
                    color: Color("ButtonColor")
                )
                
                ProgressCard(
                    title: "Puzzles",
                    value: "\(puzzleProgress.totalPuzzlesSolved)",
                    subtitle: "Solved",
                    icon: "puzzlepiece.extension.fill",
                    color: Color("SuccessColor")
                )
            }
            
            HStack(spacing: 15) {
                ProgressCard(
                    title: "Streak",
                    value: "\(quizProgress.streakDays)",
                    subtitle: "Days",
                    icon: "flame.fill",
                    color: .orange
                )
                
                ProgressCard(
                    title: "Score",
                    value: "\(quizProgress.totalScore)",
                    subtitle: "Points",
                    icon: "star.fill",
                    color: .yellow
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
}

struct ProgressCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 2) {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color("ButtonColor"))
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal)
            
            VStack(spacing: 1) {
                content
            }
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct SettingsToggle: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    let action: (() -> Void)?
    
    init(title: String, description: String, isOn: Binding<Bool>, action: (() -> Void)? = nil) {
        self.title = title
        self.description = description
        self._isOn = isOn
        self.action = action
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color("ButtonColor"))
                .onChange(of: isOn) { _ in
                    action?()
                }
        }
        .padding()
    }
}

struct SettingsRow: View {
    let title: String
    let description: String
    let icon: String
    let showChevron: Bool
    let isDestructive: Bool
    
    init(title: String, description: String, icon: String, showChevron: Bool, isDestructive: Bool = false) {
        self.title = title
        self.description = description
        self.icon = icon
        self.showChevron = showChevron
        self.isDestructive = isDestructive
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isDestructive ? .red : Color("ButtonColor"))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(isDestructive ? .red : .white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(isDestructive ? .red.opacity(0.7) : .white.opacity(0.7))
            }
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding()
    }
}

struct StatisticsView: View {
    let quizProgress: UserProgress
    let puzzleProgress: PuzzleProgress
    
    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Quiz Statistics
                    StatisticsSection(title: "Quiz Statistics", icon: "questionmark.circle") {
                        StatisticRow(label: "Total Completed", value: "\(quizProgress.totalQuizzesCompleted)")
                        StatisticRow(label: "Total Score", value: "\(quizProgress.totalScore) points")
                        StatisticRow(label: "Current Streak", value: "\(quizProgress.streakDays) days")
                        StatisticRow(label: "Achievements", value: "\(quizProgress.achievements.count)")
                    }
                    
                    // Puzzle Statistics
                    StatisticsSection(title: "Puzzle Statistics", icon: "puzzlepiece.extension") {
                        StatisticRow(label: "Total Completed", value: "\(puzzleProgress.totalPuzzlesCompleted)")
                        StatisticRow(label: "Total Solved", value: "\(puzzleProgress.totalPuzzlesSolved)")
                        StatisticRow(label: "Success Rate", value: String(format: "%.1f%%", puzzleProgress.totalPuzzlesCompleted > 0 ? Double(puzzleProgress.totalPuzzlesSolved) / Double(puzzleProgress.totalPuzzlesCompleted) * 100 : 0))
                        StatisticRow(label: "Average Time", value: timeString(puzzleProgress.averageTime))
                    }
                    
                    // Category Progress
                    if !quizProgress.categoryProgress.isEmpty {
                        StatisticsSection(title: "Category Progress", icon: "chart.bar") {
                            ForEach(Array(quizProgress.categoryProgress.keys), id: \.self) { category in
                                if let progress = quizProgress.categoryProgress[category] {
                                    CategoryProgressRow(category: category, progress: progress)
                                }
                            }
                        }
                    }
                    
                    // Recent Achievements
                    if !quizProgress.achievements.isEmpty {
                        StatisticsSection(title: "Recent Achievements", icon: "trophy") {
                            ForEach(quizProgress.achievements.prefix(5)) { achievement in
                                AchievementRow(achievement: achievement)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func timeString(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct StatisticsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color("ButtonColor"))
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
            }
            
            VStack(spacing: 8) {
                content
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct StatisticRow: View {
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

struct CategoryProgressRow: View {
    let category: QuizCategory
    let progress: CategoryProgress
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(Color("ButtonColor"))
                Text(category.rawValue)
                    .foregroundColor(.white)
                Spacer()
                Text("\(progress.quizzesCompleted) completed")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            HStack {
                Text("Average: \(String(format: "%.1f%%", progress.averageScore))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Text("Best: \(progress.bestScore) pts")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

struct AchievementRow: View {
    let achievement: Achievement
    
    var body: some View {
        HStack {
            Image(systemName: achievement.icon)
                .font(.title3)
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.body)
                    .foregroundColor(.white)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text(DateFormatter.shortDate.string(from: achievement.unlockedAt))
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // App Icon and Title
                        VStack(spacing: 15) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 80))
                                .foregroundColor(Color("ButtonColor"))
                            
                            Text("QuizzleQuest Road")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Version 1.0.0")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 15) {
                            Text("About")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("QuizzleQuest Road is an innovative iOS app that combines interactive quizzes and brain-teasing puzzles to provide an engaging educational experience. Challenge yourself across various topics while tracking your progress and achievements.")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Features
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Features")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                FeatureRow(icon: "questionmark.circle", text: "Dynamic Quiz Challenges")
                                FeatureRow(icon: "puzzlepiece.extension", text: "Unique Puzzle Games")
                                FeatureRow(icon: "bell.badge", text: "Daily Brain Teasers")
                                FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Progress Tracking")
                                FeatureRow(icon: "trophy", text: "Achievement System")
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Credits
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Credits")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Developed with SwiftUI following Apple Human Interface Guidelines. Built for iOS 15.6 and later.")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding()
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color("ButtonColor"))
                .frame(width: 20)
            
            Text(text)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}

#Preview {
    SettingsView()
}
