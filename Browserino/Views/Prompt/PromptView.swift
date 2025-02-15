//
//  PromptView.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 06.06.2024.
//

import AppKit
import SwiftUI

struct PromptView: View {
    @AppStorage("browsers") private var browsers: [BrowserItem] = []
    @AppStorage("hiddenBrowsers") private var hiddenBrowsers: [BrowserItem] = []
    @AppStorage("apps") private var apps: [App] = []
    @AppStorage("shortcuts") private var shortcuts: [String: String] = [:]
    @State private var opacityAnimation = 0.0
    @State private var selected = 0
    @FocusState private var focused: Bool

    let urls: [URL]

    private func isChrome(_ bundle: Bundle) -> Bool {
        return bundle.bundleIdentifier == "com.google.Chrome"
    }

    private func filterAppsForUrls() -> [App] {
        guard let firstUrlHost = urls.first?.host() else { return [] }
        return apps.filter { app in
            app.host == firstUrlHost && !browsers.contains(where: { $0.url == app.app })
        }
    }

    var appsForUrls: [App] {
        filterAppsForUrls()
    }

    var visibleBrowsers: [BrowserItem] {
        browsers.filter { !hiddenBrowsers.contains($0) }
    }

    @ViewBuilder
    private func appItemView(app: App, index: Int) -> some View {
        if let bundle = Bundle(url: app.app) {
            PromptItem(
                browser: app.app,
                urls: urls,
                bundle: bundle,
                shortcut: shortcuts[bundle.bundleIdentifier!]
            ) {
                selected = index  // Set selection on click
            }
            .id(index)
            .buttonStyle(
                SelectButtonStyle(
                    selected: selected == index
                )
            )
        } else {
            EmptyView()
        }
    }

    private func browserItemView(browser: BrowserItem, index: Int, baseIndex: Int) -> some View {
        Group {
            if let bundle = Bundle(url: browser.url) {
                VStack(alignment: .leading, spacing: 0) {
                    Button(action: {
                        selected = baseIndex + index

                        BrowserUtil.log("\n🖱 Button clicked:", items: [
                            "🌐 Browser: \(browser.url.path)",
                            "🔍 Is Chrome: \(isChrome(bundle))",
                            "👤 Profile: \(browser.profile?.name ?? "none")",
                            "🕶 Shift pressed: \(NSEvent.modifierFlags.contains(.shift))"
                        ])

                        BrowserUtil.openURL(
                            urls,
                            app: browser.url,
                            isIncognito: NSEvent.modifierFlags.contains(.shift),
                            chromeProfile: browser.profile
                        )

                        NSApplication.shared.hide(nil)
                    }) {
                        HStack {
                            Image(nsImage: NSWorkspace.shared.icon(forFile: bundle.bundlePath))
                                .resizable()
                                .frame(width: 32, height: 32)

                            if isChrome(bundle) && browser.profile != nil {
                                Text("\(bundle.infoDictionary!["CFBundleName"] as! String) (\(browser.profile!.name))")
                                    .font(.system(size: 14))
                            } else {
                                Text(bundle.infoDictionary!["CFBundleName"] as! String)
                                    .font(.system(size: 14))
                            }

                            Spacer()

                            if let shortcut = shortcuts[bundle.bundleIdentifier!] {
                                Text(shortcut)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(
                        SelectButtonStyle(
                            selected: selected == baseIndex + index
                        )
                    )
                    .id(baseIndex + index)
                }
            } else {
                EmptyView()
            }
        }
    }

    var body: some View {
        VStack {
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(appsForUrls.enumerated()), id: \.offset) { index, app in
                            appItemView(app: app, index: index)
                        }

                        ForEach(Array(visibleBrowsers.enumerated()), id: \.offset) { index, browser in
                            browserItemView(
                                browser: browser,
                                index: index,
                                baseIndex: appsForUrls.count
                            )
                        }
                    }
                }
                .focusable()
                .focusEffectDisabled()
                .focused($focused)
                .onKeyPress { press in
                    if press.key == .upArrow {
                        selected = max(0, selected - 1)
                        scrollViewProxy.scrollTo(selected, anchor: .center)
                        return .handled
                    }

                    if press.key == .downArrow {
                        selected = min(appsForUrls.count + visibleBrowsers.count - 1, selected + 1)
                        scrollViewProxy.scrollTo(selected, anchor: .center)
                        return .handled
                    }

                    if press.key == .return {
                        if selected < appsForUrls.count {
                            let app = appsForUrls[selected]
                            BrowserUtil.openURL(urls, app: app.app, isIncognito: press.modifiers.contains(.shift))
                        } else {
                            let browser = visibleBrowsers[selected - appsForUrls.count]
                            BrowserUtil.openURL(
                                urls,
                                app: browser.url,
                                isIncognito: press.modifiers.contains(.shift),
                                chromeProfile: browser.profile
                            )
                        }
                        NSApplication.shared.hide(nil)
                        return .handled
                    }

                    return .ignored
                }
                .onAppear {
                    focused.toggle()
                    withAnimation(.interactiveSpring(duration: 0.3)) {
                        opacityAnimation = 1
                    }
                }
            }

            Divider()

            if let host = urls.first?.host() {
                Text(host)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BlurredView())
        .opacity(opacityAnimation)
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    PromptView(urls: [])
}
