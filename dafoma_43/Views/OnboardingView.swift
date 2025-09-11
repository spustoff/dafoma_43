//
//  OnboardingView.swift
//  QuizzleQuest Road
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var showQuizDemo = false
    @State private var showPuzzleDemo = false
    
    private let onboardingPages = [
        OnboardingPage(
            title: "Welcome to QuizzleQuest Road",
            description: "Embark on an exciting journey of knowledge and brain-teasing challenges!",
            imageName: "brain.head.profile",
            color: Color("ButtonColor")
        ),
        OnboardingPage(
            title: "Dynamic Quiz Challenges",
            description: "Test your knowledge across various topics with adaptive difficulty that grows with you.",
            imageName: "questionmark.circle",
            color: Color("SuccessColor")
        ),
        OnboardingPage(
            title: "Puzzle Mastery",
            description: "Solve unique puzzles that challenge your logic, memory, and pattern recognition skills.",
            imageName: "puzzlepiece.extension",
            color: Color.orange
        ),
        OnboardingPage(
            title: "Daily Brain Teasers",
            description: "Get daily notifications with fun challenges to keep your mind sharp and engaged.",
            imageName: "bell.badge",
            color: Color.purple
        ),
        OnboardingPage(
            title: "Track Your Progress",
            description: "Monitor your achievements, streaks, and improvements across all categories.",
            imageName: "chart.line.uptrend.xyaxis",
            color: Color.blue
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color("BackgroundColor"), Color("BackgroundColor").opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress indicator
                    HStack {
                        ForEach(0..<onboardingPages.count, id: \.self) { index in
                            Capsule()
                                .fill(index <= currentPage ? Color("ButtonColor") : Color.white.opacity(0.3))
                                .frame(width: index == currentPage ? 30 : 10, height: 6)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Main content
                    TabView(selection: $currentPage) {
                        ForEach(0..<onboardingPages.count, id: \.self) { index in
                            OnboardingPageView(
                                page: onboardingPages[index],
                                showDemo: index == 1 ? $showQuizDemo : index == 2 ? $showPuzzleDemo : .constant(false)
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.5), value: currentPage)
                    
                    // Navigation buttons
                    HStack {
                        if currentPage > 0 {
                            Button("Previous") {
                                withAnimation {
                                    currentPage -= 1
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(25)
                        }
                        
                        Spacer()
                        
                        Button(currentPage == onboardingPages.count - 1 ? "Get Started" : "Next") {
                            if currentPage == onboardingPages.count - 1 {
                                hasCompletedOnboarding = true
                            } else {
                                withAnimation {
                                    currentPage += 1
                                }
                            }
                        }
                        .foregroundColor(.black)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color("ButtonColor"))
                        .cornerRadius(25)
                        .shadow(color: Color("ButtonColor").opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showQuizDemo) {
            QuizDemoView()
        }
        .sheet(isPresented: $showPuzzleDemo) {
            PuzzleDemoView()
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @Binding var showDemo: Bool
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Animated icon
            Image(systemName: page.imageName)
                .font(.system(size: 80, weight: .light))
                .foregroundColor(page.color)
                .scaleEffect(animateIcon ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateIcon)
                .onAppear {
                    animateIcon = true
                }
            
            VStack(spacing: 15) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Interactive demo button for quiz and puzzle pages
            if page.title.contains("Quiz") || page.title.contains("Puzzle") {
                Button("Try Interactive Demo") {
                    showDemo = true
                }
                .foregroundColor(.white)
                .fontWeight(.medium)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(page.color.opacity(0.3))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(page.color, lineWidth: 1)
                )
            }
            
            Spacer()
        }
        .padding()
    }
}

struct QuizDemoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAnswer: Int? = nil
    @State private var showResult = false
    
    private let demoQuestion = QuizQuestion(
        question: "What is the capital of France?",
        options: ["London", "Berlin", "Paris", "Madrid"],
        correctAnswerIndex: 2,
        explanation: "Paris is the capital and largest city of France.",
        points: 10
    )
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Demo Quiz Question")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text(demoQuestion.question)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(15)
                        
                        ForEach(0..<demoQuestion.options.count, id: \.self) { index in
                            Button(action: {
                                selectedAnswer = index
                                showResult = true
                            }) {
                                HStack {
                                    Text(demoQuestion.options[index])
                                        .foregroundColor(.white)
                                    Spacer()
                                    if let selected = selectedAnswer, selected == index {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color("SuccessColor"))
                                    }
                                }
                                .padding()
                                .background(
                                    selectedAnswer == index ? 
                                    Color("ButtonColor").opacity(0.3) : 
                                    Color.white.opacity(0.1)
                                )
                                .cornerRadius(12)
                            }
                            .disabled(showResult)
                        }
                        
                        if showResult {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(selectedAnswer == demoQuestion.correctAnswerIndex ? "Correct! 🎉" : "Try again! 💪")
                                    .font(.headline)
                                    .foregroundColor(selectedAnswer == demoQuestion.correctAnswerIndex ? Color("SuccessColor") : .orange)
                                
                                Text(demoQuestion.explanation)
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    Button("Close Demo") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color("ButtonColor"))
                    .cornerRadius(25)
                    .padding(.bottom)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
}

struct PuzzleDemoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scrambledLetters = ["C", "A", "T"]
    @State private var selectedLetters: [String] = []
    @State private var showResult = false
    
    var userWord: String {
        selectedLetters.joined()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Demo Word Scramble")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    Text("Unscramble these letters to form a word:")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    // Selected letters display
                    HStack(spacing: 10) {
                        ForEach(0..<3, id: \.self) { index in
                            Text(index < selectedLetters.count ? selectedLetters[index] : "_")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                    
                    // Available letters
                    HStack(spacing: 15) {
                        ForEach(scrambledLetters, id: \.self) { letter in
                            Button(letter) {
                                if selectedLetters.count < 3 {
                                    selectedLetters.append(letter)
                                    if let index = scrambledLetters.firstIndex(of: letter) {
                                        scrambledLetters.remove(at: index)
                                    }
                                }
                                
                                if selectedLetters.count == 3 && userWord == "CAT" {
                                    showResult = true
                                }
                            }
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .frame(width: 50, height: 50)
                            .background(Color("ButtonColor"))
                            .cornerRadius(10)
                        }
                    }
                    
                    // Clear button
                    if !selectedLetters.isEmpty {
                        Button("Clear") {
                            scrambledLetters.append(contentsOf: selectedLetters)
                            selectedLetters.removeAll()
                            showResult = false
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(15)
                    }
                    
                    if showResult {
                        Text("Excellent! You formed 'CAT'! 🐱")
                            .font(.headline)
                            .foregroundColor(Color("SuccessColor"))
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    Spacer()
                    
                    Button("Close Demo") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color("ButtonColor"))
                    .cornerRadius(25)
                    .padding(.bottom)
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    OnboardingView()
}

