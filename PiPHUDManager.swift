import Foundation
import UIKit
import AVKit
import AVFoundation

public enum HUDDisplayMode: Int {
    case statsOnly = 0       // Bảng chỉ số FPS, RAM, Ping
    case crosshairOnly = 1   // Tâm ngắm ảo Sniper (Red Dot / Crosshair)
    case combo = 2           // Kết hợp cả hai
}

/// Controller hiển thị giao diện Gaming HUD & Tâm Ngắm Ảo trong cửa sổ PiP nổi
public final class HUDViewController: UIViewController {
    public let fpsLabel = UILabel()
    public let ramLabel = UILabel()
    public let pingLabel = UILabel()
    public let dotView = UIView()
    public let liveLabel = UILabel()
    
    // View tâm ngắm ảo (Crosshair)
    public let crosshairContainer = UIView()
    public let crosshairCenterDot = UIView()
    public let crosshairTopLine = UIView()
    public let crosshairBottomLine = UIView()
    public let crosshairLeftLine = UIView()
    public let crosshairRightLine = UIView()
    
    public var currentMode: HUDDisplayMode = .statsOnly
    private var statsStack: UIStackView?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(red: 0.05, green: 0.07, blue: 0.12, alpha: 0.95)
        view.layer.cornerRadius = 14
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor(red: 0.0, green: 0.95, blue: 1.0, alpha: 0.85).cgColor
        view.clipsToBounds = true
        
