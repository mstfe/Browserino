//
//  BrowsersTab.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 10.06.2024.
//

import SwiftUI

struct BrowsersTab: View {
    @AppStorage("browsers") private var browsers: [BrowserItem] = []
    @AppStorage("hiddenBrowsers") private var hiddenBrowsers: [BrowserItem] = []
    @AppStorage("privateArgs") private var privateArgs: [String: String] = [:]
    @AppStorage("shortcuts") private var shortcuts: [String: String] = [:]
    @State private var chromeProfiles: [ChromeProfile] = []

    private func move(from source: IndexSet, to destination: Int) {
        browsers.move(fromOffsets: source, toOffset: destination)
    }

    private func shortcutKey(for browser: BrowserItem, bundleId: String) -> String {
        if let profile = browser.profile {
            return "\(bundleId)_\(profile.id)"
        }
        return bundleId
    }

    private func privateArg(for key: String) -> Binding<String> {
        return .init(
            get: { self.privateArgs[key, default: ""] },
            set: { self.privateArgs[key] = $0 })
    }

    private func isChrome(_ bundle: Bundle) -> Bool {
        return bundle.bundleIdentifier == "com.google.Chrome"
    }

    var body: some View {
        VStack (alignment: .leading) {
            List {
                ForEach(Array(browsers.enumerated()), id: \.offset) { offset, browser in
                    if let bundle = Bundle(url: browser.url) {
                        HStack {
                            Text((offset + 1).formatted())
                                .font(.system(size: 16))
                                .frame(width: 30, alignment: .leading)

                            Image(nsImage: NSWorkspace.shared.icon(forFile: bundle.bundlePath))
                                .resizable()
                                .frame(width: 32, height: 32)

                            Spacer().frame(width: 8)

                            if isChrome(bundle) && browser.profile != nil {
                                Text("\(bundle.infoDictionary!["CFBundleName"] as! String) (\(browser.profile!.name))")
                                    .font(.system(size: 14))
                            } else {
                                Text(bundle.infoDictionary!["CFBundleName"] as! String)
                                    .font(.system(size: 14))
                            }

                            Spacer().frame(width: 32)

                            TextField(
                                "Private argument",
                                text: privateArg(for: bundle.bundleIdentifier!)
                            )
                                .font(.system(size: 14).monospaced())

                            Spacer().frame(width: 32)

                            ShortcutButton(
                                browserId: shortcutKey(for: browser, bundleId: bundle.bundleIdentifier!)
                            )

                            Spacer().frame(width: 8)

                            Button(action: {
                                if hiddenBrowsers.contains(browser) {
                                    hiddenBrowsers.removeAll { $0.id == browser.id }
                                } else {
                                    hiddenBrowsers.append(browser)
                                }
                            }) {
                                Image(systemName: hiddenBrowsers.contains(browser) ? "eye.slash.fill" : "eye.fill")
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                    }
                }
                .onMove(perform: move)
            }
            .onAppear {
                if browsers.isEmpty {
                    browsers = BrowserUtil.loadBrowsers()
                }
                chromeProfiles = BrowserUtil.getChromeProfiles()
            }

            Text("Drag and drop to reorder. Press record to assign a shortcut")
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.5))
                .frame(maxWidth: .infinity)
        }
        .padding(.bottom, 20)
    }
}


#Preview {
    PreferencesView()
}
