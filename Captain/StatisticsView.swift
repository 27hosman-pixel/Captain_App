import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @State private var selection: Int = 0 // 0 = Weekly, 1 = Season

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Hero stats section with gradient background
                ZStack(alignment: .top) {
                    // Gradient background
                    LinearGradient(
                        colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 200)
                    .cornerRadius(Theme.CornerRadius.lg)
                    
                    VStack(spacing: Theme.Spacing.md) {
                        // Segmented picker with modern styling
                        Picker("Range", selection: $selection) {
                            Text("Weekly").tag(0)
                            Text("Season").tag(1)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.top, Theme.Spacing.md)
                        
                        // Featured stats
                        HStack(spacing: Theme.Spacing.lg) {
                            FeaturedStatView(
                                icon: "figure.soccer",
                                value: "\(total(of: "Game") + total(of: "Practice"))",
                                label: "Sessions"
                            )
                            
                            Divider()
                                .frame(height: 40)
                                .background(Color.white.opacity(0.3))
                            
                            FeaturedStatView(
                                icon: "flame.fill",
                                value: String(format: "%.1f", sumDetailDouble("TotalMiles")),
                                label: "Miles"
                            )
                            
                            Divider()
                                .frame(height: 40)
                                .background(Color.white.opacity(0.3))
                            
                            FeaturedStatView(
                                icon: "target",
                                value: "\(sumDetail("Goals"))",
                                label: "Goals"
                            )
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.sm)

                // Chart section with enhanced design
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Performance")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(Theme.Colors.text)
                            
                            Text("Goals & Minutes tracked over time")
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, Theme.Spacing.md)

                    MultiLineChartView(dataSeries: chartSeries(), labels: chartLabels())
                        .frame(height: 180)
                        .padding(.horizontal, Theme.Spacing.md)
                }
                .padding(.top, Theme.Spacing.sm)

                // Activity breakdown section
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Activity Breakdown")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.Colors.text)
                        .padding(.horizontal, Theme.Spacing.md)
                    
                    HStack(spacing: Theme.Spacing.sm) {
                        ActivityCard(
                            icon: "flag.checkered.circle.fill",
                            title: "Games",
                            value: "\(total(of: "Game"))",
                            color: .orange
                        )
                        
                        ActivityCard(
                            icon: "sportscourt.circle.fill",
                            title: "Practices",
                            value: "\(total(of: "Practice"))",
                            color: .blue
                        )
                        
                        ActivityCard(
                            icon: "figure.run.circle.fill",
                            title: "Workouts",
                            value: "\(total(of: "Workout"))",
                            color: .green
                        )
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }

                // Detailed stats section
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Detailed Stats")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.Colors.text)
                        .padding(.horizontal, Theme.Spacing.md)
                    
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        spacing: Theme.Spacing.sm
                    ) {
                        EnhancedStatTile(icon: "target", title: "Goals", value: String(sumDetail("Goals")), color: .red)
                        EnhancedStatTile(icon: "hand.raised.fill", title: "Assists", value: String(sumDetail("Assists")), color: .blue)
                        EnhancedStatTile(icon: "shield.fill", title: "Tackles", value: String(sumDetail("Tackles")), color: .green)
                        EnhancedStatTile(icon: "heart.fill", title: "Peak HR", value: String(maxDetail("PeakHR")), color: .pink)
                        EnhancedStatTile(icon: "bolt.fill", title: "Sprints", value: String(sumDetail("Sprints")), color: .yellow)
                        EnhancedStatTile(icon: "figure.walk", title: "Miles", value: String(format: "%.1f", sumDetailDouble("TotalMiles")), color: .purple)
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }

                Spacer(minLength: Theme.Spacing.xl)
            }
            .padding(.top, Theme.Spacing.sm)
            .padding(.bottom, 100)
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

// Featured stat in hero section
private struct FeaturedStatView: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.white)
            
            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }
}

// Activity card for breakdown section
private struct ActivityCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.Colors.text)
            
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// Enhanced stat tile with icons and colors
private struct EnhancedStatTile: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.Colors.text)
                
                Text(title)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            Spacer()
        }
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(Theme.Colors.divider, lineWidth: 0.5)
        )
        .shadow(
            color: color.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )
    }
}

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
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.03),
                        Color.purple.opacity(0.02)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Baseline grid (simple: just a midline)
                Path { path in
                    let y = height * 0.8
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
                .stroke(
                    Color(.systemGray5),
                    style: StrokeStyle(lineWidth: 1, dash: [6, 4])
                )

                // Series lines with gradient strokes
                ForEach(dataSeries.indices, id: \.self) { sIndex in
                    let series = dataSeries[sIndex]
                    let seriesColor = seriesColors[safe: sIndex] ?? Theme.Colors.primary
                    
                    // Area fill under line
                    Path { path in
                        for (i, v) in series.enumerated() {
                            let x = CGFloat(i) * stepX
                            let y = height - CGFloat(v / maxVal) * (height * 0.85) - height * 0.05
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: height))
                                path.addLine(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        path.addLine(to: CGPoint(x: CGFloat(series.count - 1) * stepX, y: height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [seriesColor.opacity(0.3), seriesColor.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Line stroke
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
                        seriesColor,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )
                    
                    // Data points
                    ForEach(series.indices, id: \.self) { i in
                        let v = series[i]
                        let x = CGFloat(i) * stepX
                        let y = height - CGFloat(v / maxVal) * (height * 0.85) - height * 0.05
                        
                        Circle()
                            .fill(seriesColor)
                            .frame(width: 6, height: 6)
                            .position(x: x, y: y)
                            .shadow(color: seriesColor.opacity(0.5), radius: 2)
                    }
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
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(Theme.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .stroke(Theme.Colors.divider, lineWidth: 0.5)
        )
        .shadow(
            color: Color.black.opacity(0.05),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

// Safe index helper
private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
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
