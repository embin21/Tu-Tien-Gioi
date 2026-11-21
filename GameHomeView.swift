import SwiftUI

struct GameHomeView: View {
    @AppStorage("ttg_started") private var started = true
    @State private var moveX: CGFloat = 0
    @State private var moveY: CGFloat = 0
    @State private var panel: GamePanel?
    @State private var hp = 100.0
    @State private var mana = 80.0
    @State private var showMap = false
    @State private var monsterHP = 120.0
    @State private var exp = 0
    @State private var level = 1
    @State private var combatMessage = "Xích Giác xuất hiện!"
    @State private var attackPulse = 0
    @State private var monsterHitPulse = 0
    @State private var currency = 0
    @State private var lootClaimed = false
    @State private var inventory: [String] = []
    @State private var realmIndex = 0
    @State private var equippedWeapon = "Kiếm gỗ"
    @State private var equippedArmor = "Áo vải"
    @State private var questKills = 0
    @State private var questClaimed = false
    @State private var mount = "Chưa có thú cưỡi"
    @State private var isMounted = false
    @State private var wings = "Chưa có cánh"
    @State private var pet = "Chưa có pet"
    @State private var artifact = "Chưa có bảo khí"
    @State private var outfit = "Trang phục mặc định"
    @State private var headwear = "Không đội mũ"
    @State private var aura = "Không có hào quang"
    @State private var isRestoringSave = false
    @State private var saveStatus = "Chưa lưu"
    @AppStorage("ttg_region_stage16") private var selectedRegion = "Thanh Vân Sơn"
    private let realms = ["Luyện Khí", "Trúc Cơ", "Kim Đan", "Nguyên Anh", "Hóa Thần"]
    private var profile: PlayerProfile {
        if let data = UserDefaults.standard.data(forKey: "ttg_profile"),
           let p = try? JSONDecoder().decode(PlayerProfile.self, from: data) { return p }
        return PlayerProfile(name: "Tân Tu Sĩ", gender: "Nam", sect: "Kiếm Tông")
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                WorldSceneView(moveX: $moveX, moveY: $moveY, attackPulse: $attackPulse, monsterHitPulse: $monsterHitPulse, monsterDefeated: Binding(get: { monsterHP <= 0 }, set: { _ in }), outfit: outfit, headwear: headwear, auraStyle: aura, wings: wings, mount: mount, pet: pet, isMounted: isMounted).ignoresSafeArea()
                VStack {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(profile.name)  •  Lv.\(level)").font(.headline)
                            meter("HP", value: hp / 100, color: .red)
                            meter("MP", value: mana / 100, color: .blue)
                        }.padding(10).background(.black.opacity(0.62)).clipShape(RoundedRectangle(cornerRadius: 12))
                        Spacer()
                        Button { showMap.toggle() } label: {
                            ZStack {
                                Circle().fill(.black.opacity(0.65))
                                Image(systemName: "map.fill").foregroundStyle(.white)
                                Circle().stroke(.white.opacity(0.65), lineWidth: 1)
                            }.frame(width: 64, height: 64)
                        }
                    }
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(monsterTitle.uppercased()).font(.caption.bold())
                            Text("\(selectedRegion) • \(combatMessage)").font(.system(size: 9))
                            meter("HP", value: monsterHP / 120, color: .orange)
                        }
                        Spacer()
                        if monsterHP <= 0 {
                            VStack(alignment: .trailing, spacing: 5) {
                                if !lootClaimed {
                                    Button("Nhặt linh thạch +10") {
                                        currency += 10
                                        inventory.append("Hỏa linh châu")
                                        lootClaimed = true
                                        combatMessage = "Nhặt được 10 linh thạch và Hỏa linh châu"
                                    }.font(.caption.bold()).padding(7).background(.cyan.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                Button("Hồi sinh quái") { respawnMonster() }
                                    .font(.caption.bold()).padding(7).background(.black.opacity(0.7)).clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }.padding(9).background(.black.opacity(0.65)).clipShape(RoundedRectangle(cornerRadius: 10))
                    Spacer()
                    HStack(alignment: .bottom) {
                        JoystickView(x: $moveX, y: $moveY).frame(width: 132, height: 132)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 9) {
                            HStack(spacing: 8) {
                                skillButton("⚔️", title: "Đánh")
                                skillButton("❄️", title: "Kỹ năng 1")
                            }
                            HStack(spacing: 8) {
                                skillButton("🔥", title: "Kỹ năng 2")
                                skillButton("🌪️", title: "Kỹ năng 3")
                                skillButton("✨", title: "Kỹ năng 4")
                            }
                        }
                    }
                    HStack(spacing: 8) {
                        ForEach(GamePanel.allCases) { item in
                            Button { panel = item } label: {
                                Text(item.rawValue).font(.caption.bold()).frame(maxWidth: .infinity).padding(.vertical, 11).background(.black.opacity(0.72)).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }.padding(.horizontal, 14).padding(.top, 10).padding(.bottom, 8)
                if let panel {
                    panelView(panel).padding(20).transition(.scale.combined(with: .opacity))
                }
                if showMap {
                    VStack(spacing: 12) {
                        HStack { Text("BẢN ĐỒ TU TIÊN").bold(); Spacer(); Button("Đóng") { showMap = false } }
                        Text("Khu vực hiện tại: \\(selectedRegion)").font(.caption).foregroundStyle(.cyan)
                        regionButton("Thanh Vân Sơn", detail: "Khu vực khởi đầu • Cấp 1", requiredLevel: 1)
                        regionButton("Hỏa Diệm Cốc", detail: "Thung lũng dung nham • Cấp 3", requiredLevel: 3)
                        regionButton("Băng Phong Cốc", detail: "Thung lũng băng giá • Cấp 5", requiredLevel: 5)
                        Text("Mở khóa khu vực bằng cách tăng cấp nhân vật.").font(.caption2).foregroundStyle(.gray)
                    }.padding(18).frame(maxWidth: 330).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 18)).padding(24)
                }
            }
        }
        .onAppear { loadGame() }
        .onChange(of: saveFingerprint) { _ in
            if !isRestoringSave { saveGame() }
        }
        .onChange(of: monsterHitPulse) { _ in
            hp = max(0, hp - 8)
            combatMessage = "Xích Giác phản công! -8 HP"
        }
        .preferredColorScheme(.dark)
    }


    private var monsterTitle: String {\n        switch selectedRegion {\n        case "Hỏa Diệm Cốc": return "Viêm Thạch Thú"\n        case "Băng Phong Cốc": return "Băng Giáp Lang"\n        default: return "Xích Giác"\n        }\n    }\n\n    func regionButton(_ name: String, detail: String, requiredLevel: Int) -> some View {\n        Button {\n            guard level >= requiredLevel else { combatMessage = "Cần đạt cấp \\(requiredLevel)"; return }\n            selectedRegion = name\n            monsterHP = 120\n            lootClaimed = false\n            combatMessage = "Đã đến \\(name), \\(monsterTitle) xuất hiện!"\n            showMap = false\n        } label: {\n            HStack {\n                VStack(alignment: .leading, spacing: 3) { Text(name).bold(); Text(detail).font(.caption2).foregroundStyle(.secondary) }\n                Spacer()\n                if level < requiredLevel { Image(systemName: "lock.fill").foregroundStyle(.orange) }\n                else if selectedRegion == name { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }\n                else { Image(systemName: "arrow.right.circle") }\n            }.padding(10).background(.black.opacity(0.25)).clipShape(RoundedRectangle(cornerRadius: 10))\n        }.buttonStyle(.plain).disabled(level < requiredLevel)\n    }\n\n    // Stage 15: automatic local save/restore.
    private var saveFingerprint: String {
        [
            String(hp), String(mana), String(monsterHP), String(exp), String(level),
            String(currency), String(lootClaimed), inventory.joined(separator: "~"),
            String(realmIndex), equippedWeapon, equippedArmor, String(questKills),
            String(questClaimed), mount, String(isMounted), wings, pet, artifact,
            outfit, headwear, aura
        ].joined(separator: "|")
    }

    func saveGame() {
        let save = GameSave(
            hp: hp, mana: mana, monsterHP: monsterHP, exp: exp, level: level,
            currency: currency, lootClaimed: lootClaimed, inventory: inventory,
            realmIndex: realmIndex, equippedWeapon: equippedWeapon,
            equippedArmor: equippedArmor, questKills: questKills,
            questClaimed: questClaimed, mount: mount, isMounted: isMounted,
            wings: wings, pet: pet, artifact: artifact, outfit: outfit,
            headwear: headwear, aura: aura
        )
        do {
            let data = try JSONEncoder().encode(save)
            UserDefaults.standard.set(data, forKey: "ttg_save_stage15")
            saveStatus = "Đã lưu tự động"
        } catch {
            saveStatus = "Lỗi lưu dữ liệu"
        }
    }

    func loadGame() {
        guard let data = UserDefaults.standard.data(forKey: "ttg_save_stage15"),
              let save = try? JSONDecoder().decode(GameSave.self, from: data) else {
            saveStatus = "Chưa có bản lưu — sẽ tự lưu khi chơi"
            return
        }
        isRestoringSave = true
        hp = min(100, max(0, save.hp))
        mana = min(100, max(0, save.mana))
        monsterHP = min(120, max(0, save.monsterHP))
        exp = max(0, save.exp)
        level = max(1, save.level)
        currency = max(0, save.currency)
        lootClaimed = save.lootClaimed
        inventory = Array(save.inventory.prefix(40))
        realmIndex = min(realms.count - 1, max(0, save.realmIndex))
        equippedWeapon = save.equippedWeapon
        equippedArmor = save.equippedArmor
        questKills = max(0, save.questKills)
        questClaimed = save.questClaimed
        mount = save.mount
        isMounted = save.isMounted
        wings = save.wings
        pet = save.pet
        artifact = save.artifact
        outfit = save.outfit
        headwear = save.headwear
        aura = save.aura
        saveStatus = "Đã khôi phục bản lưu"
        isRestoringSave = false
        saveGame()
    }

    func meter(_ label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 5) {
            Text(label).font(.system(size: 9, weight: .bold)).frame(width: 20)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.18))
                    Capsule().fill(color).frame(width: g.size.width * max(0, min(1, value)))
                }
            }.frame(width: 116, height: 8)
        }
    }

    func skillButton(_ symbol: String, title: String) -> some View {
        Button {
            let stats: (Double, Double)
            switch title {
            case "Đánh": stats = (15, 0)
            case "Kỹ năng 1": stats = (30, 10)
            case "Kỹ năng 2": stats = (25, 10)
            case "Kỹ năng 3": stats = (20, 8)
            default: stats = (40, 15)
            }
            attackMonster(damage: stats.0 + Double(powerScore) * 0.15 + companionPower, manaCost: stats.1)
        } label: {
            VStack(spacing: 2) {
                Text(symbol).font(.title2)
                Text(title).font(.system(size: 8, weight: .bold))
            }.frame(width: 54, height: 54).background(.black.opacity(0.76)).clipShape(Circle()).overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1))
        }.foregroundStyle(.white)
    }

    func attackMonster(damage: Double, manaCost: Double) {
        guard monsterHP > 0 else { combatMessage = "Quái đã bị đánh bại"; return }
        guard mana >= manaCost else { combatMessage = "Không đủ MP"; return }
        mana -= manaCost
        attackPulse += 1
        monsterHP = max(0, monsterHP - damage)
        if monsterHP == 0 {
            lootClaimed = false
            exp += 30
            questKills += 1
            combatMessage = "Hạ quái! +30 EXP"
            if exp >= level * 100 {
                exp -= level * 100
                level += 1
                combatMessage = "Lên cấp! Lv.\(level)"
            }
        } else {
            combatMessage = "Gây \(Int(damage)) sát thương"
        }
    }

    var powerScore: Int {
        let bonus = ["Hỏa Long Kiếm": 65, "Băng Phách Kiếm": 75, "Thiên Lôi Kiếm": 90, "Thanh Long Kiếm": 110, "Vạn Kiếm Quy Tông": 145, "Cửu U Ma Kiếm": 130, "Kiếm linh": 35, "Kiếm sắt": 15][equippedWeapon] ?? 5
        return level * 10 + bonus
    }

    var companionPower: Double { (["Linh Hồ": 8, "Cửu Vĩ Thiên Hồ": 18, "Bạch Trạch": 14, "Kim Sí Điểu": 16, "Thanh Long": 24, "Hỏa Phượng": 22, "Ngân Nguyệt Lang": 12, "Bạch Hổ Chiến Thú": 20][pet] ?? 0) + (["Hỏa Linh Châu": 12, "Trấn Yêu Tháp": 18, "Thái Cực Đồ": 22, "Sinh Mệnh Chi Thụ": 25][artifact] ?? 0) }

    var defenseScore: Int {
        let bonus = equippedArmor == "Áo da" ? 15 : 5
        return level * 5 + bonus
    }

    @ViewBuilder func shopItem(_ name: String, price: Int) -> some View {
        HStack {
            VStack(alignment: .leading) { Text(name).bold(); Text("Giá: \\(price) linh thạch").font(.caption) }
            Spacer()
            if inventory.contains(name) { Text("Đã sở hữu").font(.caption).foregroundStyle(.green) }
            else { Button("Mua") {
                guard currency >= price else { combatMessage = "Không đủ linh thạch"; return }
                currency -= price
                inventory.append(name)
                combatMessage = "Đã mua \\(name)"
            }.disabled(currency < price) }
        }
    }

    func breakthrough() {
        guard exp >= 100, realmIndex < realms.count - 1 else { return }
        exp -= 100
        realmIndex += 1
        combatMessage = "Đột phá thành công: \(realms[realmIndex])!"
        mana = min(100, mana + 20)
        hp = min(100, hp + 20)
    }

    func respawnMonster() {
        monsterHP = 120
        lootClaimed = false
        combatMessage = "Xích Giác đã hồi sinh"
    }

    @ViewBuilder func panelView(_ item: GamePanel) -> some View {
        VStack(spacing: 12) {
            HStack { Text(item.rawValue.uppercased()).font(.headline); Spacer(); Button("✕") { panel = nil } }
            switch item {
            case .character:
                Text("⚔️  \(profile.name)").font(.title3.bold())
                Text("Môn phái: \(profile.sect)  •  Giới tính: \(profile.gender)")
                Text("Cấp độ: \(level)  •  EXP: \(exp)/\(level * 100)")
                Text("Cảnh giới: \(realms[realmIndex])")
                Button("Đột phá cảnh giới (100 EXP)") { breakthrough() }
                    .disabled(exp < 100 || realmIndex >= realms.count - 1)
                    .padding(9).background(.purple.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 9))
            case .bag:
                Text("Túi đồ (\(inventory.count)/40)").font(.headline)
                if inventory.isEmpty {
                    Text("Chưa có vật phẩm. Hãy đánh quái để nhận chiến lợi phẩm.")
                } else {
                    ForEach(Array(Dictionary(grouping: inventory, by: { $0 }).keys.sorted()), id: \.self) { item in
                        Text("🔹 \(item) × \(inventory.filter { $0 == item }.count)")
                    }
                }
            case .shop:
                Text("Linh thạch: \\(currency)")
                shopItem("Kiếm sắt", price: 20)
                shopItem("Áo da", price: 15)
                shopItem("Kiếm linh", price: 50)
                shopItem("Hỏa Long Kiếm", price: 100)
                shopItem("Băng Phách Kiếm", price: 140)
                shopItem("Thiên Lôi Kiếm", price: 200)
                shopItem("Long Lân Giáp", price: 160)
                shopItem("Huyền Vũ Giáp", price: 220)
                shopItem("Thanh Vân Hạc", price: 120)
                shopItem("Tử Kim Kỳ Lân", price: 260)
                shopItem("Phong Vũ Chi Dực", price: 180)
                shopItem("Phượng Hoàng Thần Dực", price: 320)
                shopItem("Linh Hồ", price: 150)
                shopItem("Cửu Vĩ Thiên Hồ", price: 300)
                shopItem("Hỏa Linh Châu", price: 130)
                shopItem("Trấn Yêu Tháp", price: 280)
                shopItem("Ngân Nguyệt Lang", price: 190)
                shopItem("Thanh Long", price: 420)
                shopItem("Hỏa Phượng", price: 380)
                shopItem("Bạch Hổ Chiến Thú", price: 350)
                shopItem("Lưu Quang Tiên Dực", price: 450)
                shopItem("Cửu Thiên Thần Dực", price: 600)
                shopItem("Thanh Long Kiếm", price: 360)
                shopItem("Vạn Kiếm Quy Tông", price: 520)
                shopItem("Cửu U Ma Kiếm", price: 480)
                shopItem("Thiên Tằm Bảo Giáp", price: 340)
                shopItem("Cửu Thiên Tiên Giáp", price: 560)
                shopItem("Bạch Trạch", price: 240)
                shopItem("Kim Sí Điểu", price: 330)
                shopItem("Thái Cực Đồ", price: 390)
                shopItem("Sinh Mệnh Chi Thụ", price: 500)
                shopItem("Tiên Y Thanh Vân", price: 180)
                shopItem("Chiến Bào Xích Viêm", price: 260)
                shopItem("Dạ Hành Huyền Ảnh", price: 300)
                shopItem("Long Thần Đế Bào", price: 650)
                shopItem("Phượng Vũ Tiên Y", price: 580)
                shopItem("Mũ Ngọc Vân Quan", price: 120)
                shopItem("Mặt Nạ U Minh", price: 160)
                shopItem("Vương Miện Thiên Đế", price: 400)
                shopItem("Hào Quang Kim Liên", price: 220)
                shopItem("Tinh Hà Quang Hoàn", price: 360)
            case .equipment:
                Text("Vũ khí: \\(equippedWeapon)")
                Text("Giáp: \\(equippedArmor)")
                Text("Sức mạnh: \\(powerScore)")
                Text("Phòng thủ: \\(defenseScore)")
                ForEach(["Kiếm gỗ", "Kiếm sắt", "Kiếm linh", "Hỏa Long Kiếm", "Băng Phách Kiếm", "Thiên Lôi Kiếm", "Thanh Long Kiếm", "Vạn Kiếm Quy Tông", "Cửu U Ma Kiếm"], id: \\.self) { item in
                    if inventory.contains(item) { Button("Trang bị \\(item)") { equippedWeapon = item } }
                }
                ForEach(["Áo vải", "Áo da", "Long Lân Giáp", "Huyền Vũ Giáp", "Thiên Tằm Bảo Giáp", "Cửu Thiên Tiên Giáp"], id: \\.self) { item in
                    if inventory.contains(item) { Button("Mặc \\(item)") { equippedArmor = item } }
                }
            case .companions:
                Text("Thú cưỡi: \\(mount)")
                if mount != "Chưa có thú cưỡi" {
                    Button(isMounted ? "Xuống thú cưỡi" : "Lên thú cưỡi") { isMounted.toggle() }
                        .padding(8).background(.orange.opacity(0.3)).clipShape(RoundedRectangle(cornerRadius: 8))
                }
                ForEach(["Thanh Vân Hạc", "Tử Kim Kỳ Lân", "Ngân Nguyệt Lang", "Thanh Long", "Hỏa Phượng", "Bạch Hổ Chiến Thú"], id: \\.self) { item in
                    if inventory.contains(item) { Button("Cưỡi \\(item)") { mount = item } }
                }
                Divider().overlay(.white.opacity(0.3))
                Text("Cánh: \\(wings)")
                ForEach(["Phong Vũ Chi Dực", "Phượng Hoàng Thần Dực", "Lưu Quang Tiên Dực", "Cửu Thiên Thần Dực"], id: \\.self) { item in
                    if inventory.contains(item) { Button("Trang bị \\(item)") { wings = item } }
                }
                Divider().overlay(.white.opacity(0.3))
                Text("Pet: \\(pet)")
                ForEach(["Linh Hồ", "Cửu Vĩ Thiên Hồ", "Bạch Trạch", "Kim Sí Điểu"], id: \\.self) { item in
                    if inventory.contains(item) { Button("Triệu hồi \\(item)") { pet = item } }
                }
                Divider().overlay(.white.opacity(0.3))
                Text("Bảo khí: \\(artifact)")
                ForEach(["Hỏa Linh Châu", "Trấn Yêu Tháp", "Thái Cực Đồ", "Sinh Mệnh Chi Thụ"], id: \\.self) { item in
                    if inventory.contains(item) { Button("Kích hoạt \\(item)") { artifact = item } }
                }
            case .cosmetics:
                Text("Ngoại trang không cộng chỉ số, chỉ thay đổi phong cách nhân vật.")
                    .font(.caption).foregroundStyle(.gray)
                Text("Trang phục: \\(outfit)")
                ForEach(["Trang phục mặc định", "Tiên Y Thanh Vân", "Chiến Bào Xích Viêm", "Dạ Hành Huyền Ảnh", "Long Thần Đế Bào", "Phượng Vũ Tiên Y"], id: \\.self) { item in
                    if item == "Trang phục mặc định" || inventory.contains(item) {
                        Button("Mặc \\(item)") { outfit = item }
                    }
                }
                Divider().overlay(.white.opacity(0.3))
                Text("Mũ / mặt nạ: \\(headwear)")
                ForEach(["Không đội mũ", "Mũ Ngọc Vân Quan", "Mặt Nạ U Minh", "Vương Miện Thiên Đế"], id: \\.self) { item in
                    if item == "Không đội mũ" || inventory.contains(item) {
                        Button("Trang bị \\(item)") { headwear = item }
                    }
                }
                Divider().overlay(.white.opacity(0.3))
                Text("Hào quang: \\(aura)")
                ForEach(["Không có hào quang", "Hào Quang Kim Liên", "Tinh Hà Quang Hoàn"], id: \\.self) { item in
                    if item == "Không có hào quang" || inventory.contains(item) {
                        Button("Bật \\(item)") { aura = item }
                    }
                }
            case .quests:
                Text("NPC: Trưởng lão Thanh Vân").font(.headline)
                Text("Nhiệm vụ: Đánh bại 3 Xích Giác")
                Text("Tiến độ: \\(min(questKills, 3))/3")
                if questKills >= 3 && !questClaimed {
                    Button("Nhận thưởng: 60 EXP + 30 linh thạch") {
                        exp += 60
                        currency += 30
                        questClaimed = true
                        combatMessage = "Hoàn thành nhiệm vụ! +60 EXP, +30 linh thạch"
                    }.padding(8).background(.green.opacity(0.3)).clipShape(RoundedRectangle(cornerRadius: 8))
                } else if questClaimed {
                    Text("Đã nhận thưởng. Nhiệm vụ hoàn thành!")
                } else {
                    Text("Hãy tiếp tục săn Xích Giác để hoàn thành nhiệm vụ.")
                }
            case .skills:
                Text("Đánh thường  •  Kiếm khí  •  Hộ thể  •  Phi hành")
                Text("Kỹ năng hiện là giao diện mẫu.")
            }
        }.foregroundStyle(.white).padding(18).frame(maxWidth: 330).background(Color.black.opacity(0.88)).clipShape(RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(.orange.opacity(0.7), lineWidth: 1))
    }
}

struct JoystickView: View {
    @Binding var x: CGFloat
    @Binding var y: CGFloat
    @State private var knob = CGSize.zero
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                Circle().fill(.black.opacity(0.45)).overlay(Circle().stroke(.white.opacity(0.55), lineWidth: 2))
                Circle().fill(.white.opacity(0.24)).frame(width: size * 0.42, height: size * 0.42).offset(knob)
            }
            .frame(width: size, height: size)
            .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                let c = CGPoint(x: size/2, y: size/2)
                let dx = value.location.x - c.x
                let dy = value.location.y - c.y
                let maxR = size * 0.28
                let d = hypot(dx, dy)
                let scale = d > maxR ? maxR / d : 1
                knob = CGSize(width: dx * scale, height: dy * scale)
                x = knob.width / maxR
                y = knob.height / maxR
            }.onEnded { _ in
                knob = .zero; x = 0; y = 0
            })
        }
    }
}
