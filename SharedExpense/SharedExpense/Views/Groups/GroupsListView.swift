import SwiftUI

struct GroupsListView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var showingAddGroup = false

    var body: some View {
        NavigationStack {
            List {
                if vm.groups.isEmpty {
                    ContentUnavailableView(
                        "No Groups Yet",
                        systemImage: "person.3",
                        description: Text("Tap + to create your first expense group.")
                    )
                } else {
                    ForEach(vm.groups) { group in
                        NavigationLink(destination: GroupDetailView(group: group)) {
                            GroupRowView(group: group)
                        }
                    }
                    .onDelete(perform: vm.deleteGroup)
                }
            }
            .navigationTitle("Shared Expenses")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddGroup = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddGroup) {
                AddGroupView()
            }
        }
    }
}

// MARK: - Row

struct GroupRowView: View {
    let group: ExpenseGroup

    var body: some View {
        HStack(spacing: 14) {
            Text(group.emoji)
                .font(.largeTitle)
                .frame(width: 50, height: 50)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)
                Text("\(group.members.count) members · \(group.expenses.count) expenses")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(group.totalExpenses, format: .currency(code: currencyCode))
                    .font(.subheadline.bold())
                Text("total")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Group Sheet

struct AddGroupView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var emoji = "👥"
    @State private var memberName = ""
    @State private var members: [Person] = []

    private let emojiOptions = ["👥","✈️","🏠","🍕","🎉","🏕️","🛒","💼","🎓","❤️"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Group Info") {
                    TextField("Group name", text: $name)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(emojiOptions, id: \.self) { e in
                                Text(e)
                                    .font(.title)
                                    .padding(8)
                                    .background(emoji == e ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .onTapGesture { emoji = e }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Members") {
                    ForEach(members) { m in
                        Label(m.name, systemImage: "person")
                    }
                    .onDelete { members.remove(atOffsets: $0) }

                    HStack {
                        TextField("Add member name", text: $memberName)
                        Button("Add") {
                            let trimmed = memberName.trimmingCharacters(in: .whitespaces)
                            guard !trimmed.isEmpty else { return }
                            members.append(Person(name: trimmed))
                            memberName = ""
                        }
                        .disabled(memberName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let group = ExpenseGroup(name: name, emoji: emoji, members: members)
                        vm.addGroup(group)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    GroupsListView()
        .environmentObject(AppViewModel())
}
