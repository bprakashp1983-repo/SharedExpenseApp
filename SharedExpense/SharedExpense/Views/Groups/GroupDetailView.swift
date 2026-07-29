import SwiftUI

struct GroupDetailView: View {
    @EnvironmentObject var vm: AppViewModel
    let group: ExpenseGroup

    // Always read the live group from vm so updates reflect instantly
    private var liveGroup: ExpenseGroup {
        vm.groups.first { $0.id == group.id } ?? group
    }

    @State private var showingAddExpense = false
    @State private var showingAddMember  = false
    @State private var selectedTab = 0

    var body: some View {
        let g = liveGroup
        VStack(spacing: 0) {
            // Summary card
            GroupSummaryCard(group: g)
                .padding()

            Picker("", selection: $selectedTab) {
                Text("Expenses").tag(0)
                Text("Members").tag(1)
                Text("Balances").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Divider().padding(.top, 8)

            TabView(selection: $selectedTab) {
                ExpensesTabView(group: g)
                    .tag(0)
                MembersTabView(group: g)
                    .tag(1)
                BalancesView(group: g)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle(g.emoji + " " + g.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingAddExpense = true
                    } label: {
                        Label("Add Expense", systemImage: "plus.circle")
                    }
                    Button {
                        showingAddMember = true
                    } label: {
                        Label("Add Member", systemImage: "person.badge.plus")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(group: liveGroup)
        }
        .sheet(isPresented: $showingAddMember) {
            AddMemberView(groupID: group.id)
        }
    }
}

// MARK: - Summary Card

struct GroupSummaryCard: View {
    let group: ExpenseGroup

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Spent")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(group.totalExpenses, format: .currency(code: currencyCode))
                    .font(.title2.bold())
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Members")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(group.members.count)")
                    .font(.title2.bold())
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Expenses")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(group.expenses.count)")
                    .font(.title2.bold())
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Expenses Tab

struct ExpensesTabView: View {
    @EnvironmentObject var vm: AppViewModel
    let group: ExpenseGroup

    var body: some View {
        List {
            if group.expenses.isEmpty {
                ContentUnavailableView(
                    "No Expenses",
                    systemImage: "creditcard",
                    description: Text("Tap + to add the first expense.")
                )
            } else {
                ForEach(group.expenses.sorted { $0.date > $1.date }) { expense in
                    NavigationLink(destination: ExpenseDetailView(expense: expense, group: group)) {
                        ExpenseRowView(expense: expense, group: group)
                    }
                }
                .onDelete { offsets in
                    let sorted = group.expenses.sorted { $0.date > $1.date }
                    for i in offsets {
                        vm.deleteExpense(expenseID: sorted[i].id, from: group.id)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

struct ExpenseRowView: View {
    let expense: Expense
    let group: ExpenseGroup

    private var payer: String {
        group.members.first { $0.id == expense.paidByPersonID }?.name ?? "Unknown"
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "creditcard.fill")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(expense.title)
                    .font(.headline)
                HStack(spacing: 4) {
                    Text("Paid by \(payer)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(expense.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(expense.totalAmount, format: .currency(code: currencyCode))
                .font(.subheadline.bold())
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Members Tab

struct MembersTabView: View {
    @EnvironmentObject var vm: AppViewModel
    let group: ExpenseGroup

    var body: some View {
        List {
            ForEach(group.members) { member in
                Label(member.name, systemImage: "person.circle.fill")
            }
            .onDelete { offsets in
                let ids = offsets.map { group.members[$0].id }
                ids.forEach { vm.deleteMember(personID: $0, from: group.id) }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Add Member Sheet

struct AddMemberView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss
    let groupID: UUID
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Member name", text: $name)
            }
            .navigationTitle("Add Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        vm.addMember(Person(name: name.trimmingCharacters(in: .whitespaces)), to: groupID)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
