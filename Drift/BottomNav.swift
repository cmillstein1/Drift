import SwiftUI
import UIKit

struct BottomNav: View {
    @Binding var activeTab: String
    let onTabChange: (String) -> Void
    
    // Color definitions matching the design system
    private let burntOrange = Color("BurntOrange")
    private let charcoal = Color("Charcoal")
    
    struct TabItem {
        let id: String
        let label: String
        let icon: String
    }
    
    private let tabs: [TabItem] = [
        TabItem(id: "discover", label: "Discover", icon: "discover_rv"),
        TabItem(id: "community", label: "Community", icon: "person.3"),
        TabItem(id: "messages", label: "Messages", icon: "message"),
        TabItem(id: "profile", label: "Profile", icon: "person")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(tabs, id: \.id) { tab in
                    Button(action: {
                        onTabChange(tab.id)
                    }) {
                        VStack(spacing: 4) {
                            if tab.icon == "discover_rv" {
                                Image(tab.icon)
                                    .resizable()
                                    .renderingMode(.template)
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(activeTab == tab.id ? burntOrange : charcoal)
                                    .animation(.easeInOut(duration: 0.2), value: activeTab)
                            } else {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 24, weight: .regular))
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(activeTab == tab.id ? burntOrange : charcoal)
                                    .animation(.easeInOut(duration: 0.2), value: activeTab)
                            }
                            
                            Text(tab.label)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(activeTab == tab.id ? burntOrange : charcoal)
                                .frame(height: 14)
                                .animation(.easeInOut(duration: 0.2), value: activeTab)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(Color.white)
        .clipShape(BottomNavRoundedCorner(radius: 24, corners: [.topLeft, .topRight]))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: -4)
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Rounded Corner Shape for BottomNav
private struct BottomNavRoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var activeTab = "discover"
        
        var body: some View {
            ZStack {
                Color.gray.opacity(0.1)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    Text("Active Tab: \(activeTab)")
                        .padding()
                    
                    Spacer()
                    
                    BottomNav(activeTab: $activeTab) { tab in
                        activeTab = tab
                    }
                }
            }
        }
    }
    
    return PreviewWrapper()
}
