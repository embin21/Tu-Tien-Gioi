
import SwiftUI

struct Monster: Identifiable {
    let id = UUID()
    var name: String
    var hp: Int
    var maxHP: Int
    var expReward: Int

    var isAlive: Bool {
        hp > 0
    }
}

final class CombatSystem: ObservableObject {
    @Published var monster = Monster(
        name: "Xích Giác",
        hp: 100,
        maxHP: 100,
        expReward: 30
    )

    @Published var level = 1
    @Published var exp = 0
    @Published var hp = 100
    @Published var mana = 80
    @Published var message = "Xích Giác xuất hiện!"

    var expRequired: Int {
        level * 100
    }

    func attack() {
        guard monster.isAlive else { return }
        damageMonster(15)
    }

    func useSkill() {
        guard monster.isAlive else { return }

        guard mana >= 20 else {
            message = "Không đủ linh lực!"
            return
        }

        mana -= 20
        damageMonster(35)
    }

    private func damageMonster(_ damage: Int) {
        monster.hp = max(0, monster.hp - damage)

        if monster.isAlive {
            message = "Bạn gây \(damage) sát thương!"
        } else {
            message = "Đánh bại Xích Giác! Nhận \(monster.expReward) EXP."
            gainExp(monster.expReward)
        }
    }

    private func gainExp(_ amount: Int) {
        exp += amount

        while exp >= expRequired {
            exp -= expRequired
            level += 1
            hp = 100
            mana = 80
            message = "Chúc mừng! Đột phá lên cấp \(level)!"
        }
    }

    func respawnMonster() {
        monster.hp = monster.maxHP
        message = "Xích Giác đã xuất hiện trở lại!"
    }
}
