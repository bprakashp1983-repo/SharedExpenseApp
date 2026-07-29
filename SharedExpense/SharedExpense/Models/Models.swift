import Foundation

// MARK: - Person

struct Person: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

// MARK: - Split

/// Represents how much of an expense one person owes.
struct Split: Identifiable, Codable, Hashable {
    var id: UUID
    var personID: UUID
    /// Amount this person owes for the expense
    var amount: Double

    init(id: UUID = UUID(), personID: UUID, amount: Double) {
        self.id = id
        self.personID = personID
        self.amount = amount
    }
}

// MARK: - Expense

struct Expense: Identifiable, Codable {
    var id: UUID
    var title: String
    var date: Date
    /// Total cost of the expense
    var totalAmount: Double
    /// The person who paid
    var paidByPersonID: UUID
    /// How the cost is split among participants
    var splits: [Split]
    /// Optional note
    var note: String

    init(
        id: UUID = UUID(),
        title: String,
        date: Date = Date(),
        totalAmount: Double,
        paidByPersonID: UUID,
        splits: [Split],
        note: String = ""
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.totalAmount = totalAmount
        self.paidByPersonID = paidByPersonID
        self.splits = splits
        self.note = note
    }
}

// MARK: - Group

struct ExpenseGroup: Identifiable, Codable {
    var id: UUID
    var name: String
    var emoji: String
    var members: [Person]
    var expenses: [Expense]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        emoji: String = "👥",
        members: [Person] = [],
        expenses: [Expense] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.members = members
        self.expenses = expenses
        self.createdAt = createdAt
    }

    // MARK: Computed helpers

    var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.totalAmount }
    }

    /// Net balance for each member:  positive = is owed money, negative = owes money
    func balances() -> [UUID: Double] {
        var bal: [UUID: Double] = [:]
        for m in members { bal[m.id] = 0 }

        for expense in expenses {
            // Payer gets credit for the full amount
            bal[expense.paidByPersonID, default: 0] += expense.totalAmount
            // Each participant is debited their share
            for split in expense.splits {
                bal[split.personID, default: 0] -= split.amount
            }
        }
        return bal
    }

    /// Simplified list of settlements: who pays whom how much
    func settlements() -> [Settlement] {
        var bal = balances()
        var result: [Settlement] = []

        while true {
            // Find the biggest creditor and biggest debtor
            guard
                let maxCred = bal.max(by: { $0.value < $1.value }),
                let maxDeb  = bal.min(by: { $0.value < $1.value }),
                maxCred.value > 0.005,
                maxDeb.value  < -0.005
            else { break }

            let amount = min(maxCred.value, -maxDeb.value)
            result.append(Settlement(
                fromPersonID: maxDeb.key,
                toPersonID: maxCred.key,
                amount: amount
            ))
            bal[maxCred.key]! -= amount
            bal[maxDeb.key]!  += amount
        }
        return result
    }
}

// MARK: - Settlement

struct Settlement: Identifiable {
    var id = UUID()
    var fromPersonID: UUID
    var toPersonID: UUID
    var amount: Double
}