        setupStatsViews()
        setupCrosshairViews()
        applyMode(currentMode)
    }
    
    private func setupStatsViews() {
        fpsLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 26, weight: .black)
        fpsLabel.textColor = UIColor(red: 0.0, green: 1.0, blue: 0.5, alpha: 1.0)
        fpsLabel.text = "FPS  60"
        
        dotView.backgroundColor = UIColor(red: 0.0, green: 1.0, blue: 0.5, alpha: 1.0)
        dotView.layer.cornerRadius = 4
        dotView.translatesAutoresizingMaskIntoConstraints = false
        
        liveLabel.text = "LIVE"
        liveLabel.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        liveLabel.textColor = .white
        liveLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let liveStack = UIStackView(arrangedSubviews: [dotView, liveLabel])
        liveStack.axis = .horizontal
        liveStack.spacing = 4
        liveStack.alignment = .center
        
        let topStack = UIStackView(arrangedSubviews: [fpsLabel, liveStack])
        topStack.axis = .horizontal
        topStack.distribution = .equalSpacing
        topStack.alignment = .center
        
        let separator = UIView()
        separator.backgroundColor = UIColor(white: 1.0, alpha: 0.15)
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        ramLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        ramLabel.textColor = .white
        ramLabel.text = "RAM: 2.0 GB (50%)"
        
        pingLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        pingLabel.textColor = UIColor(red: 0.0, green: 0.95, blue: 1.0, alpha: 1.0)
        pingLabel.text = "PING: 18 ms • CPU: 12%"
        
        let bottomStack = UIStackView(arrangedSubviews: [ramLabel, pingLabel])
        bottomStack.axis = .vertical
        bottomStack.spacing = 2
        
        let mainStack = UIStackView(arrangedSubviews: [topStack, separator, bottomStack])
        mainStack.axis = .vertical
        mainStack.spacing = 5
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)
        self.statsStack = mainStack
        
        NSLayoutConstraint.activate([
            dotView.widthAnchor.constraint(equalToConstant: 8),
            dotView.heightAnchor.constraint(equalToConstant: 8),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
            mainStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            mainStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])
    }
    
    private func setupCrosshairViews() {
        crosshairContainer.translatesAutoresizingMaskIntoConstraints = false
        crosshairContainer.backgroundColor = .clear
        view.addSubview(crosshairContainer)
        
        // Chấm tròn trung tâm màu đỏ Neon
        crosshairCenterDot.backgroundColor = UIColor(red: 1.0, green: 0.1, blue: 0.3, alpha: 1.0)
        crosshairCenterDot.layer.cornerRadius = 3.5
        crosshairCenterDot.translatesAutoresizingMaskIntoConstraints = false
        crosshairContainer.addSubview(crosshairCenterDot)
        
        // 4 vạch ngắm Neon Cyan
        let lineColor = UIColor(red: 0.0, green: 0.95, blue: 1.0, alpha: 0.9)
        for line in [crosshairTopLine, crosshairBottomLine, crosshairLeftLine, crosshairRightLine] {
            line.backgroundColor = lineColor
            line.layer.cornerRadius = 1
            line.translatesAutoresizingMaskIntoConstraints = false
            crosshairContainer.addSubview(line)
        }
        
        NSLayoutConstraint.activate([
            crosshairContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            crosshairContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            crosshairContainer.widthAnchor.constraint(equalToConstant: 50),
            crosshairContainer.heightAnchor.constraint(equalToConstant: 50),
            
            crosshairCenterDot.centerXAnchor.constraint(equalTo: crosshairContainer.centerXAnchor),
            crosshairCenterDot.centerYAnchor.constraint(equalTo: crosshairContainer.centerYAnchor),
            crosshairCenterDot.widthAnchor.constraint(equalToConstant: 7),
            crosshairCenterDot.heightAnchor.constraint(equalToConstant: 7),
            
            // Top line
            crosshairTopLine.centerXAnchor.constraint(equalTo: crosshairContainer.centerXAnchor),
            crosshairTopLine.bottomAnchor.constraint(equalTo: crosshairCenterDot.topAnchor, constant: -4),
            crosshairTopLine.widthAnchor.constraint(equalToConstant: 2),
            crosshairTopLine.heightAnchor.constraint(equalToConstant: 12),
            
            // Bottom line
            crosshairBottomLine.centerXAnchor.constraint(equalTo: crosshairContainer.centerXAnchor),
            crosshairBottomLine.topAnchor.constraint(equalTo: crosshairCenterDot.bottomAnchor, constant: 4),
            crosshairBottomLine.widthAnchor.constraint(equalToConstant: 2),
            crosshairBottomLine.heightAnchor.constraint(equalToConstant: 12),
            
            // Left line
            crosshairLeftLine.centerYAnchor.constraint(equalTo: crosshairContainer.centerYAnchor),
            crosshairLeftLine.trailingAnchor.constraint(equalTo: crosshairCenterDot.leadingAnchor, constant: -4),
            crosshairLeftLine.widthAnchor.constraint(equalToConstant: 12),
            crosshairLeftLine.heightAnchor.constraint(equalToConstant: 2),
            
            // Right line
            crosshairRightLine.centerYAnchor.constraint(equalTo: crosshairContainer.centerYAnchor),
            crosshairRightLine.leadingAnchor.constraint(equalTo: crosshairCenterDot.trailingAnchor, constant: 4),
            crosshairRightLine.widthAnchor.constraint(equalToConstant: 12),
            crosshairRightLine.heightAnchor.constraint(equalToConstant: 2)
        ])
    }
    
    public func applyMode(_ mode: HUDDisplayMode) {
        self.currentMode = mode
        switch mode {
        case .statsOnly:
            statsStack?.isHidden = false
            crosshairContainer.isHidden = true
            view.backgroundColor = UIColor(red: 0.05, green: 0.07, blue: 0.12, alpha: 0.95)
            view.layer.borderWidth = 2
        case .crosshairOnly:
            statsStack?.isHidden = true
            crosshairContainer.isHidden = false
            view.backgroundColor = UIColor(white: 0.0, alpha: 0.35) // Trong suốt để thấy map game
            view.layer.borderWidth = 1
        case .combo:
            statsStack?.isHidden = false
            crosshairContainer.isHidden = false
            view.backgroundColor = UIColor(red: 0.05, green: 0.07, blue: 0.12, alpha: 0.95)
            view.layer.borderWidth = 2
        }
    }
    
    public func updateStats() {
        let monitor = SystemMonitor.shared
        let fpsVal = Int(monitor.fps)
        fpsLabel.text = "FPS  \(fpsVal)"
        fpsLabel.textColor = fpsVal >= 55 ? UIColor(red: 0.0, green: 1.0, blue: 0.5, alpha: 1.0) : UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
        
        ramLabel.text = String(format: "RAM: %.1f GB (%.0f%%)", monitor.usedRAM_MB / 1024.0, monitor.ramUsagePercent)
        pingLabel.text = String(format: "PING: %d ms • CPU: %.0f%%", monitor.pingMs, monitor.cpuUsagePercent)
        pingLabel.textColor = monitor.pingMs < 35 ? UIColor(red: 0.0, green: 0.95, blue: 1.0, alpha: 1.0) : (monitor.pingMs < 75 ? UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) : UIColor(red: 1.0, green: 0.3, blue: 0.4, alpha: 1.0))
    }
}

