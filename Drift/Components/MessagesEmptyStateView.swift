//
//  MessagesEmptyStateView.swift
//  Drift
//

import SwiftUI

struct MessagesEmptyStateView: View {
    let mode: MessageMode
    let onFindFriends: () -> Void

    private let charcoalColor = Color("Charcoal")
    private let burntOrange = Color("BurntOrange")

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image("Message_Empty_State")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 260, maxHeight: 260)

                VStack(spacing: 10) {
                    Text("No messages right now")
                        .font(.campfire(.regular, size: 24))
                        .foregroundColor(charcoalColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Text(mode == .dating
                         ? "Matches are more intentional on Drift. Discover someone new to get the conversation started."
                         : "Start a conversation with a friend, or discover other travelers nearby.")
                        .font(.campfire(.regular, size: 16))
                        .foregroundColor(charcoalColor.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)

                    Button(action: onFindFriends) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text(mode == .dating ? "Find Matches" : "Find friends")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(burntOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
