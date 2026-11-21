
import SwiftUI

struct CombatView: View {
    @StateObject private var combat = CombatSystem()

    var body: some View {
        VStack(spacing: 16) {
            Text("⚔️ KHU VỰC CHIẾN ĐẤU")
                .font(.headline)

            Text("👹")
                .font(.system(size: 65))

            Text(combat.monster.name)
                .font(.title2.bold())

            ProgressView(
                value: Double(combat.monster.hp),
                total: Double(combat.monster.maxHP)
            )
            .tint(.red)

            Text("HP: \(combat.monster.hp)/\(combat.monster.maxHP)")

            Text("Cấp \(combat.level) • EXP \(combat.exp)/\(combat.expRequired)")
                .font(.subheadline)

            Text(combat.message)
                .font(.caption)
                .multilineTextAlignment(.center)

            HStack {
                Button("⚔️ Đánh thường") {
                    combat.attack()
                }
                .buttonStyle(.borderedProminent)

                Button("🔥 Kiếm khí") {
                    combat.useSkill()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }

            Text("Linh lực: \(combat.mana)")
                .font(.caption)

            if !combat.monster.isAlive {
                Button("Quái vật xuất hiện lại") {
                    combat.respawnMonster()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.black.opacity(0.85))
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding()
    }
}
