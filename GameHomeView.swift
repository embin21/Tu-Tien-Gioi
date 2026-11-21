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
    private var profile: PlayerProfile {
        if let data = UserDefaults.standard.data(forKey: "ttg_profile"),
           let p = try? JSONDecoder().decode(PlayerProfile.self, from: data) { return p }
        return PlayerProfile(name: "Tân Tu Sĩ", gender: "Nam", sect: "Kiếm Tông")
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                WorldSceneView(moveX: $moveX, moveY: $moveY, attackPulse: $attackPulse).ignoresSafeArea()
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
                            Text("XÍCH GIÁC").font(.caption.bold())
                            Text(combatMessage).font(.system(size: 9))
                            meter("HP", value: monsterHP / 120, color: .orange)
                        }
                        Spacer()
                        if monsterHP <= 0 {
                            Button("Hồi sinh quái") { respawnMonster() }
                                .font(.caption.bold()).padding(8).background(.black.opacity(0.7)).clipShape(RoundedRectangle(cornerRadius: 8))
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
                    VStack {
                        HStack { Text("BẢN ĐỒ KHU VỰC").bold(); Spacer(); Button("Đóng") { showMap = false } }
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(Color(red: 0.16, green: 0.24, blue: 0.22))
                            Image(systemName: "location.fill").font(.largeTitle).foregroundStyle(.orange)
                            Text("Thanh Vân Sơn").font(.caption).foregroundStyle(.white).offset(y: 52)
                        }.frame(height: 210)
                    }.padding(18).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 18)).padding(34)
                }
            }
        }.preferredColorScheme(.dark)
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
            attackMonster(damage: stats.0, manaCost: stats.1)
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
            exp += 30
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

    func respawnMonster() {
        monsterHP = 120
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
            case .bag:
                Text("Túi đồ (0/40)").font(.headline)
                Text("Chưa có vật phẩm. Vật phẩm nhặt được sẽ xuất hiện tại đây.")
            case .shop:
                Text("Tiền: 0  •  Linh thạch: 0")
                Text("Shop đang chờ kết nối dữ liệu vật phẩm.")
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