/// Trình quản lý PiP độc quyền - Hỗ trợ cả Stats Monitor và Tâm Ngắm Ảo (Crosshair HUD)
public final class PiPHUDManager: NSObject, ObservableObject {
    public static let shared = PiPHUDManager()
    
    @Published public var isPiPActive: Bool = false
    @Published public var isPiPSupported: Bool = false
    @Published public var selectedMode: HUDDisplayMode = .statsOnly
    
    private var pipController: AVPictureInPictureController?
    private var hudVC: HUDViewController?
    private var updateTimer: Timer?
    
    private override init() {
        super.init()
        setupAudioSession()
        checkPiPSupport()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioSession Error: \(error)")
        }
    }
    
    private func checkPiPSupport() {
        isPiPSupported = AVPictureInPictureController.isPictureInPictureSupported()
    }
    
    public func setupPiP(in sourceView: UIView) {
        guard isPiPSupported else { return }
        
        if #available(iOS 15.0, *) {
            let callVC = AVPictureInPictureVideoCallViewController()
            callVC.preferredContentSize = CGSize(width: 220, height: 100)
            
            let hud = HUDViewController()
            callVC.addChild(hud)
            callVC.view.addSubview(hud.view)
            hud.view.frame = CGRect(x: 0, y: 0, width: 220, height: 100)
            hud.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            hud.didMove(toParent: callVC)
            
            self.hudVC = hud
            hud.applyMode(selectedMode)
            
            let contentSource = AVPictureInPictureController.ContentSource(
                activeVideoCallSourceView: sourceView,
                contentViewController: callVC
            )
            
            pipController = AVPictureInPictureController(contentSource: contentSource)
            pipController?.delegate = self
            pipController?.canStartPictureInPictureAutomaticallyFromInline = true
        }
        
        startUpdating()
    }
    
    public func setMode(_ mode: HUDDisplayMode) {
        self.selectedMode = mode
        hudVC?.applyMode(mode)
    }
    
    public func startPiP() {
        guard let pip = pipController else { return }
        if !pip.isPictureInPictureActive {
            startUpdating()
            hudVC?.applyMode(selectedMode)
            hudVC?.updateStats()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                pip.startPictureInPicture()
            }
        }
    }
    
    public func stopPiP() {
        pipController?.stopPictureInPicture()
    }
    
    private func startUpdating() {
        stopUpdating()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.hudVC?.updateStats()
        }
    }
    
    private func stopUpdating() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
}

// MARK: - AVPictureInPictureControllerDelegate
extension PiPHUDManager: AVPictureInPictureControllerDelegate {
    public func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        DispatchQueue.main.async { self.isPiPActive = true }
    }
    
    public func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        DispatchQueue.main.async { self.isPiPActive = false }
    }
}
