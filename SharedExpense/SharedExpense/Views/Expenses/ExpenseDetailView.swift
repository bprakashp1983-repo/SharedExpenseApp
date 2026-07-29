import SwiftUI

struct ExpenseDetailView: View {
    @EnvironmentObject var vm: AppViewModel
    let expense: Expense
    let group: ExpenseGroup

    @State private var showingEdit = false

    private var liveGroup: ExpenseGroup {
        vm.groups.first { $0.id == group.id } ?? group
    }

    private var liveExpense: Expense? {
        liveGroup.expenses.first { $0.id == expense.id }
    }

    private var payer: String {
        liveGroup.members.first { $0.id == expense.paidByPersonID }?.name ?? "Unknown"
    }

    var body: some View {
        let e = liveExpense ?? expense
        List {
            Section("Summary") {
                LabeledContent("Title", value: e.title)
                LabeledContent("Amount") {
                    Text(e.totalAmount, format: .currency(code: currencyCode))
                        .bold()
                }
                LabeledContent("Paid by", value: payer)
                LabeledContent("Date", value: e.date.formatted(date: .long, time: .omitted))
                if !e.note.isEmpty {
                    LabeledContent("Note", value: e.note)
                }
            }

            Section("Split Breakdown") {
                ForEach(e.splits) { split in
                    let name = liveGroup.members.first { $0.id == split.personID }?.name ?? "?"
                    HStack {
                        Label(name, systemImage: "person")
                        Spacer()
                        Text(split.amount, format: .currency(code: currencyCode))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Expense Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            if let e = liveExpense {
                AddExpenseView(group: liveGroup, existingExpense: e)
            }
        }
    }
}
