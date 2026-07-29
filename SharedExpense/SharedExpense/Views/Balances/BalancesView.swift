import SwiftUI

struct BalancesView: View {
    @EnvironmentObject var vm: AppViewModel
    let group: ExpenseGroup

    private var liveGroup: ExpenseGroup {
        vm.groups.first { $0.id == group.id } ?? group
    }

    var body: some View {
        let g = liveGroup
        let balances = g.balances()
        let settlements = g.settlements()

        List {
            // Per-person balance
            Section("Net Balances") {
                if g.members.isEmpty {
                    Text("No members yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(g.members) { member in
                        let amount = balances[member.id] ?? 0
                        HStack {
                            Label(member.name, systemImage: "person.circle.fill")
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(abs(amount), format: .currency(code: currencyCode))
                                    .foregroundStyle(amount >= 0 ? .green : .red)
                                    .bold()
                                Text(amount >= 0 ? "gets back" : "owes")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            // Suggested settlements
            Section("Suggested Settlements") {
                if settlements.isEmpty {
                    Label("Everyone is settled up!", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                } else {
                    ForEach(settlements) { s in
                        let from = g.members.first { $0.id == s.fromPersonID }?.name ?? "?"
                        let to   = g.members.first { $0.id == s.toPersonID   }?.name ?? "?"
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 4) {
                                    Text(from).bold()
                                    Image(systemName: "arrow.right")
                                    Text(to).bold()
                                }
                                Text("should pay")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(s.amount, format: .currency(code: currencyCode))
                                .font(.subheadline.bold())
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

#Preview {
    let vm = AppViewModel()
    return BalancesView(group: vm.groups[0])
        .environmentObject(vm)
}
