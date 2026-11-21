import SwiftUI

struct GameHomeView: View {
    @AppStorage("ttg_started") private var started = true
    @State private var moveX: CGFloat = 0
    @State private var moveY: CGFloat = 0
    @State private var panel: GamePanel?
    @State private var hp = 100.0
    @State private var mana = 80.0
    @State private var showMap = false
    @State private var monsterHP = stageMonsterHP.0
    @State private var exp = 0
    @State private var level = 1
    @State private var combatMessage = "Xích Giác xuất hiện!"
    @State private var attackPulse = 0
    @State private var monsterHitPulse = 0
    @State private var shieldCharges = 0
    @State private var dodgeCharges = 0
    @State private var strength = 0
    @State private var agility = 0
    @State private var vitality = 0
    @State private var intelligence = 0
    @State private var potentialPoints = 50
    @State private var selectedStage = 1
    @State private var isBossFight = false
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

    private var maxHP: Double { (profile.sect == "Võ Tông" ? 130.0 : 100.0) + Double(vitality * 10) }
    private var maxMana: Double { (profile.sect == "Linh Tông" ? 120.0 : 80.0) + Double(intelligence * 5) }
    private var classStatDescription: String {
        switch profile.sect {
        case "Võ Tông": return "Sinh lực tối đa: 130 HP"
        case "Linh Tông": return "Linh lực tối đa: 120 MP"
        case "Kiếm Tông": return "Sinh lực: 100 HP • Linh lực: 80 MP"
        default: return "Sinh lực: 100 HP • Linh lực: 80 MP"
        }
    }
    private var profile: PlayerProfile {
        if let data = UserDefaults.standard.data(forKey: "ttg_profile"),
           let p = try? JSONDecoder().decode(PlayerProfile.self, from: data) { return p }
        return PlayerProfile(name: "Tân Tu Sĩ", gender: "Nam", sect: "Kiếm Tông")
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                WorldSceneView(moveX: $moveX, moveY: $moveY, attackPulse: $attackPulse, monsterHitPulse: $monsterHitPulse, monsterDefeated: Binding(get: { monsterHP <= 0 }, set: { _ in }), outfit: outfit, headwear: headwear, auraStyle: aura, wings: wings, mount: mount, pet: pet, isMounted: isMounted, selectedRegion: selectedRegion).ignoresSafeArea()
                VStack {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(profile.name)  •  Lv.\(level)  •  LC \\(powerScore)").font(.headline)
                            Text("\(realms[realmIndex])").font(.caption2).foregroundStyle(.cyan)
                            meter("HP", value: hp / maxHP, color: .red)
                            meter("MP", value: mana / maxMana, color: .blue)
                        }.padding(10).background(.black.opacity(0.62)).clipShape(RoundedRectangle(cornerRadius: 12))
                        Spacer()
                        if selectedRegion == "Tân Thủ Thôn" || selectedRegion == "Thanh Vân Đại Điện" {
                            Button { panel = .quests } label: {
                                VStack(spacing: 3) {
                                    Image(systemName: "person.fill")
                                    Text("Trưởng lão").font(.system(size: 9, weight: .bold))
                                }.foregroundStyle(.white).frame(width: 64, height: 64)
                                    .background(.purple.opacity(0.75)).clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
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
                            Text((isBossFight ? bossTitle : monsterTitle).uppercased()).font(.caption.bold())
                            Text("\(selectedRegion) • \(combatMessage)").font(.system(size: 9))
                            meter("HP", value: monsterHP / monsterMaxHP, color: isBossFight ? .red : .orange)
                        }
                        Spacer()
                        if monsterHP <= 0 {
                            VStack(alignment: .trailing, spacing: 5) {
                                if !lootClaimed {
                                    Button("Nhặt linh thạch +10") {
                                        currency += stageCurrency * (isBossFight ? 5 : 1)
                                        inventory.append(isBossFight ? bossDropName : stageDropName)
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
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 5) {
                            Label("AUTO TU LUYỆN", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                                .font(.caption.bold()).foregroundStyle(.green)
                            Text("Nhân vật tự động chiến đấu và nhận thưởng")
                                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.8))
                        }
                        Spacer()
                        Text("ẢI 1").font(.caption.bold()).padding(.horizontal, 12).padding(.vertical, 8)
                            .background(.purple.opacity(0.65)).clipShape(Capsule())
                    }.padding(12).background(.black.opacity(0.72)).clipShape(RoundedRectangle(cornerRadius: 14))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach([GamePanel.character, .stages, .bag, .equipment, .companions, .shop, .quests, .skills, .cosmetics]) { item in
                                Button { panel = item } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: panelIcon(item)).font(.system(size: 17, weight: .semibold))
                                        Text(item.rawValue).font(.system(size: 10, weight: .bold))
                                    }.frame(width: 68, height: 54)
                                        .background(.black.opacity(0.78)).foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 11))
                                }
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
                        regionButton("Tân Thủ Thôn", detail: "Làng khởi đầu • Khu an toàn", requiredLevel: 1)
                        regionButton("Thanh Vân Đại Điện", detail: "Đại điện môn phái • Khu an toàn", requiredLevel: 2)
                        regionButton("Thanh Vân Sơn", detail: "Sơn môn và bãi tu luyện • Cấp 1", requiredLevel: 1)
                        regionButton("Hỏa Diệm Cốc", detail: "Thung lũng dung nham • Cấp 3", requiredLevel: 3)
                        regionButton("Băng Phong Cốc", detail: "Thung lũng băng giá • Cấp 5", requiredLevel: 5)
                        regionButton("Lạc Hà Cốc", detail: "Thung lũng hoàng hôn • Cấp 7", requiredLevel: 7)
                        regionButton("Yêu Thú Sâm Lâm", detail: "Rừng cổ đầy linh thú • Cấp 9", requiredLevel: 9)
                        regionButton("Thiên Kiếm Di Tích", detail: "Tàn tích kiếm tu • Cấp 12", requiredLevel: 12)
                        regionButton("Cửu U Ma Vực", detail: "Ma vực u tối • Cấp 15", requiredLevel: 15)
                        regionButton("Phi Thăng Tiên Giới", detail: "Tiên cảnh trên mây • Cấp 20", requiredLevel: 20)
                        Text("Mở khóa khu vực bằng cách tăng cấp nhân vật.").font(.caption2).foregroundStyle(.gray)
                    }.padding(18).frame(maxWidth: 330).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 18)).padding(24)
                }
            }
        }
        .onAppear { loadGame() }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { break }
                if selectedRegion != "Tân Thủ Thôn" && selectedRegion != "Thanh Vân Đại Điện" && hp > 0 {
                    if monsterHP > 0 {
                        attackMonster(damage: 18 + Double(powerScore) * 0.08 + companionPower * 0.25, manaCost: 0)
                        if monsterHP > 0 { combatMessage = "Tự động farm • " + combatMessage }
                    } else if !lootClaimed {
                        currency += stageCurrency * (isBossFight ? 5 : 1)
                        inventory.append(isBossFight ? bossDropName : stageDropName)
                        lootClaimed = true
                        combatMessage = "Nhặt ải \(selectedStage): +\(stageCurrency) linh thạch, \(stageDropName)"
                    } else { respawnMonster() }
                }
            }
        }
        .onChange(of: saveFingerprint) { _ in
            if !isRestoringSave { saveGame() }
        }
        .onChange(of: monsterHitPulse) { _ in
            if dodgeCharges > 0 {
                dodgeCharges -= 1
                combatMessage = "Mê Tung Bộ né được đòn tấn công!"
            } else if shieldCharges > 0 {
                shieldCharges -= 1
                combatMessage = "Lá chắn đã hấp thụ đòn đánh!"
            } else {
                let incomingDamage = profile.sect == "Võ Tông" ? 5.0 : 8.0
                hp = max(0, hp - incomingDamage)
                combatMessage = "Quái phản công! -\\(Int(incomingDamage)) HP"
            }
        }
        .preferredColorScheme(.dark)
    }


    private func panelIcon(_ item: GamePanel) -> String {
        switch item {
        case .character: return "person.crop.circle"
        case .stages: return "flag.fill"
        case .bag: return "bag"
        case .shop: return "storefront"
        case .skills: return "sparkles"
        case .equipment: return "shield.lefthalf.filled"
        case .quests: return "scroll"
        case .companions: return "pawprint"
        case .cosmetics: return "wand.and.stars"
        }
    }

    private var monsterTitle: String {\n        switch selectedRegion {\n        case "Tân Thủ Thôn", "Thanh Vân Đại Điện": return "Khu an toàn"\n        case "Hỏa Diệm Cốc": return "Viêm Thạch Thú"\n        case "Băng Phong Cốc": return "Băng Giáp Lang"\n        case "Lạc Hà Cốc": return "Hoàng Hôn Hồ"\n        case "Yêu Thú Sâm Lâm": return "Thanh Mộc Lang"\n        case "Thiên Kiếm Di Tích": return "Kiếm Linh Cổ"\n        case "Cửu U Ma Vực": return "U Minh Ma Tướng"\n        case "Phi Thăng Tiên Giới": return "Thiên Giới Hộ Vệ"\n        default: return "Xích Giác"\n        }\n    }\n\n    func regionButton(_ name: String, detail: String, requiredLevel: Int) -> some View {\n        Button {\n            guard level >= requiredLevel else { combatMessage = "Cần đạt cấp \\(requiredLevel)"; return }\n            selectedRegion = name\n            monsterHP = 120\n            lootClaimed = false\n            combatMessage = "Đã đến \\(name), \\(monsterTitle) xuất hiện!"\n            showMap = false\n        } label: {\n            HStack {\n                VStack(alignment: .leading, spacing: 3) { Text(name).bold(); Text(detail).font(.caption2).foregroundStyle(.secondary) }\n                Spacer()\n                if level < requiredLevel { Image(systemName: "lock.fill").foregroundStyle(.orange) }\n                else if selectedRegion == name { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }\n                else { Image(systemName: "arrow.right.circle") }\n            }.padding(10).background(.black.opacity(0.25)).clipShape(RoundedRectangle(cornerRadius: 10))\n        }.buttonStyle(.plain).disabled(level < requiredLevel)\n    }\n\n    // Stage 15: automatic local save/restore.
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
            headwear: headwear, aura: aura,
            strength: strength, agility: agility, vitality: vitality,
            intelligence: intelligence, potentialPoints: potentialPoints, selectedStage: selectedStage, isBossFight: isBossFight
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
        strength = max(0, save.strength ?? 0)
        agility = max(0, save.agility ?? 0)
        vitality = max(0, save.vitality ?? 0)
        intelligence = max(0, save.intelligence ?? 0)
        potentialPoints = max(0, save.potentialPoints ?? 50)
        selectedStage = min(10, max(1, save.selectedStage ?? 1))
        isBossFight = save.isBossFight ?? false
        hp = min(maxHP, max(0, save.hp))
        mana = min(maxMana, max(0, save.mana))
        monsterHP = min(monsterMaxHP, max(0, save.monsterHP))
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

    @ViewBuilder func potentialRow(_ code: String, title: String, value: Int, detail: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\\(code) • \\(title)  \\(value)").font(.subheadline.bold())
                Text(detail).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            Button("+") {
                guard potentialPoints > 0 else { return }
                action()
                potentialPoints -= 1
                hp = min(maxHP, hp + 10)
                mana = min(maxMana, mana + 5)
                saveGame()
            }
            .font(.title3.bold()).frame(width: 36, height: 32)
            .background(potentialPoints > 0 ? .purple.opacity(0.45) : .gray.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .disabled(potentialPoints <= 0)
        }.padding(8).background(.white.opacity(0.06)).clipShape(RoundedRectangle(cornerRadius: 9))
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
        let skill = classSkill(for: title)
        return Button {
            if skill.name == "Kiếm Tâm Hộ Thể" || skill.name == "Thiết Bố Sam" || skill.name == "Long Tượng Bá Thể" {
                shieldCharges = min(2, shieldCharges + (skill.name == "Long Tượng Bá Thể" ? 2 : 1))
            }
            if skill.name == "Mê Tung Bộ" { dodgeCharges = min(2, dodgeCharges + 1) }
            if skill.name == "Tinh Hà Bạo" { mana = min(maxMana, mana + 12) }
            attackMonster(damage: skill.damage + Double(powerScore) * 0.15 + companionPower, manaCost: skill.mana)
            if monsterHP > 0 { combatMessage = "\\(skill.name)! " + combatMessage }
        } label: {
            VStack(spacing: 2) {
                Text(symbol).font(.title2)
                Text(skill.shortName).font(.system(size: 8, weight: .bold))
            }.frame(width: 54, height: 54).background(.black.opacity(0.76)).clipShape(Circle()).overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1))
        }.foregroundStyle(.white)
    }

    func classSkill(for slot: String) -> (name: String, shortName: String, damage: Double, mana: Double) {
        let index = ["Kỹ năng 1": 0, "Kỹ năng 2": 1, "Kỹ năng 3": 2, "Kỹ năng 4": 3][slot] ?? -1
        if slot == "Đánh" { return ("Đánh thường", "Đánh", 15, 0) }
        let skills: [(String, String, Double, Double)]
        switch profile.sect {
        case "Kiếm Tông":
            skills = [("Kiếm Khí Trảm", "Kiếm khí", 34, 10), ("Liên Hoàn Kiếm", "Liên kích", 29, 12), ("Kiếm Tâm Hộ Thể", "Hộ thể", 23, 8), ("Vạn Kiếm Quy Tông", "Vạn kiếm", 52, 20)]
        case "Linh Tông":
            skills = [("Hỏa Cầu Thuật", "Hỏa cầu", 39, 13), ("Băng Tiễn", "Băng tiễn", 34, 12), ("Lôi Ấn", "Lôi ấn", 43, 16), ("Tinh Hà Bạo", "Tinh hà", 56, 24)]
        case "Võ Tông":
            skills = [("Băng Sơn Quyền", "Trọng quyền", 37, 9), ("Thiết Bố Sam", "Thiết thân", 25, 7), ("Chấn Địa Kích", "Chấn địa", 42, 13), ("Long Tượng Bá Thể", "Bá thể", 55, 21)]
        default:
            skills = [("Ảnh Trảm", "Ảnh trảm", 36, 10), ("Mê Tung Bộ", "Mê tung", 28, 8), ("Phân Thân Kích", "Phân thân", 41, 14), ("Vô Ảnh Sát", "Vô ảnh", 58, 22)]
        }
        guard skills.indices.contains(index) else { return ("Kỹ năng", "Chiêu", 20, 8) }
        let item = skills[index]
        return (item.0, item.1, item.2, item.3)
    }

    var classPassive: (title: String, detail: String) {
        switch profile.sect {
        case "Kiếm Tông": return ("Kiếm Ý", "+12% sát thương kỹ năng")
        case "Linh Tông": return ("Linh Mạch", "Giảm 20% MP tiêu hao")
        case "Võ Tông": return ("Kim Cang Thể", "Giảm 3 sát thương nhận vào")
        default: return ("Ảnh Bộ", "+10% sát thương kỹ năng")
        }
    }

    func attackMonster(damage: Double, manaCost: Double) {
        guard monsterHP > 0 else { combatMessage = "Quái đã bị đánh bại"; return }
        let adjustedManaCost = profile.sect == "Linh Tông" ? manaCost * 0.8 : manaCost
        guard mana >= adjustedManaCost else { combatMessage = "Không đủ MP"; return }
        mana -= adjustedManaCost
        let multiplier = profile.sect == "Kiếm Tông" ? 1.12 : (profile.sect == "Ảnh Tông" ? 1.10 : 1.0)
        let finalDamage = damage * multiplier
        attackPulse += 1
        monsterHP = max(0, monsterHP - finalDamage)
        if monsterHP == 0 {
            lootClaimed = false
            let stageExp = (30 + (selectedStage - 1) * 15) * (isBossFight ? 5 : 1)
            exp += stageExp
            questKills += 1
            combatMessage = "Hạ quái ải \(selectedStage)! +\(stageExp) EXP"
            if exp >= level * 100 {
                exp -= level * 100
                level += 1
                potentialPoints += 5
                combatMessage = "Lên cấp! Lv.\\(level) • +5 điểm tiềm năng"
            }
        } else {
            combatMessage = "Gây \\(Int(finalDamage)) sát thương"
        }
    }

    var bossTitle: String { ["古代炎魔", "冰霜龍王", "九幽魔君", "天劍尊者", "混沌仙帝"][(selectedStage - 1) / 2 % 5] }
    var monsterMaxHP: Double { isBossFight ? stageMonsterHP * 5 : stageMonsterHP }
    var bossDropName: String { ["炎魔核心", "冰龍精魄", "九幽魔核", "天劍碎片", "混沌仙晶"][(selectedStage - 1) / 2 % 5] }

    var stageMonsterHP: Double { 120 + Double(selectedStage - 1) * 60 }
    var stageCurrency: Int { 10 + (selectedStage - 1) * 5 }
    var stageDropName: String {
        switch selectedStage {
        case 1...2: return "Hỏa linh châu"
        case 3...4: return "Thanh tâm thạch"
        case 5...6: return "Băng phách tinh"
        case 7...8: return "Thiên kiếm mảnh"
        default: return "Cửu u tiên tinh"
        }
    }

    var powerScore: Int {
        let bonus = ["Hỏa Long Kiếm": 65, "Băng Phách Kiếm": 75, "Thiên Lôi Kiếm": 90, "Thanh Long Kiếm": 110, "Vạn Kiếm Quy Tông": 145, "Cửu U Ma Kiếm": 130, "Kiếm linh": 35, "Kiếm sắt": 15][equippedWeapon] ?? 5
        return level * 10 + bonus + strength * 2 + agility
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
        mana = min(maxMana, mana + 20)
        hp = min(maxHP, hp + 20)
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
                Text("Nội tại: \\(classPassive.title)").font(.headline).foregroundStyle(.cyan)
                Text(classStatDescription).font(.caption).foregroundStyle(.secondary)
                Text(classPassive.detail).font(.caption).foregroundStyle(.secondary)
                if shieldCharges > 0 { Text("Lá chắn: \\(shieldCharges) lần chặn").font(.caption).foregroundStyle(.cyan) }
                if dodgeCharges > 0 { Text("Né tránh: \\(dodgeCharges) lần").font(.caption).foregroundStyle(.green) }
                Text("Cấp độ: \(level)  •  EXP: \(exp)/\(level * 100)")
                Text("Cảnh giới: \(realms[realmIndex])")
                Divider()
                Text("TIỀM NĂNG • Còn \\(potentialPoints) điểm").font(.headline).foregroundStyle(.yellow)
                potentialRow("STR", title: "Sức mạnh", value: strength, detail: "+2 lực chiến mỗi điểm") { strength += 1 }
                potentialRow("AGI", title: "Nhanh nhẹn", value: agility, detail: "+1 lực chiến mỗi điểm") { agility += 1 }
                potentialRow("VIT", title: "Thể chất", value: vitality, detail: "+10 HP tối đa mỗi điểm") { vitality += 1 }
                potentialRow("INT", title: "Trí lực", value: intelligence, detail: "+5 MP tối đa mỗi điểm") { intelligence += 1 }
                Button("Đột phá cảnh giới (100 EXP)") { breakthrough() }
                    .disabled(exp < 100 || realmIndex >= realms.count - 1)
                    .padding(9).background(.purple.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 9))
            case .stages:
                Text("Chọn ải hoặc khiêu chiến BOSS • Boss có 5 lần HP và thưởng hiếm").font(.caption).foregroundStyle(.secondary)
                Button {
                    isBossFight = true
                    monsterHP = stageMonsterHP * 5
                    lootClaimed = false
                    combatMessage = "Khiêu chiến \\(bossTitle)! "
                    panel = nil
                } label: {
                    HStack {
                        Image(systemName: "crown.fill").foregroundStyle(.yellow)
                        VStack(alignment: .leading) {
                            Text("BOSS ẢI \\(selectedStage): \\(bossTitle)").bold()
                            Text("HP \\(Int(stageMonsterHP * 5)) • Thưởng EXP và vật phẩm hiếm ×5").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("ĐẤU").bold().foregroundStyle(.orange)
                    }.padding(10).background(.red.opacity(0.2)).clipShape(RoundedRectangle(cornerRadius: 10))
                }.buttonStyle(.plain)
                ForEach(1...10, id: \.self) { stage in
                    Button {
                        selectedStage = stage
                        isBossFight = false
                        monsterHP = stageMonsterHP
                        lootClaimed = false
                        combatMessage = "Bắt đầu Ải \(stage) • HP quái \(Int(stageMonsterHP))"
                        panel = nil
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Ải \(stage) • \(stage < 3 ? "Tân thủ" : stage < 5 ? "Trung cấp" : stage < 8 ? "Cao cấp" : "Tiên giới")").bold()
                                Text("Quái: \(Int(120 + Double(stage - 1) * 60)) HP • +\(30 + (stage - 1) * 15) EXP • +\(10 + (stage - 1) * 5) linh thạch").font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedStage == stage { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
                        }.padding(9).background(.white.opacity(0.07)).clipShape(RoundedRectangle(cornerRadius: 9))
                    }.buttonStyle(.plain)
                }
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
                Text("🧙 Trưởng lão Thanh Vân").font(.headline)
                Text(selectedRegion == "Tân Thủ Thôn" || selectedRegion == "Thanh Vân Đại Điện" ? "Chào đạo hữu! Hãy rèn luyện tại các khu vực bên ngoài rồi quay về báo tin." : "Quái tại khu vực này đang hoành hành. Hãy giúp môn phái dọn đường tu luyện.")
                    .multilineTextAlignment(.center)
                Text("Nhiệm vụ môn phái: Đánh bại 3 quái")
                ProgressView(value: Double(min(questKills, 3)), total: 3).tint(.green)
                Text("Tiến độ: \\(min(questKills, 3))/3")
                if questKills >= 3 && !questClaimed {
                    Button("Nhận thưởng: 60 EXP + 30 linh thạch") {
                        exp += 60
                        currency += 30
                        questClaimed = true
                        combatMessage = "Trưởng lão ban thưởng: +60 EXP, +30 linh thạch"
                    }.padding(8).background(.green.opacity(0.3)).clipShape(RoundedRectangle(cornerRadius: 8))
                } else if questClaimed {
                    Text("Nhiệm vụ đã hoàn thành. Hãy tiếp tục hành trình!")
                } else {
                    Text("Hãy đánh bại thêm \\(3 - min(questKills, 3)) quái để nhận thưởng.")
                }
            case .skills:
                Text("Hệ phái: \(profile.sect)").font(.headline)
                Text("Bộ kỹ năng riêng của lớp nhân vật").font(.caption).foregroundStyle(.cyan)
                ForEach(["Kỹ năng 1", "Kỹ năng 2", "Kỹ năng 3", "Kỹ năng 4"], id: \\.self) { slot in
                    let skill = classSkill(for: slot)
                    HStack {
                        Text(skill.name).bold()
                        Spacer()
                        Text("ST: \(Int(skill.damage)) • MP: \(Int(skill.mana))").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Text("Chạm các nút kỹ năng trong trận đấu để sử dụng.").font(.caption2)
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
