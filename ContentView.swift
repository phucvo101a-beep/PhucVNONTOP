import SwiftUI
import AVKit

struct PiPContainerView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 2, height: 2))
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        view.clipsToBounds = true
        PiPHUDManager.shared.setupPiP(in: view)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct ContentView: View {
    @StateObject private var monitor = SystemMonitor.shared
    @StateObject private var pipManager = PiPHUDManager.shared
    
    var body: some View {
        ZStack {
            // Nền tối Cyberpunk
            Color(red: 0.04, green: 0.05, blue: 0.09)
                .ignoresSafeArea()
            
            // View ngầm để neo PiP (không che màn hình)
            PiPContainerView()
                .frame(width: 2, height: 2)
                .opacity(0.01)
                .allowsHitTesting(false)
            
            VStack(spacing: 22) {
                // Header
                VStack(spacing: 6) {
                    Text("⚡ GAMING HUD PRO")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color(red: 0.0, green: 0.95, blue: 1.0)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Cửa sổ nổi hiển thị FPS, RAM & Ping khi chơi game")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                
                // Khung hiển thị thông số trực tiếp
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("FPS  \(Int(monitor.fps))")
                            .font(.system(size: 34, weight: .black, design: .monospaced))
                            .foregroundColor(monitor.fps >= 55 ? Color(red: 0.0, green: 1.0, blue: 0.5) : Color(red: 1.0, green: 0.8, blue: 0.0))
                        
                        Spacer()
                        
                        Circle()
                            .fill(Color(red: 0.0, green: 1.0, blue: 0.5))
                            .frame(width: 10, height: 10)
                        Text("LIVE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Divider().background(Color.white.opacity(0.15))
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("RAM ĐANG DÙNG")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.gray)
                            Text(String(format: "%.1f GB (%.0f%%)", monitor.usedRAM_MB / 1024.0, monitor.ramUsagePercent))
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("ĐỘ TRỄ MẠNG (PING)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.gray)
                            Text("\(monitor.pingMs) ms")
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(monitor.pingMs < 40 ? Color(red: 0.0, green: 0.95, blue: 1.0) : Color.red)
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(red: 0.08, green: 0.10, blue: 0.16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color(red: 0.0, green: 0.95, blue: 1.0).opacity(0.4), lineWidth: 1.5)
                        )
                )
                .padding(.horizontal, 20)
                
                // Nút Bật / Tắt Cửa Sổ Nổi PiP
                Button(action: {
                    if pipManager.isPiPActive {
                        pipManager.stopPiP()
                    } else {
                        pipManager.startPiP()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: pipManager.isPiPActive ? "stop.circle.fill" : "pip.enter")
                            .font(.system(size: 20, weight: .bold))
                        
                        Text(pipManager.isPiPActive ? "ĐANG BẬT CỬA SỔ NỔI" : "BẬT CỬA SỔ NỔI (START PiP)")
                            .font(.system(size: 16, weight: .heavy))
                    }
                    .foregroundColor(Color(red: 0.05, green: 0.08, blue: 0.14))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: pipManager.isPiPActive ? [Color(red: 0.0, green: 1.0, blue: 0.5), Color(red: 0.0, green: 0.8, blue: 0.8)] : [Color(red: 0.0, green: 0.95, blue: 1.0), Color(red: 0.2, green: 0.6, blue: 1.0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: Color(red: 0.0, green: 0.95, blue: 1.0).opacity(0.4), radius: 15, x: 0, y: 5)
                }
                .padding(.horizontal, 20)
                
                // Hướng dẫn nhanh
                VStack(alignment: .leading, spacing: 10) {
                    Text("💡 CÁCH SỬ DỤNG KHI CHƠI GAME:")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.7, blue: 0.0))
                    
                    Text("1. Bấm nút xanh ở trên để kích hoạt cửa sổ PiP.")
                    Text("2. Vuốt thoát ra màn hình chính (Khung PiP sẽ tự nổi lên).")
                    Text("3. Mở game Free Fire / PUBG lên: Khung PiP vẫn hiển thị đè lên game. Dùng 1 ngón tay kéo khung nổi vào góc tùy ý.")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.white.opacity(0.04))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .onAppear {
            monitor.start()
        }
    }
}
