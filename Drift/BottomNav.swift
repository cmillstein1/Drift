import SwiftUI

struct BottomNav: View {
    @Binding var activeTab: String
    let onTabChange: (String) -> Void
    
    // Color definitions matching the design system
    private let burntOrange = Color(red: 0.80, green: 0.40, blue: 0.20) // #CC6633
    private let charcoal = Color(red: 0.2, green: 0.2, blue: 0.2) // #333333
    
    struct TabItem {
        let id: String
        let label: String
        let icon: String
    }
    
    private let tabs: [TabItem] = [
        TabItem(id: "discover", label: "Discover", icon: "heart"),
        TabItem(id: "activities", label: "Activities", icon: "calendar"),
        TabItem(id: "builder", label: "Builder", icon: "wrench"),
        TabItem(id: "messages", label: "Messages", icon: "message"),
        TabItem(id: "profile", label: "Profile", icon: "person")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.2))
            
            HStack(spacing: 0) {
                ForEach(tabs, id: \.id) { tab in
                    Button(action: {
                        onTabChange(tab.id)
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 24, weight: .regular))
                                .foregroundColor(activeTab == tab.id ? burntOrange : charcoal.opacity(0.4))
                                .animation(.easeInOut(duration: 0.2), value: activeTab)
                            
                            Text(tab.label)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(activeTab == tab.id ? burntOrange : charcoal.opacity(0.4))
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
        .background(.ultraThinMaterial)
        .background(Color.white.opacity(0.95))
        .frame(maxWidth: .infinity)
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
