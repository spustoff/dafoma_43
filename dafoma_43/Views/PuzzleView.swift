//
//  PuzzleView.swift
//  QuizzleQuest Road
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI

struct PuzzleView: View {
    @StateObject private var viewModel = PuzzleViewModel()
    @StateObject private var puzzleService = PuzzleService()
    @State private var selectedPuzzle: Puzzle?
    @State private var showingPuzzleSelection = true
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                
                if showingPuzzleSelection {
                    PuzzleSelectionView(
                        puzzles: puzzleService.availablePuzzles,
                        onPuzzleSelected: { puzzle in
                            selectedPuzzle = puzzle
                            viewModel.startPuzzle(puzzle)
                            showingPuzzleSelection = false
                        }
                    )
                } else if viewModel.isPuzzleCompleted {
                    PuzzleResultView(
                        result: viewModel.puzzleResult,
                        puzzle: viewModel.currentPuzzle,
                        onTryAgain: {
                            if let puzzle = selectedPuzzle {
                                viewModel.startPuzzle(puzzle)
                            }
                        },
                        onSelectNewPuzzle: {
                            viewModel.resetPuzzle()
                            showingPuzzleSelection = true
                        }
                    )
                } else {
                    PuzzleGameView(viewModel: viewModel)
                }
            }
            .navigationTitle(showingPuzzleSelection ? "Select Puzzle" : (viewModel.currentPuzzle?.title ?? "Puzzle"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(!showingPuzzleSelection && !viewModel.isPuzzleCompleted)
            .navigationBarItems(
                trailing: !showingPuzzleSelection && !viewModel.isPuzzleCompleted ?
                Button("Exit") {
                    viewModel.resetPuzzle()
                    showingPuzzleSelection = true
                }
                .foregroundColor(.white) : nil
            )
        }
    }
}

