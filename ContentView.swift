import SwiftUI
import AVKit

struct PiPSourceView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 220, height: 110))
        view.backgroundColor = UIColor(red: 0.05, green: 0.07, blue: 0.12, alpha: 0.95)
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        PiPHUDManager.shared.setupPiP(in: view)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct ContentView: View {
    @StateObject private var monitor = SystemMonitor.shared
    @StateObject private var pipManager = PiPHUDManager.shared
    
    @State private var currentTab: Int = 0
    @State private var selectedDevice: String = "120hz"
    @State private var selectedStyle: String = "shotgun"
    @State private var boostSuccessMessage: String?
    
    var body: some View {
        ZStack {
            // Nền tối Cyberpunk
            Color(red: 0.04, green: 0.05, blue: 0.09)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Segmented Tabs
                tabSelectorView
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                
                // Nội dung các Tab
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        if currentTab == 0 {
                            tabHUDAndCrosshairView
                        } else if currentTab == 1 {
                            tabSensiRegeditView
                        } else {
                            tabAccessibilityGuideView
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            monitor.start()
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 4) {
            HStack {
                Text("⚡ GAMING HUD PRO")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color(red: 0.0, green: 0.95, blue: 1.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Spacer()
                
                Text("V3.0 SENSI MOD")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.0, green: 0.95, blue: 1.0).opacity(0.15))
                    .cornerRadius(6)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
        }
    }
    
    // MARK: - Tab Selector
    private var tabSelectorView: some View {
        HStack(spacing: 8) {
            tabButton(title: "⚡ Cửa Sổ PiP", index: 0)
            tabButton(title: "🎯 Sensi Regedit", index: 1)
            tabButton(title: "🛠️ Trợ Năng", index: 2)
        }
        .padding(4)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func tabButton(title: String, index: Int) -> some View {
        Button(action: { currentTab = index }) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(currentTab == index ? Color(red: 0.05, green: 0.08, blue: 0.14) : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(currentTab == index ? Color(red: 0.0, green: 0.95, blue: 1.0) : Color.clear)
                .cornerRadius(9)
        }
    }
    
    // MARK: - Tab 0: Cửa Sổ PiP & Tâm Ngắm Ảo
    private var tabHUDAndCrosshairView: some View {
        VStack(spacing: 16) {
            // KHUNG PREVIEW TRỰC TIẾP
            ZStack {
                PiPSourceView()
                    .frame(height: 120)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 0.0, green: 0.95, blue: 1.0).opacity(pipManager.selectedMode == .crosshairOnly ? 0.2 : 0.6), lineWidth: 2)
                    )
                
                // Hiển thị tâm ngắm trong suốt
                if pipManager.selectedMode == .crosshairOnly {
                    VStack {
                        ZStack {
                            Circle()
                                .fill(crosshairSwiftColor())
                                .frame(width: 8, height: 8)
                            
                            Rectangle()
                                .fill(Color(red: 0.0, green: 0.95, blue: 1.0))
                                .frame(width: 2, height: 16)
                                .offset(y: -14)
                            Rectangle()
                                .fill(Color(red: 0.0, green: 0.95, blue: 1.0))
                                .frame(width: 2, height: 16)
                                .offset(y: 14)
                            Rectangle()
                                .fill(Color(red: 0.0, green: 0.95, blue: 1.0))
                                .frame(width: 16, height: 2)
                                .offset(x: -14)
                            Rectangle()
                                .fill(Color(red: 0.0, green: 0.95, blue: 1.0))
                                .frame(width: 16, height: 2)
                                .offset(x: 14)
                        }
                        
                        Text("🎯 CHẾ ĐỘ TRONG SUỐT (CHỈ HIỆN TÂM ĐỎ)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(crosshairSwiftColor())
                            .padding(.top, 8)
                    }
                }
            }
            .frame(height: 120)
            
            // Bộ chọn chế độ
            VStack(alignment: .leading, spacing: 10) {
                Text("CHỌN CHẾ ĐỘ HIỂN THỊ:")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray)
                
                HStack(spacing: 8) {
                    modePillButton(title: "📊 Chỉ Số", mode: .statsOnly)
                    modePillButton(title: "🎯 Tâm Trong Suốt", mode: .crosshairOnly)
                    modePillButton(title: "⚡ Kết Hợp", mode: .combo)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Chọn màu tâm
            if pipManager.selectedMode == .crosshairOnly || pipManager.selectedMode == .combo {
                HStack(spacing: 12) {
                    Text("MÀU TÂM:")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.gray)
                    
                    colorCircle(color: Color.red, uiColor: UIColor.red, name: "red")
                    colorCircle(color: Color.green, uiColor: UIColor.green, name: "green")
                    colorCircle(color: Color.yellow, uiColor: UIColor.yellow, name: "yellow")
                    colorCircle(color: Color.cyan, uiColor: UIColor.cyan, name: "cyan")
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
            
            // Nút Bật/Tắt Cửa Sổ Nổi PiP
            Button(action: {
                if pipManager.isPiPActive {
                    pipManager.stopPiP()
                } else {
                    pipManager.startPiP()
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: pipManager.isPiPActive ? "stop.circle.fill" : "pip.enter")
                        .font(.system(size: 18, weight: .bold))
                    
                    Text(pipManager.isPiPActive ? "ĐANG BẬT CỬA SỔ NỔI" : "BẬT CỬA SỔ NỔI (START PiP)")
                        .font(.system(size: 15, weight: .heavy))
                }
                .foregroundColor(Color(red: 0.05, green: 0.08, blue: 0.14))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: pipManager.isPiPActive ? [Color(red: 0.0, green: 1.0, blue: 0.5), Color(red: 0.0, green: 0.8, blue: 0.8)] : [Color(red: 0.0, green: 0.95, blue: 1.0), Color(red: 0.2, green: 0.6, blue: 1.0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(13)
                .shadow(color: Color(red: 0.0, green: 0.95, blue: 1.0).opacity(0.35), radius: 12, x: 0, y: 4)
            }
            
            // Nút Tối Ưu Cảm Ứng & Xả RAM (Booster)
            Button(action: {
                monitor.boostPerformance {
                    boostSuccessMessage = "✅ Đã giải phóng RAM rác và kích hoạt cảm ứng 120Hz mượt mà!"
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.horizontal.fill")
                        .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                    
                    Text(monitor.isOptimizing ? "ĐANG TỐI ƯU HỆ THỐNG..." : "🚀 TỐI ƯU CẢM ỨNG & XẢ RAM 120HZ")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(Color.white.opacity(0.06))
                .cornerRadius(11)
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .stroke(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.4), lineWidth: 1)
                )
            }
            
            if let msg = boostSuccessMessage {
                Text(msg)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(red: 0.0, green: 1.0, blue: 0.5))
            }
            
            // Hướng dẫn đặt tâm giữa màn hình
            VStack(alignment: .leading, spacing: 6) {
                Text("🎯 HƯỚNG DẪN KHÓA TÂM VÀO GIỮA MÀN HÌNH:")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 1.0, green: 0.7, blue: 0.0))
                Text("• Cửa sổ nổi PiP bây giờ đã hoàn toàn TRONG SUỐT (chỉ hiện duy nhất chấm tâm đỏ và 4 vạch ngắm, xóa sạch nền đen).\n• Khi mở game, bạn chỉ cần dùng ngón tay kéo khung nổi vào chính giữa tâm bắn là nó sẽ cố định ngay điểm đó để bạn headshot cực chuẩn!")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding(14)
            .background(Color.white.opacity(0.03))
            .cornerRadius(12)
        }
    }
    
    private func modePillButton(title: String, mode: HUDDisplayMode) -> some View {
        Button(action: {
            pipManager.setMode(mode)
        }) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(pipManager.selectedMode == mode ? Color(red: 0.05, green: 0.08, blue: 0.14) : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(pipManager.selectedMode == mode ? Color(red: 0.0, green: 0.95, blue: 1.0) : Color.white.opacity(0.06))
                .cornerRadius(8)
        }
    }
    
    private func colorCircle(color: Color, uiColor: UIColor, name: String) -> some View {
        Button(action: {
            pipManager.setCrosshairColor(uiColor, hex: name)
        }) {
            Circle()
                .fill(color)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: pipManager.selectedColorHex == name ? 2.5 : 0)
                )
        }
    }
    
    private func crosshairSwiftColor() -> Color {
        switch pipManager.selectedColorHex {
        case "green": return Color.green
        case "yellow": return Color.yellow
        case "cyan": return Color(red: 0.0, green: 0.95, blue: 1.0)
        default: return Color(red: 1.0, green: 0.15, blue: 0.35)
        }
    }
    
    // MARK: - Tab 1: Sensi Regedit Mod
    private var tabSensiRegeditView: some View {
        VStack(spacing: 16) {
            // Chọn thiết bị
            VStack(alignment: .leading, spacing: 8) {
                Text("CHỌN DÒNG MÁY CỦA BẠN:")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray)
                
                HStack(spacing: 8) {
                    deviceButton(title: "iPhone 120Hz Pro", key: "120hz")
                    deviceButton(title: "iPhone 60Hz", key: "60hz")
                    deviceButton(title: "iPad", key: "ipad")
                }
            }
            
            // Chọn phong cách bắn
            VStack(alignment: .leading, spacing: 8) {
                Text("PHONG CÁCH KÉO TÂM:")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray)
                
                HStack(spacing: 8) {
                    styleButton(title: "💥 Shotgun", key: "shotgun")
                    styleButton(title: "🔫 SMG / MP40", key: "smg")
                    styleButton(title: "🎯 AR Sấy Xa", key: "ar")
                }
            }
            
            sensiResultCard
        }
    }
    
    private func deviceButton(title: String, key: String) -> some View {
        Button(action: { selectedDevice = key }) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(selectedDevice == key ? Color(red: 0.05, green: 0.08, blue: 0.14) : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selectedDevice == key ? Color(red: 0.0, green: 0.95, blue: 1.0) : Color.white.opacity(0.06))
                .cornerRadius(8)
        }
    }
    
    private func styleButton(title: String, key: String) -> some View {
        Button(action: { selectedStyle = key }) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(selectedStyle == key ? Color(red: 0.05, green: 0.08, blue: 0.14) : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selectedStyle == key ? Color(red: 1.0, green: 0.84, blue: 0.0) : Color.white.opacity(0.06))
                .cornerRadius(8)
        }
    }
    
    private var sensiResultCard: some View {
        let sens = calculateSensi()
        return VStack(spacing: 12) {
            HStack {
                Text("🎯 THÔNG SỐ ĐỘ NHẠY ĐỀ XUẤT")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                sensiStatBox(label: "Nhìn xung quanh", val: "\(sens.general)")
                sensiStatBox(label: "Red Dot Sight", val: "\(sens.reddot)")
                sensiStatBox(label: "Ống ngắm 2X", val: "\(sens.scope2)")
                sensiStatBox(label: "Ống ngắm 4X", val: "\(sens.scope4)")
                sensiStatBox(label: "Ống Sniper", val: "\(sens.sniper)")
                sensiStatBox(label: "Nút bắn (Fire)", val: "\(sens.button)%")
            }
            
            HStack {
                Text("📍 Vị trí nút bắn: Đặt thấp sát mép dưới màn hình.")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color(red: 0.08, green: 0.10, blue: 0.16))
        .cornerRadius(14)
    }
    
    private func sensiStatBox(label: String, val: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)
            Spacer()
            Text(val)
                .font(.system(size: 15, weight: .black, design: .monospaced))
                .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
        }
        .padding(10)
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
    }
    
    private func calculateSensi() -> (general: Int, reddot: Int, scope2: Int, scope4: Int, sniper: Int, button: Int) {
        if selectedDevice == "120hz" {
            if selectedStyle == "shotgun" { return (98, 95, 88, 82, 45, 45) }
            if selectedStyle == "smg" { return (94, 90, 85, 80, 48, 48) }
            return (90, 86, 82, 76, 50, 52)
        } else if selectedDevice == "60hz" {
            if selectedStyle == "shotgun" { return (100, 98, 92, 86, 50, 48) }
            if selectedStyle == "smg" { return (98, 94, 88, 84, 52, 50) }
            return (94, 90, 84, 80, 55, 54)
        } else {
            return (88, 84, 78, 72, 42, 42)
        }
    }
    
    // MARK: - Tab 2: Trợ Năng
    private var tabAccessibilityGuideView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("⚙️ BÍ KÍP TRỢ NĂNG (REGEDIT IOS CHUẨN):")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
            
            guideItem(title: "1. Điều khiển công tắc (Switch Control)", detail: "Kiểu quét: Tinh chỉnh • Tốc độ con trỏ lướt: 120 (Max)")
            guideItem(title: "2. Thích nghi cảm ứng (Touch Accommodations)", detail: "Thời gian giữ: TẮT (0ms) • Bỏ qua lặp lại: 0.10s")
            guideItem(title: "3. AssistiveTouch", detail: "Độ nhạy di chuyển: 90% - 95% • Dung sai: 35%")
            guideItem(title: "4. Chuyển động (Motion)", detail: "BẬT 'Giảm chuyển động' (Reduce Motion)")
        }
        .padding(16)
        .background(Color(red: 0.08, green: 0.10, blue: 0.16))
        .cornerRadius(14)
    }
    
    private func guideItem(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
            Text(detail)
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
    }
}
