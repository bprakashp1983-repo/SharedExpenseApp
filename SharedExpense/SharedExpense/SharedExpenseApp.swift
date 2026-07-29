import SwiftUI

@main
struct SharedExpenseApp: App {
    @StateObject private var vm = AppViewModel()

    var body: some Scene {
        WindowGroup {
            GroupsListView()
                .environmentObject(vm)
        }
    }
}
