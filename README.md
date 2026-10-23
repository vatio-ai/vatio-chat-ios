# Vatio Chat for iOS

A ChatGPT-style chat app for a [Vatio](https://vatio.ai) agent, in SwiftUI,
built on the [Vatio iOS SDK](https://github.com/vatio-ai/ios). Out of the box
it talks to Vatio's own agent, the one on vatio.ai; one file points it at
yours.

It is also a reference for putting a Vatio agent in your own iOS app. Each
file does one thing and says why it does it that way, so you, or the coding
agent working on your app, can find the part you need and copy it.

The quickest way to put an agent in your own app is `npx @vatio-ai/skills`,
then `/vatio-init` and `/vatio-add-to-app` in Claude Code.

## Features

- **Chat** with the agent: its replies rendered as Markdown (paragraphs,
  lists, code blocks, links), typing dots while it writes, and the list
  scrolled to the newest message.
- **A welcome screen** with the agent's avatar, greeting and suggested
  questions, from its configuration.
- **Photos and voice notes:** up to four photos per message from the photo
  picker, or a voice note recorded in the app, which Vatio transcribes.
- **Past conversations** in a drawer, as in ChatGPT, and a new chat button.
- **Visitor feedback:** the card Vatio asks for when a request looks resolved.
- **Settings** for the workspace, token and base URL, and a visitor token to
  try the agent as a signed-in user.
- Light and dark mode, in the agent's accent color.

## Run it

You need Xcode 16 or later, and an iOS 17 simulator or device.

```bash
git clone https://github.com/vatio-ai/vatio-chat-ios
cd vatio-chat-ios
open VatioChat.xcodeproj
```

Press ⌘R. Xcode fetches the Vatio package the first time. To build from the
command line instead:

```bash
xcodebuild -project VatioChat.xcodeproj -scheme VatioChat \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

On a device, pick your team under **Signing & Capabilities**.

## Point it at your own agent

A publishable key only works from the origins it allows, and an iOS app's
origin is `ios-app://` plus its bundle id: `ios-app://ai.vatio.chat` for this
one (Settings shows it under About).

1. Create a publishable key that allows it:

   ```bash
   vatio keys create publishable --env preview --origin ios-app://ai.vatio.chat
   ```

   Or add the origin to a key you already have under
   **Settings → API keys** in the inbox. If you change the bundle id, the
   origin changes with it.
2. Put your workspace and the token in `VatioChat/AppConfig.swift`, or paste
   them in the app's Settings.

A `vatpub_` key is meant to ship inside an app. A `vat_` token is a developer
secret: never put one in an app.

To try private tools, paste a visitor token in **Settings → Signed-in user**:
a JWT your backend signs for a user, as described in
[Sessions and channels](https://vatio.ai/docs/authentication/sessions). In a
real app it comes from your backend after your own sign-in.

## File tour

Start with `ChatStore.swift`: everything the app does with the SDK goes
through it.

| File | What it shows how to do |
|---|---|
| `VatioChat/AppConfig.swift` | Ship a default agent: workspace, publishable key and base URL in one place. |
| `VatioChat/ChatStore.swift` | Own the `Vatio` client and the current `VatioChat`; make a new chat when the settings or the visitor token change; load `config()` and `conversations(visitorToken:)`; send, open, rate; turn a `VatioError` into a message (`origin_not_allowed` included). |
| `VatioChat/AppSettings.swift` | Keep the workspace, token, base URL and visitor token in `UserDefaults`. |
| `VatioChat/VatioChatApp.swift` | Create the store once, for the life of the app. |
| `VatioChat/Views/RootView.swift` | Follow a chat swap: the chat screen is keyed by the chat's identity, so a new chat gets a new view that observes it. Also the drawer, the settings sheet and the error banner. |
| `VatioChat/Views/ChatView.swift` | The chat screen: the agent's name and connection status in the top bar, `resume()` when a chat appears, `lastError` shown as a banner. |
| `VatioChat/Views/MessageList.swift` | Observe `messages`, `isTyping` and `feedback`, and keep the newest in view. |
| `VatioChat/Views/EmptyState.swift` | A welcome screen from `VatioConfig`: avatar, greeting, suggestions that send themselves. |
| `VatioChat/Views/AgentAvatar.swift` | The agent's `avatarURL`, else its initial on its accent color. |
| `VatioChat/Views/MessageRow.swift` | Draw the visitor's and the agent's messages differently; dim `isPending`; skip the `isMediaLabel` stand-in. |
| `VatioChat/Views/AttachmentView.swift` | Draw a `VatioAttachment`: a thumbnail from its signed `url`, or a chip. |
| `VatioChat/Views/MarkdownText.swift` | Render a reply's Markdown as untrusted text, without a library: blocks parsed by hand, inline styles from `AttributedString`, only web, mail and phone links. |
| `VatioChat/Views/TypingIndicator.swift` | Typing dots for `isTyping`. |
| `VatioChat/Views/FeedbackCard.swift` | Answer Vatio's feedback moment with `rate(_:comment:)` or `dismissFeedback()`. |
| `VatioChat/Views/Composer.swift` | Send text, photos and voice notes; put the draft back when `send` throws; the 4-file and 4,000-character limits. |
| `VatioChat/DraftAttachment.swift` | Turn a picked photo into a `VatioUpload`: JPEG, at most 2048 px, well under 8 MB. |
| `VatioChat/VoiceRecorder.swift` | Record a voice note to .m4a with `AVAudioRecorder`, asking for the microphone first. |
| `VatioChat/Views/ConversationsSidebar.swift` | List the visitor's past conversations and switch with `chat.open(_:)`. |
| `VatioChat/Views/SettingsView.swift` | Change the agent and the visitor token, and show the origin the key must allow. |
| `VatioChat/Views/NoticeBanner.swift` | Show an error briefly. |
| `VatioChat/HexColor.swift` | Read the agent's `#RRGGBB` accent color. |
| `project.yml` | The Xcode project, for XcodeGen. |

## The Xcode project

`VatioChat.xcodeproj` is generated from `project.yml` by
[XcodeGen](https://github.com/yonaskolb/XcodeGen). After adding or removing
files, regenerate it from this folder:

```bash
brew install xcodegen   # once
xcodegen generate
```

## More

- [iOS SDK documentation](https://vatio.ai/docs/sdk/ios)
- [The SDK package and its README](https://github.com/vatio-ai/ios)
- [Vatio](https://vatio.ai)

## Issues

Bugs and questions go to [issues](https://github.com/vatio-ai/vatio-chat-ios/issues).
This repository is a read-only mirror of Vatio Chat as it lives in Vatio's
monorepo, so a pull request cannot be merged here: open an issue describing
the change instead.

## License

MIT. See [LICENSE](LICENSE).
