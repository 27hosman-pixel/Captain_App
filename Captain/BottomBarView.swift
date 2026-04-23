import SwiftUI

struct BottomBarItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let systemImage: String
    let destination: Destination
}

struct BottomBarView: View {
    @EnvironmentObject var router: AppRouter

    private let items: [BottomBarItem] = [
        .init(title: "Home", systemImage: "house", destination: .home),
        .init(title: "Profile", systemImage: "person.crop.circle", destination: .profile),
        .init(title: "Log", systemImage: "plus.square.on.square", destination: .logSession),
        .init(title: "Stats", systemImage: "chart.bar", destination: .settings),
        .init(title: "Settings", systemImage: "gearshape", destination: .settings)
    ]

    var body: some View {
        HStack(spacing: 18) {
            ForEach(items) { item in
                Button(action: {
                    // use main queue and reset the navigation stack so we don't push duplicates
                    DispatchQueue.main.async {
                        // pop to root first to avoid deep stacking
                        router.popToRoot()
                        // then navigate to the selected destination
                        router.navigate(item.destination)
                    }
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: item.systemImage)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(router.current == item.destination ? Color.white : Color.primary)
                            .frame(width: 36, height: 36)
                            .background(
                                Group {
                                    if router.current == item.destination {
                                        Circle()
                                            .fill(LinearGradient(colors: [Color.blue, Color.blue.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .shadow(color: Color.blue.opacity(0.18), radius: 6, x: 0, y: 4)
                                    } else {
                                        Color.clear
                                    }
                                }
                            )

                        Text(item.title)
                            .font(.caption2)
                            .foregroundColor(router.current == item.destination ? Color.blue : Color.secondary)
                    }
                    .padding(.vertical, 6)
                    .frame(minWidth: 60)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, safeAreaBottomPadding())
        .background(
            VisualEffectBlur(blurStyle: .systemMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: -6)
        )
        .padding(.horizontal, 12)
    }

    // helper for bottom safe area spacing
    private func safeAreaBottomPadding() -> CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.safeAreaInsets.bottom ?? 16
    }
}

// Small visual effect blur support for SwiftUI
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

struct BottomBarView_Previews: PreviewProvider {
    static var previews: some View {
        BottomBarView()
            .previewLayout(.sizeThatFits)
            .padding()
            .environmentObject(AppRouter())
    }
}
