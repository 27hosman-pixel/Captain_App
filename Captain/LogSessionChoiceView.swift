import SwiftUI

struct LogSessionChoiceView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Hero section with motivational text
                VStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.top, Theme.Spacing.xl)
                    
                    Text("What did you do today?")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Theme.Colors.text)
                        .padding(.top, Theme.Spacing.sm)
                    
                    Text("Track your progress and share with teammates")
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(Theme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.xl)
                }
                .padding(.bottom, Theme.Spacing.md)

                // Session type options with enhanced cards
                VStack(spacing: Theme.Spacing.md) {
                    SessionOptionCard(
                        icon: "sportscourt",
                        title: "Practice",
                        subtitle: "Log a team practice session",
                        gradientColors: [Color.blue, Color.blue.opacity(0.7)],
                        action: {
                            print("[LogChoice] post NavigateToLogPractice")
                            NotificationCenter.default.post(
                                name: Notification.Name("NavigateToLogPractice"),
                                object: nil
                            )
                        }
                    )

                    SessionOptionCard(
                        icon: "flag",
                        title: "Game",
                        subtitle: "Log a match with stats",
                        gradientColors: [Color.orange, Color.red.opacity(0.8)],
                        action: {
                            print("[LogChoice] post NavigateToLogGame")
                            NotificationCenter.default.post(
                                name: Notification.Name("NavigateToLogGame"),
                                object: nil
                            )
                        }
                    )

                    SessionOptionCard(
                        icon: "figure.walk",
                        title: "Individual Workout",
                        subtitle: "Log a solo training session",
                        gradientColors: [Color.green, Color.teal.opacity(0.8)],
                        action: {
                            print("[LogChoice] post NavigateToLogWorkout")
                            NotificationCenter.default.post(
                                name: Notification.Name("NavigateToLogWorkout"),
                                object: nil
                            )
                        }
                    )
                }
                .padding(.horizontal, Theme.Spacing.md)
                
                Spacer(minLength: Theme.Spacing.xl)
            }
        }
        .navigationTitle("Log Session")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 20)
        }
    }
}

// MARK: - Enhanced Session Option Card Component

private struct SessionOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradientColors: [Color]
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .leading) {
                // Background gradient
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .cornerRadius(Theme.CornerRadius.lg)
                
                // Content
                HStack(spacing: Theme.Spacing.md) {
                    // Large icon with circular background
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: icon)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    // Text content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(subtitle)
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    // Chevron indicator
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(Theme.Spacing.md)
            }
            .frame(height: 100)
            .shadow(
                color: gradientColors[0].opacity(0.4),
                radius: isPressed ? 4 : 12,
                x: 0,
                y: isPressed ? 2 : 8
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(CardButtonStyle(isPressed: $isPressed))
    }
}

// Custom button style for press animation
private struct CardButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = newValue
                }
            }
    }
}

struct LogSessionChoiceView_Previews: PreviewProvider {
    static var previews: some View {
        LogSessionChoiceView()
    }
}
