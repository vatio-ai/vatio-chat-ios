import SwiftUI
import UIKit

/// The frame around the chat: the conversations drawer that slides over it,
/// the settings sheet and the error banner. These live outside `ChatView` so
/// that swapping the chat, which rebuilds `ChatView`, leaves them alone.
@MainActor
struct RootView: View {
    @ObservedObject var store: ChatStore

    @State private var isDrawerOpen = false
    @State private var isShowingSettings = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                NavigationStack {
                    // Keyed by the chat's identity: a new chat is a new view,
                    // which observes it and resumes it.
                    ChatView(store: store, chat: store.chat, onOpenDrawer: openDrawer)
                        .id(ObjectIdentifier(store.chat))
                }

                if isDrawerOpen {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture(perform: closeDrawer)
                        .transition(.opacity)
                        .zIndex(1)

                    ConversationsSidebar(
                        conversations: store.conversations,
                        currentID: store.chat.conversationID,
                        isLoading: store.isLoadingConversations,
                        onNewChat: {
                            store.startNewChat()
                            closeDrawer()
                        },
                        onSelect: { conversation in
                            closeDrawer()
                            Task { await store.open(conversation) }
                        },
                        onSettings: {
                            closeDrawer()
                            isShowingSettings = true
                        }
                    )
                    .frame(width: min(geometry.size.width * 0.85, 320))
                    .transition(.move(edge: .leading))
                    .zIndex(2)
                }
            }
        }
        .tint(store.accent)
        .overlay(alignment: .top) {
            if let notice = store.notice {
                NoticeBanner(text: notice)
                    .onTapGesture { store.notice = nil }
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: store.notice)
        .sheet(isPresented: $isShowingSettings) {
            SettingsView(store: store)
        }
    }

    private func openDrawer() {
        // The keyboard would cover the bottom of the drawer.
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        withAnimation(.easeOut(duration: 0.25)) { isDrawerOpen = true }
        Task { await store.loadConversations() }
    }

    private func closeDrawer() {
        withAnimation(.easeOut(duration: 0.25)) { isDrawerOpen = false }
    }
}
