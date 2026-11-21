# Assets 3D — Tu Tiên Giới

Thư mục này dành cho model 3D được đóng gói cùng ứng dụng iOS.

## Trạng thái tích hợp

Chưa có file model nhị phân trong repository. Không đánh dấu model là đã tích hợp cho đến khi file USDZ/DAE thật được thêm và kiểm tra trong bản build iOS.

## Model dự kiến

| Vai trò trong game | Model nguồn | Định dạng ưu tiên | Ghi chú |
|---|---|---|---|
| Pet cáo / hồ ly | Grab3D — Low Poly Fox | USDZ | 2.999 triangles, static, CC0 1.0 |
| Thú cưỡi kỳ lân thay thế tạm | Grab3D — Low Poly Unicorn | USDZ | 3.496 triangles, static, CC0 1.0 |
| Nhân vật chibi | Plewr — 3D Rigged Character | GLB → USDZ/DAE sau chuyển đổi | Rigged GLB; cần chuyển đổi/kiểm tra animation trước khi dùng trong SceneKit |

Nguồn:
- https://grab3d.com/models/animals/low-poly-fox/
- https://grab3d.com/models/creatures/low-poly-unicorn/
- https://plewr.itch.io/3d-rigged-character

Các trang nguồn mô tả model Fox và Unicorn là CC0 1.0; model nhân vật Plewr cũng được ghi CC0. Giữ lại giấy phép/manifest đi kèm mỗi file khi tải về.

## Quy ước khi thêm file

- Chỉ thêm file đã tải đầy đủ và kiểm tra mở được.
- Đặt tên rõ ràng: `LowPolyFox.usdz`, `LowPolyUnicorn.usdz`, `ChibiHero.usdz`.
- Đặt giấy phép và manifest cùng model.
- Thêm thư mục này vào mục `resources` của `project.yml`, không đưa model nhị phân vào Swift source.
- SceneKit tải USDZ bằng `SCNScene(url:options:)`; GLB không được SceneKit hỗ trợ trực tiếp.
- Giữ model nhẹ để phù hợp iPhone 12; ưu tiên low-poly, texture nhỏ và static nếu chưa có animation tương thích.

## Các giai đoạn 11–14

11. Chuẩn bị tài nguyên model, giấy phép và cấu hình bundle resources.
12. Tạo bộ nạp SceneKit có kiểm tra lỗi và model dự phòng.
13. Ánh xạ model vào pet/thú cưỡi/ngoại trang, không xóa các vật phẩm shop hiện có.
14. Tối ưu kích thước, kiểm tra hiển thị, animation và build trên iOS.
