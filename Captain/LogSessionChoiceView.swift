import SwiftUI

struct LogSessionChoiceView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Large title with consistent typography
            Text("Log New Session")
                .font(Theme.Typography.largeTitle)
                .foregroundColor(Theme.Colors.text)
                .padding(.top, Theme.Spacing.lg)

            // Subtitle with secondary color
            Text("Choose the type of session you want to log")
                .font(Theme.Typography.subheadline)
                .foregroundColor(Theme.Colors.secondaryText)

            Spacer()

            // Session type options with consistent 8pt spacing
            VStack(spacing: Theme.Spacing.md) {
                SessionOptionButton(
                    icon: "sportscourt",
                    title: "Practice",
                    subtitle: "Log a team practice session",
                    action: {
                        print("[LogChoice] post NavigateToLogPractice")
                        NotificationCenter.default.post(
                            name: Notification.Name("NavigateToLogPractice"),
                            object: nil
                        )
                    }
                )

                SessionOptionButton(
                    icon: "flag",
                    title: "Game",
                    subtitle: "Log a match with stats",
                    action: {
                        print("[LogChoice] post NavigateToLogGame")
                        NotificationCenter.default.post(
                            name: Notification.Name("NavigateToLogGame"),
                            object: nil
                        )
                    }
                )

                SessionOptionButton(
                    icon: "figure.walk",
                    title: "Individual Workout",
                    subtitle: "Log a solo training session",
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

            Spacer()
        }
        .navigationTitle("New Session")
    }
}

// MARK: - Session Option Button Component

private struct SessionOptionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                // Icon container
                Image(systemName: icon)
                    .font(.system(size: Theme.IconSize.lg, weight: .medium))
                    .foregroundColor(Theme.Colors.primary)
                    .frame(width: 36, height: 36)

                // Text content
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(title)
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.text)
                    
                    Text(subtitle)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Spacer()
                
                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: Theme.IconSize.sm, weight: .medium))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }
}

struct LogSessionChoiceView_Previews: PreviewProvider {
    static var previews: some View {
        LogSessionChoiceView()
    }
}
