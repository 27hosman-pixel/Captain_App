import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @State private var selection: Int = 0 // 0 = Weekly, 1 = Season

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header with segmented control
                HStack {
                    Text("MY STATS")
                        .font(.title2)
                        .bold()
                    Spacer()
                }
                .padding(.horizontal)

                Picker("Range", selection: $selection) {
                    Text("Weekly").tag(0)
                    Text("Season").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                // Progress chart (two lines: goals & minutes)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Goals & Minutes Progress")
                        .font(.headline)
                        .padding(.horizontal)

                    MultiLineChartView(dataSeries: chartSeries(), labels: chartLabels())
                        .frame(height: 180)
                        .padding(.horizontal)
                }

                // Stat tiles grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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
                .padding(.horizontal)

                Spacer(minLength: 40)
            }
            .padding(.top)
        }
        .navigationTitle("Stats")
    }

    // MARK: - Data helpers
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
        // produce two series: goals and minutes per period
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
        return (0..<count).map { i in ""
        }
    }

    private func bucketedSessions() -> [[SessionData]] {
        // bucket sessions into N periods (last 8 weeks or season months)
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

// Small stat tile
struct StatTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.title2).bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator)))
    }
}

// Simple multi-line chart for two series
struct MultiLineChartView: View {
    var dataSeries: [[Double]]
    var labels: [String]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let maxV = (dataSeries.flatMap { $0 }.max() ?? 1)
            ZStack {
                // grid lines
                ForEach(0..<4) { i in
                    Path { p in
                        let y = h * CGFloat(i) / 4.0
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: w, y: y))
                    }
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
                }

                ForEach(0..<dataSeries.count, id: \.self) { idx in
                    let series = dataSeries[idx]
                    Path { p in
                        for (i, v) in series.enumerated() {
                            let x = w * CGFloat(i) / CGFloat(max(1, series.count - 1))
                            let y = h - (h * CGFloat(v) / CGFloat(maxV == 0 ? 1 : maxV))
                            if i == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }
                    .stroke(idx == 0 ? Color.accentColor : Color.blue, lineWidth: 2)
                }
            }
        }
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
            .environmentObject(SessionStore())
    }
}
