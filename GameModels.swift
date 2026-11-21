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
