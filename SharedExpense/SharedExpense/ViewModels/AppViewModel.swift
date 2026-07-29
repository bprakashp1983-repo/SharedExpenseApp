import Foundation
import Combine

class AppViewModel: ObservableObject {
    @Published var groups: [ExpenseGroup] = []

    private let saveKey = "shared_expense_groups"

    init() {
        load()
        if groups.isEmpty {
            groups = Self.sampleData()
        }
    }

    // MARK: - Group CRUD

    func addGroup(_ group: ExpenseGroup) {
        groups.append(group)
        save()
    }

    func updateGroup(_ group: ExpenseGroup) {
        if let idx = groups.firstIndex(where: { $0.id == group.id }) {
            groups[idx] = group
            save()
        }
    }

    func deleteGroup(at offsets: IndexSet) {
        groups.remove(atOffsets: offsets)
        save()
    }

    // MARK: - Member helpers

    func addMember(_ person: Person, to groupID: UUID) {
        modify(groupID: groupID) { $0.members.append(person) }
    }

    func deleteMember(personID: UUID, from groupID: UUID) {
        modify(groupID: groupID) { group in
            group.members.removeAll { $0.id == personID }
        }
    }

    // MARK: - Expense CRUD

    func addExpense(_ expense: Expense, to groupID: UUID) {
        modify(groupID: groupID) { $0.expenses.append(expense) }
    }

    func updateExpense(_ expense: Expense, in groupID: UUID) {
        modify(groupID: groupID) { group in
            if let idx = group.expenses.firstIndex(where: { $0.id == expense.id }) {
                group.expenses[idx] = expense
            }
        }
    }

    func deleteExpense(expenseID: UUID, from groupID: UUID) {
        modify(groupID: groupID) { group in
            group.expenses.removeAll { $0.id == expenseID }
        }
    }

    // MARK: - Helpers

    func person(id: UUID, in group: ExpenseGroup) -> Person? {
        group.members.first { $0.id == id }
    }

    // MARK: - Private

    private func modify(groupID: UUID, transform: (inout ExpenseGroup) -> Void) {
        if let idx = groups.firstIndex(where: { $0.id == groupID }) {
            transform(&groups[idx])
            save()
        }
    }

    // MARK: - Persistence (UserDefaults)

    private func save() {
        if let encoded = try? JSONEncoder().encode(groups) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([ExpenseGroup].self, from: data) {
            groups = decoded
        }
    }

    // MARK: - Sample data

    static func sampleData() -> [ExpenseGroup] {
        let alice = Person(name: "Alice")
        let bob   = Person(name: "Bob")
        let carol = Person(name: "Carol")

        let total = 90.0
        let share = total / 3.0

        let expense = Expense(
            title: "Dinner at Olive Garden",
            totalAmount: total,
            paidByPersonID: alice.id,
            splits: [
                Split(personID: alice.id, amount: share),
                Split(personID: bob.id,   amount: share),
                Split(personID: carol.id, amount: share)
            ]
        )

        var group = ExpenseGroup(
            name: "Weekend Trip",
            emoji: "✈️",
            members: [alice, bob, carol]
        )
        group.expenses = [expense]
        return [group]
    }
}