struct PuzzleSelectionView: View {
    let puzzles: [Puzzle]
    let onPuzzleSelected: (Puzzle) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                ForEach(PuzzleType.allCases, id: \.self) { type in
                    let typePuzzles = puzzles.filter { $0.type == type }
                    
                    if !typePuzzles.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(Color("ButtonColor"))
                                Text(type.rawValue)
                                    .font(.headline)
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(typePuzzles) { puzzle in
                                        PuzzleCard(puzzle: puzzle) {
                                            onPuzzleSelected(puzzle)
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

struct PuzzleCard: View {
    let puzzle: Puzzle
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: puzzle.type.icon)
                        .font(.title2)
                        .foregroundColor(Color("ButtonColor"))
                    
                    Spacer()
                    
                    Text(puzzle.difficulty.rawValue)
                        .font(.caption)
                        .font(.body.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(difficultyColor(puzzle.difficulty))
                        .cornerRadius(8)
                }
                
                Text(puzzle.title)
                    .font(.headline)
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Text(puzzle.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Label("\(puzzle.hints.count) hints", systemImage: "lightbulb")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    if let timeLimit = puzzle.timeLimit {
                        Label(timeString(timeLimit), systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        Text("No time limit")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
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

struct PuzzleGameView: View {
    @ObservedObject var viewModel: PuzzleViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with timer and hints
            VStack(spacing: 10) {
                HStack {
                    if let puzzle = viewModel.currentPuzzle {
                        Text(puzzle.type.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    if viewModel.isTimerActive {
                        Text(viewModel.timeRemainingFormatted)
                            .font(.headline)
                            .font(.headline.weight(.semibold))
                            .foregroundColor(viewModel.timeRemaining < 30 ? .red : .white)
                    }
                }
                
                HStack {
                    Button(action: viewModel.toggleHint) {
                        HStack(spacing: 5) {
                            Image(systemName: "lightbulb")
                            Text("Hint")
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color("ButtonColor").opacity(0.7))
                        .cornerRadius(12)
                    }
                    
                    if viewModel.hasMoreHints {
                        Button("Next Hint") {
                            viewModel.showNextHint()
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            
            ScrollView {
                VStack(spacing: 20) {
                    // Puzzle content
                    if let puzzle = viewModel.currentPuzzle {
                        PuzzleContentView(puzzle: puzzle, viewModel: viewModel)
                    }
                    
                    // Hint display
                    if let hint = viewModel.currentHint {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("💡 Hint")
                                .font(.headline)
                                .foregroundColor(Color("ButtonColor"))
                            
                            Text(hint)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // Solution display (for incorrect answers)
                    if viewModel.showSolution, let puzzle = viewModel.currentPuzzle {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("💡 Solution")
                                .font(.headline)
                                .foregroundColor(.orange)
                            
                            Text("The correct answer was: \(puzzle.solution)")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding()
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding()
            }
            
            // Submit button
            if !viewModel.isPuzzleCompleted && viewModel.currentPuzzle?.type != .wordScramble {
                Button("Submit Answer") {
                    viewModel.submitAnswer()
                }
                .foregroundColor(.black)
                .font(.body.weight(.semibold))
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(Color("ButtonColor"))
                .cornerRadius(25)
                .padding()
                .disabled(viewModel.userAnswer.isEmpty)
            }
        }
    }
}

struct PuzzleContentView: View {
    let puzzle: Puzzle
    @ObservedObject var viewModel: PuzzleViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Puzzle description
            Text(puzzle.description)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(15)
            
            // Type-specific content
            switch puzzle.type {
            case .wordScramble:
                WordScrambleView(viewModel: viewModel)
                
            case .numberSequence, .pattern:
                SequenceView(puzzle: puzzle, viewModel: viewModel)
                
            case .riddle, .logicGrid:
                RiddleView(puzzle: puzzle, viewModel: viewModel)
                
            case .memory:
                MemoryView(puzzle: puzzle, viewModel: viewModel)
            }
        }
    }
}

struct WordScrambleView: View {
    @ObservedObject var viewModel: PuzzleViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Current word display
            HStack(spacing: 10) {
                ForEach(0..<8, id: \.self) { index in
                    Text(index < viewModel.selectedLetters.count ? viewModel.selectedLetters[index] : "_")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 50)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            // Available letters
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                ForEach(viewModel.scrambledLetters, id: \.self) { letter in
                    Button(letter) {
                        viewModel.addLetter(letter)
                    }
                    .font(.title2)
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.black)
                    .frame(width: 50, height: 50)
                    .background(Color("ButtonColor"))
                    .cornerRadius(10)
                }
            }
            
            // Action buttons
            HStack(spacing: 15) {
                if !viewModel.selectedLetters.isEmpty {
                    Button("Clear") {
                        viewModel.clearWord()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(15)
                }
                
                Button("Shuffle") {
                    viewModel.shuffleLetters()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.2))
                .cornerRadius(15)
                
                if !viewModel.userAnswer.isEmpty {
                    Button("Submit") {
                        viewModel.submitAnswer()
                    }
                    .foregroundColor(.black)
                    .font(.title2.weight(.semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color("ButtonColor"))
                    .cornerRadius(15)
                }
            }
        }
    }
}

struct SequenceView: View {
    let puzzle: Puzzle
    @ObservedObject var viewModel: PuzzleViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text(puzzle.data.content)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            
            if let options = puzzle.data.options {
                VStack(spacing: 10) {
                    ForEach(0..<options.count, id: \.self) { index in
                        Button(options[index]) {
                            viewModel.userAnswer = options[index]
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            viewModel.userAnswer == options[index] ? 
                            Color("ButtonColor").opacity(0.5) : 
                            Color.white.opacity(0.1)
                        )
                        .cornerRadius(10)
                    }
                }
            } else {
                TextField("Enter your answer", text: $viewModel.userAnswer)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
            }
        }
    }
}

struct RiddleView: View {
    let puzzle: Puzzle
    @ObservedObject var viewModel: PuzzleViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text(puzzle.data.content)
                .font(.body)
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            
            if let options = puzzle.data.options {
                VStack(spacing: 10) {
                    ForEach(0..<options.count, id: \.self) { index in
                        Button(options[index]) {
                            viewModel.userAnswer = options[index]
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            viewModel.userAnswer == options[index] ? 
                            Color("ButtonColor").opacity(0.5) : 
                            Color.white.opacity(0.1)
                        )
                        .cornerRadius(10)
                    }
                }
            } else {
                TextField("Enter your answer", text: $viewModel.userAnswer)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
            }
        }
    }
}

struct MemoryView: View {
    let puzzle: Puzzle
    @ObservedObject var viewModel: PuzzleViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            if viewModel.showMemorySequence {
                VStack(spacing: 15) {
                    Text("Memorize this sequence:")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(viewModel.memorySequenceText)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color("ButtonColor"))
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    
                    Text("Remember it carefully...")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
            } else {
                VStack(spacing: 15) {
                    Text("Enter the sequence you memorized:")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let options = puzzle.data.options {
                        VStack(spacing: 10) {
                            ForEach(0..<options.count, id: \.self) { index in
                                Button(options[index]) {
                                    viewModel.userAnswer = options[index]
                                }
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    viewModel.userAnswer == options[index] ? 
                                    Color("ButtonColor").opacity(0.5) : 
                                    Color.white.opacity(0.1)
                                )
                                .cornerRadius(10)
                            }
                        }
                    } else {
                        TextField("Enter sequence (comma separated)", text: $viewModel.userAnswer)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                    }
                }
            }
        }
    }
}

struct PuzzleResultView: View {
    let result: PuzzleResult?
    let puzzle: Puzzle?
    let onTryAgain: () -> Void
    let onSelectNewPuzzle: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Result header
                VStack(spacing: 15) {
                    Image(systemName: result?.isCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(result?.isCorrect == true ? Color("SuccessColor") : .red)
                    
                    Text(result?.isCorrect == true ? "Correct!" : "Try Again!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(performanceMessage)
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
                
                // Statistics
                if let result = result, let puzzle = puzzle {
                    VStack(spacing: 15) {
                        Text("Puzzle Statistics")
                            .font(.headline)
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 12) {
                            StatRow(label: "Result", value: result.isCorrect ? "Correct ✓" : "Incorrect ✗")
                            StatRow(label: "Time Spent", value: timeString(result.timeSpent))
                            StatRow(label: "Hints Used", value: "\(result.hintsUsed)")
                            StatRow(label: "Your Answer", value: result.userAnswer)
                            if !result.isCorrect {
                                StatRow(label: "Correct Answer", value: puzzle.solution)
                            }
                            StatRow(label: "Type", value: puzzle.type.rawValue)
                            StatRow(label: "Difficulty", value: puzzle.difficulty.rawValue)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(15)
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button("Try Again") {
                        onTryAgain()
                    }
                    .foregroundColor(.black)
                    .font(.title2.weight(.semibold))
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(Color("ButtonColor"))
                    .cornerRadius(25)
                    
                    Button("Select New Puzzle") {
                        onSelectNewPuzzle()
                    }
                    .foregroundColor(.white)
                    .font(.body.weight(.medium))
                    .padding(.horizontal, 30)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                }
            }
            .padding()
        }
    }
    
    private var performanceMessage: String {
        guard let result = result else { return "" }
        
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
    
    private func timeString(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    PuzzleView()
}


