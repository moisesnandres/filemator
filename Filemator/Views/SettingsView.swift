import SwiftUI

struct SettingsView: View {
    @State private var launchAtLogin = LoginItemManager.isEnabled

    var body: some View {
        Form {
            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { newValue in
                    LoginItemManager.isEnabled = newValue
                }
        }
        .padding()
    }
}
