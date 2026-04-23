import SwiftUI

struct LogSessionChoiceView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Log New Session")
                .font(.largeTitle).bold()
                .padding(.top, 24)

            Text("Choose the type of session you want to log")
                .foregroundColor(.secondary)

            Spacer()

            VStack(spacing: 16) {
                Button(action: { NotificationCenter.default.post(name: Notification.Name("NavigateToLogPractice"), object: nil) }) {
                    HStack {
                        Image(systemName: "whistle")
                            .font(.title2)
                            .frame(width: 36, height: 36)
                        VStack(alignment: .leading) {
                            Text("Practice")
                                .font(.headline)
                            Text("Log a team practice session")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                }

                Button(action: { NotificationCenter.default.post(name: Notification.Name("NavigateToLogGame"), object: nil) }) {
                    HStack {
                        Image(systemName: "sportscourt")
                            .font(.title2)
                            .frame(width: 36, height: 36)
                        VStack(alignment: .leading) {
                            Text("Game")
                                .font(.headline)
                            Text("Log a match with stats")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                }

                Button(action: { NotificationCenter.default.post(name: Notification.Name("NavigateToLogWorkout"), object: nil) }) {
                    HStack {
                        Image(systemName: "figure.run")
                            .font(.title2)
                            .frame(width: 36, height: 36)
                        VStack(alignment: .leading) {
                            Text("Individual Workout")
                                .font(.headline)
                            Text("Log a solo training session")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .navigationTitle("New Session")
    }
}

struct LogSessionChoiceView_Previews: PreviewProvider {
    static var previews: some View {
        LogSessionChoiceView()
            .environmentObject(AppRouter())
    }
}
