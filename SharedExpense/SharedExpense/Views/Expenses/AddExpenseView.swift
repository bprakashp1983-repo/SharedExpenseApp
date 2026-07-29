import SwiftUI

struct AddExpenseView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss

    let group: ExpenseGroup
    var existingExpense: Expense? = nil   // pass when editing

    @State private var title       = ""
    @State private var amountText  = ""
    @State private var date        = Date()
    @State private var note        = ""
    @State private var paidByIndex = 0
    @State private var splitMode: SplitMode = .equally
    @State private var customAmounts: [UUID: String] = [:]

    private var isEditing: Bool { existingExpense != nil }
    private var members: [Person] { group.members }

    private var totalAmount: Double { Double(amountText) ?? 0 }

    private var equalShare: Double {
        guard !members.isEmpty else { return 0 }
        return totalAmount / Double(members.count)
    }

    enum SplitMode: String, CaseIterable {
        case equally  = "Equally"
        case custom   = "Custom"
    }

    var body: some View {
        NavigationStack {
            Form {
                // Basic info
                Section("Expense Details") {
                    TextField("Title (e.g. Dinner)", text: $title)

                    HStack {
                        Text(currencySymbol)
                        TextField("Amount", text: $amountText)
                            .keyboardType(.decimalPad)
                    }

                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    TextField("Note (optional)", text: $note)
                }

                // Paid by
                Section("Paid By") {
                    if members.isEmpty {
                        Text("Add members to the group first.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Paid by", selection: $paidByIndex) {
                            ForEach(members.indices, id: \.self) { i in
                                Text(members[i].name).tag(i)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                // Split
                Section("Split") {
                    Picker("Split Mode", selection: $splitMode) {
                        ForEach(SplitMode.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)

                    if splitMode == .equally {
                        ForEach(members) { m in
                            HStack {
                                Text(m.name)
                                Spacer()
                                Text(equalShare, format: .currency(code: currencyCode))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        ForEach(members) { m in
                            HStack {
                                Text(m.name)
                                Spacer()
                                HStack(spacing: 2) {
                                    Text(currencySymbol).foregroundStyle(.secondary)
                                    TextField("0", text: customBinding(for: m.id))
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 80)
                                }
                            }
                        }

                        let remaining = totalAmount - customTotal
                        HStack {
                            Text("Remaining")
                                .foregroundStyle(abs(remaining) < 0.005 ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.red))
                            Spacer()
                            Text(remaining, format: .currency(code: currencyCode))
                                .foregroundStyle(abs(remaining) < 0.005 ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.red))
                        }
                        .font(.footnote)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Expense" : "New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveExpense()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear(perform: populateIfEditing)
        }
    }

    // MARK: - Helpers

    private var customTotal: Double {
        customAmounts.values.compactMap { Double($0) }.reduce(0, +)
    }

    private var canSave: Bool {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty,
              totalAmount > 0,
              !members.isEmpty else { return false }
        if splitMode == .custom {
            return abs(customTotal - totalAmount) < 0.005
        }
        return true
    }

    private func customBinding(for id: UUID) -> Binding<String> {
        Binding(
            get: { customAmounts[id] ?? "" },
            set: { customAmounts[id] = $0 }
        )
    }

    private func populateIfEditing() {
        guard let e = existingExpense else { return }
        title = e.title
        amountText = String(format: "%.2f", e.totalAmount)
        date = e.date
        note = e.note
        paidByIndex = members.firstIndex { $0.id == e.paidByPersonID } ?? 0

        let isEqual = e.splits.allSatisfy { abs($0.amount - e.splits[0].amount) < 0.005 }
        splitMode = isEqual ? .equally : .custom
        for split in e.splits {
            customAmounts[split.personID] = String(format: "%.2f", split.amount)
        }
    }

    private func saveExpense() {
        let payer = members[paidByIndex]
        let splits: [Split]

        if splitMode == .equally {
            splits = members.map { Split(personID: $0.id, amount: equalShare) }
        } else {
            splits = members.compactMap { m in
                guard let amt = Double(customAmounts[m.id] ?? "") else { return nil }
                return Split(personID: m.id, amount: amt)
            }
        }

        if isEditing, let old = existingExpense {
            let updated = Expense(
                id: old.id,
                title: title.trimmingCharacters(in: .whitespaces),
                date: date,
                totalAmount: totalAmount,
                paidByPersonID: payer.id,
                splits: splits,
                note: note
            )
            vm.updateExpense(updated, in: group.id)
        } else {
            let expense = Expense(
                title: title.trimmingCharacters(in: .whitespaces),
                date: date,
                totalAmount: totalAmount,
                paidByPersonID: payer.id,
                splits: splits,
                note: note
            )
            vm.addExpense(expense, to: group.id)
        }
        dismiss()
    }
}
