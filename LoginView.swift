import SwiftUI

struct LoginView: View {
    @AppStorage("ttg_started") private var started = false
    @State private var showCreate = false
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.08, green: 0.12, blue: 0.25), .black, Color(red: 0.28, green: 0.13, blue: 0.32)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            VStack(spacing: 18) {
                Spacer()
                Text("☯").font(.system(size: 66)).foregroundStyle(.orange)
                Text("TU TIÊN GIỚI").font(.system(size: 34, weight: .black, design: .rounded)).foregroundStyle(.white)
                Text("Con đường tu luyện bắt đầu từ đây").foregroundStyle(.white.opacity(0.72))
                Spacer()
                Button { showCreate = true } label: {
                    Text("TẠO NHÂN VẬT").fontWeight(.bold).frame(maxWidth: .infinity).padding().background(.orange).foregroundStyle(.black).clipShape(RoundedRectangle(cornerRadius: 14))
                }
                Button { started = true } label: {
                    Text("VÀO GAME THỬ").fontWeight(.semibold).frame(maxWidth: .infinity).padding().background(.white.opacity(0.12)).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 14))
                }
                Text("Bản thử nghiệm offline").font(.caption).foregroundStyle(.white.opacity(0.45))
            }.padding(28)
        }
        .sheet(isPresented: $showCreate) { CharacterCreateView { started = true } }
    }
}

struct CharacterCreateView: View {
    var onFinish: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var gender = "Nam"
    @State private var sect: Sect = .kiem
    var body: some View {
        NavigationStack {
            Form {
                Section("Thông tin nhân vật") {
                    TextField("Tên nhân vật", text: $name).textInputAutocapitalization(.never).autocorrectionDisabled()
                    Picker("Giới tính", selection: $gender) {
                        Text("Nam").tag("Nam")
                        Text("Nữ").tag("Nữ")
                    }.pickerStyle(.segmented)
                }
                Section("Chọn môn phái") {
                    ForEach(Sect.allCases) { item in
                        Button { sect = item } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.rawValue).fontWeight(.bold)
                                    Text(item.description).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if sect == item { Image(systemName: "checkmark.circle.fill").foregroundStyle(.orange) }
                            }.contentShape(Rectangle())
                        }.foregroundStyle(.primary)
                    }
                }
                Section {
                    Button("Bắt đầu tu luyện") {
                        let p = PlayerProfile(name: name.isEmpty ? "Tân Tu Sĩ" : name, gender: gender, sect: sect.rawValue)
                        if let data = try? JSONEncoder().encode(p) { UserDefaults.standard.set(data, forKey: "ttg_profile") }
                        dismiss()
                        onFinish()
                    }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("Tạo nhân vật")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Đóng") { dismiss() } } }
        }
    }
}
