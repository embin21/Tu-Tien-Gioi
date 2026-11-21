import SwiftUI

enum Sect: String, CaseIterable, Identifiable {
    case kiem = "Kiếm Tông"
    case linh = "Linh Tông"
    case vo = "Võ Tông"
    case anh = "Ảnh Tông"
    var id: String { rawValue }
    var description: String {
        switch self {
        case .kiem: return "Kiếm pháp cân bằng, cận chiến"
        case .linh: return "Pháp thuật tầm xa, sát thương phép"
        case .vo: return "Thể chất mạnh, phòng thủ cao"
        case .anh: return "Nhanh nhẹn, né tránh linh hoạt"
        }
    }
}

enum GamePanel: String, CaseIterable, Identifiable {
    case character = "Nhân vật"
    case guild = "Bang hội"
    case bag = "Túi đồ"
    case shop = "Shop"
    case skills = "Kỹ năng"
    case equipment = "Trang bị"
    case quests = "Nhiệm vụ"
    case companions = "Thú cưỡi / Pet"
    case cosmetics = "Ngoại trang"
    var id: String { rawValue }
}

struct PlayerProfile: Codable {
    var name: String
    var gender: String
    var sect: String
    var level: Int = 1
}


// Versioned local save data for Stage 15.
struct GameSave: Codable {
    var hp: Double
    var mana: Double
    var monsterHP: Double
    var exp: Int
    var level: Int
    var currency: Int
    var lootClaimed: Bool
    var inventory: [String]
    var realmIndex: Int
    var equippedWeapon: String
    var equippedArmor: String
    var questKills: Int
    var questClaimed: Bool
    var mount: String
    var isMounted: Bool
    var wings: String
    var pet: String
    var artifact: String
    var outfit: String
    var headwear: String
    var aura: String
    var strength: Int? = nil
    var agility: Int? = nil
    var vitality: Int? = nil
    var intelligence: Int? = nil
    var potentialPoints: Int? = nil
    var selectedStage: Int? = nil
    var isBossFight: Bool? = nil
    var guildName: String? = nil
    var guildLevel: Int? = nil
    var guildExp: Int? = nil
    var guildContribution: Int? = nil
    var guildKills: Int? = nil
    var guildTaskClaimed: Bool? = nil
    var mountLevel: Int? = nil
    var mountExp: Int? = nil
    var wingLevel: Int? = nil
    var wingExp: Int? = nil
    var petLevel: Int? = nil
    var petExp: Int? = nil
}
