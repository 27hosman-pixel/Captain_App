import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @State private var selection: Int = 0 // 0 = Weekly, 1 = Season

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                // Section header with 8pt spacing
                ThemeSectionHeader(title: "My Stats")
                    .padding(.horizontal, Theme.Spacing.md)

                // Segmented picker with consistent spacing
                Picker("Range", selection: $selection) {
                    Text("Weekly").tag(0)
                    Text("Season").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, Theme.Spacing.md)

                // Chart section with semantic typography
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Goals & Minutes Progress")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.text)
                        .padding(.horizontal, Theme.Spacing.md)

                    MultiLineChartView(dataSeries: chartSeries(), labels: chartLabels())
                        .frame(height: 200)
                        .padding(.horizontal, Theme.Spacing.md)
                }

                // Stat grid with consistent 8pt spacing
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: Theme.Spacing.sm
                ) {
                    StatTile(title: "Total Games", value: String(total(of: "Game")))
                    StatTile(title: "Total Practices", value: String(total(of: "Practice")))
                    StatTile(title: "Total Workouts", value: String(total(of: "Workout")))

                    StatTile(title: "Goals", value: String(sumDetail("Goals")))
                    StatTile(title: "Assists", value: String(sumDetail("Assists")))
                    StatTile(title: "Tackles", value: String(sumDetail("Tackles")))

                    StatTile(title: "Miles", value: String(format: "%.1f", sumDetailDouble("TotalMiles")))
                    StatTile(title: "Peak HR", value: String(maxDetail("PeakHR")))
                    StatTile(title: "Sprints", value: String(sumDetail("Sprints")))
                }
                .padding(.horizontal, Theme.Spacing.md)

                Spacer(minLength: Theme.Spacing.xl)
            }
            .padding(.top, Theme.Spacing.md)
        }
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: Theme.Spacing.md)
        }
    }

    // MARK: - Data helpers (unchanged)
    private func total(of type: String) -> Int {
        sessionStore.sessions.filter { $0.sessionType.lowercased().contains(type.lowercased()) }.count
    }

    private func sumDetail(_ key: String) -> Int {
        sessionStore.sessions.reduce(0) { acc, s in
            if let v = s.details[key], let n = Int(v) { return acc + n }
            return acc
        }
    }

    private func sumDetailDouble(_ key: String) -> Double {
        sessionStore.sessions.reduce(0.0) { acc, s in
            if let v = s.details[key], let n = Double(v) { return acc + n }
            return acc
        }
    }

    private func maxDetail(_ key: String) -> Int {
        sessionStore.sessions.compactMap { s in
            if let v = s.details[key], let n = Int(v) { return n }
            return nil
        }.max() ?? 0
    }

    private func chartSeries() -> [[Double]] {
        // Two series: goals and minutes per bucket
        let buckets = bucketedSessions()
        let goals = buckets.map { bucket in
            Double(bucket.reduce(0) { acc, s in acc + (Int(s.details["Goals"] ?? "0") ?? 0) })
        }
        let minutes = buckets.map { bucket in
            Double(bucket.reduce(0) { acc, s in acc + (Int(s.details["Minutes"] ?? "0") ?? 0) })
        }
        return [goals, minutes]
    }

    private func chartLabels() -> [String] {
        let count = 8
        // Use empty labels for compactness
        return (0..<count).map { _ in "" }
    }

    private func bucketedSessions() -> [[SessionData]] {
        // 8 buckets of weeks ago (0 = current week)
        let count = 8
        let now = Date()
        var buckets: [[SessionData]] = Array(repeating: [], count: count)
        let calendar = Calendar.current
        for s in sessionStore.sessions {
            let weeksAgo = calendar.dateComponents([.weekOfYear], from: s.date, to: now).weekOfYear ?? 0
            let idx = max(0, min(count - 1, count - 1 - weeksAgo))
            buckets[idx].append(s)
        }
        return buckets
    }
}

// MARK: - Supporting views (self-contained)

// Simple multi-series line chart with a baseline and x labels
private struct MultiLineChartView: View {
    let dataSeries: [[Double]]
    let labels: [String]

    // Colors per series (expand if needed)
    private let seriesColors: [Color] = [
        Theme.Colors.success,
        Theme.Colors.primary
    ]

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let maxVal = max(dataSeries.flatMap { $0 }.max() ?? 1, 1)
            let count = max(dataSeries.first?.count ?? 0, 0)
            let stepX = count > 1 ? width / CGFloat(count - 1) : 0

            ZStack {
                // Baseline grid (simple: just a midline)
                Path { path in
                    let y = height * 0.8
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
                .stroke(
                    Color(.systemGray4),
                    style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                )

                // Series lines
                ForEach(dataSeries.indices, id: \.self) { sIndex in
                    let series = dataSeries[sIndex]
                    Path { path in
                        for (i, v) in series.enumerated() {
                            let x = CGFloat(i) * stepX
                            let y = height - CGFloat(v / maxVal) * (height * 0.85) - height * 0.05
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(
                        seriesColors[safe: sIndex] ?? Theme.Colors.primary,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                    )
                }

                // X labels (compact)
                VStack {
                    Spacer()
                    HStack {
                        ForEach(labels.indices, id: \.self) { i in
                            Text(labels[i])
                                .font(Theme.Typography.caption2)
                                .foregroundColor(Theme.Colors.secondaryText)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .padding(.top, Theme.Spacing.xxs)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(Theme.Colors.divider, lineWidth: 0.5)
        )
    }
}

// Safe index helper
private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private struct StatTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
            
            Text(value)
                .font(Theme.Typography.title3)
                .foregroundColor(Theme.Colors.text)
        }
        .statTileStyle()
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StatisticsView()
                .environmentObject(SessionStore())
        }
    }
}
