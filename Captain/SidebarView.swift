import SwiftUI

struct SidebarItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let systemImage: String
}

struct SidebarView: View {
    @EnvironmentObject var router: AppRouter
    @State private var selected: SidebarItem?

    private let items: [SidebarItem] = [
        .init(title: "Home", systemImage: "house"),
        .init(title: "My Profile", systemImage: "person.circle"),
        .init(title: "Log New Session", systemImage: "video"),
        .init(title: "Recruiter Mode", systemImage: "magnifyingglass"),
        .init(title: "Season Stats", systemImage: "chart.bar"),
        .init(title: "Sync Health Data", systemImage: "heart.text.square"),
        .init(title: "Settings", systemImage: "gearshape")
    ]

    var body: some View {
        GeometryReader { geom in
            ZStack(alignment: .leading) {
                // Soft gradient background for the sidebar
                LinearGradient(gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6)]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)

                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack(alignment: .center, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color.blue.opacity(0.15), Color.blue.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 64, height: 64)

                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.blue)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Captain")
                                .font(.title2).bold()
                                .foregroundColor(.primary)
                            Text("Welcome back")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 36)
                    .padding(.bottom, 18)

                    // Divider
                    Divider()
                        .padding(.vertical, 8)

                    // Menu items
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(items) { item in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.18)) {
                                        selected = item
                                    }
                                    // route actions for core items
                                    switch item.title {
                                    case "Home":
                                        router.navigate(.home)
                                    case "My Profile":
                                        router.navigate(.profile)
                                    case "Log New Session":
                                        router.navigate(.logSession)
                                    case "Settings":
                                        router.navigate(.settings)
                                    default:
                                        break
                                    }
                                }) {
                                    HStack(spacing: 14) {
                                        Image(systemName: item.systemImage)
                                            .font(.system(size: 20, weight: .regular))
                                            .frame(width: 32, height: 32)
                                            .foregroundColor(selected == item ? .white : .primary)

                                        Text(item.title)
                                            .font(.system(size: 18, weight: .regular))
                                            .foregroundColor(selected == item ? .white : .primary)

                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 12)
                                    .background(
                                        Group {
                                            if selected == item {
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .fill(LinearGradient(colors: [Color.blue, Color.blue.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                                    .shadow(color: Color.blue.opacity(0.18), radius: 8, x: 0, y: 6)
                                            } else {
                                                Color.clear
                                            }
                                        }
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, 12)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }

                    Spacer()

                    // Footer actions
                    VStack(alignment: .leading, spacing: 10) {
                        Button(action: {
                            // placeholder for sign out
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrowshape.turn.up.left")
                                    .font(.system(size: 18))
                                    .foregroundColor(.red)
                                Text("Sign Out")
                                    .foregroundColor(.red)
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Text("v0.1.0")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.leading, 14)
                            .padding(.bottom, 18)
                    }
                }
                .frame(width: min(320, geom.size.width * 0.86))
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 10)
                )
                .padding(.leading, 16)
                .padding(.vertical, 24)
            }
        }
    }
}

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SidebarView()
                .previewLayout(.sizeThatFits)
                .environment(\.colorScheme, .light)
                .frame(width: 320)
                .environmentObject(AppRouter())

            SidebarView()
                .previewLayout(.sizeThatFits)
                .environment(\.colorScheme, .dark)
                .frame(width: 320)
                .preferredColorScheme(.dark)
                .environmentObject(AppRouter())
        }
    }
}
