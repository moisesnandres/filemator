import ServiceManagement

enum LoginItemManager {
    static var isEnabled: Bool {
        get {
            SMAppService.mainApp.status == .enabled
        }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Registration failures (e.g. user declined in System Settings) leave
                // isEnabled unchanged; the toggle will simply reflect actual status
                // the next time this getter is read.
            }
        }
    }
}
