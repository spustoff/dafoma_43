//
//  ContentView.swift
//  QuizzleQuest Road
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab = 0
    
    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView()
        } else {
            TabView(selection: $selectedTab) {
                QuizView()
                    .tabItem {
                        Image(systemName: "questionmark.circle")
                        Text("Quizzes")
                    }
                    .tag(0)
                
                PuzzleView()
                    .tabItem {
                        Image(systemName: "puzzlepiece.extension")
                        Text("Puzzles")
                    }
                    .tag(1)
                
                DailyView()
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Daily")
                    }
                    .tag(2)
                
                SettingsView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .tag(3)
            }
            .accentColor(Color("ButtonColor"))
            .onAppear {
                // Configure tab bar appearance
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(Color("BackgroundColor"))
                
                UITabBar.appearance().standardAppearance = appearance
                if #available(iOS 15.0, *) {
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                }
            }
        }
    }
}

struct DailyView: View {
    @StateObject private var quizService = QuizService()
    @StateObject private var puzzleService = PuzzleService()
    @State private var selectedChallenge: DailyChallenge?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 10) {
                            Text("Daily Challenge")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Complete today's special challenge for bonus points!")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        
                        // Daily Challenge Card
                        if let challenge = quizService.dailyChallenge {
                            DailyChallengeCard(challenge: challenge) {
                                selectedChallenge = challenge
                            }
                        } else {
                            Button("Generate Today's Challenge") {
                                quizService.generateDailyChallenge()
                            }
                            .foregroundColor(.black)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Color("ButtonColor"))
                            .cornerRadius(25)
                        }
                        
                        // Brain Teasers Section
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("Brain Teasers")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            
                            ForEach(puzzleService.dailyBrainTeasers) { teaser in
                                BrainTeaserCard(teaser: teaser)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(15)
                        
                        // Streak Information
                        StreakCard(
                            quizStreak: quizService.userProgress.streakDays,
                            puzzleStreak: puzzleService.puzzleProgress.dailyStreak
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("Daily")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                quizService.generateDailyChallenge()
            }
        }
    }
}

struct DailyChallengeCard: View {
    let challenge: DailyChallenge
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 15) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Today's Challenge")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(DateFormatter.dayMonth.string(from: challenge.date))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 5) {
                        Text("\(String(format: "%.1fx", challenge.bonusMultiplier))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color("ButtonColor"))
                        
                        Text("Bonus")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                HStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title)
                            .foregroundColor(Color("ButtonColor"))
                        
                        Text("Quiz")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Image(systemName: "plus")
                        .foregroundColor(.white.opacity(0.5))
                    
                    VStack(spacing: 8) {
                        Image(systemName: "puzzlepiece.extension.fill")
                            .font(.title)
                            .foregroundColor(Color("SuccessColor"))
                        
                        Text("Puzzle")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                if challenge.isCompleted {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color("SuccessColor"))
                        Text("Completed!")
                            .fontWeight(.medium)
                            .foregroundColor(Color("SuccessColor"))
                    }
                } else {
                    Text("Tap to Start Challenge")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color("ButtonColor"))
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color("ButtonColor").opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(challenge.isCompleted)
    }
}

struct BrainTeaserCard: View {
    let teaser: BrainTeaser
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: teaser.category.icon)
                    .foregroundColor(Color("ButtonColor"))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(teaser.title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text(teaser.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Text(teaser.content)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                    
                    HStack {
                        Label("~\(Int(teaser.estimatedTime / 60)) min", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Text(teaser.difficulty.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(difficultyColor(teaser.difficulty))
                            .cornerRadius(8)
                    }
                    
                    if !teaser.tips.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("💡 Tips:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color("ButtonColor"))
                            
                            ForEach(teaser.tips, id: \.self) { tip in
                                Text("• \(tip)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(.top, 5)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
    
    private func difficultyColor(_ difficulty: DifficultyLevel) -> Color {
        switch difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        case .expert: return .purple
        }
    }
}

struct StreakCard: View {
    let quizStreak: Int
    let puzzleStreak: Int
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Your Streaks")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
            }
            
            HStack(spacing: 20) {
                StreakItem(
                    title: "Quiz Streak",
                    days: quizStreak,
                    icon: "questionmark.circle.fill",
                    color: Color("ButtonColor")
                )
                
                StreakItem(
                    title: "Puzzle Streak",
                    days: puzzleStreak,
                    icon: "puzzlepiece.extension.fill",
                    color: Color("SuccessColor")
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
}

struct StreakItem: View {
    let title: String
    let days: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text("\(days)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 2) {
                Text("Days")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

extension DateFormatter {
    static let dayMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }()
}

#Preview {
    ContentView()
}
