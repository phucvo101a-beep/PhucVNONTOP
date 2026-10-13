import Foundation
import UIKit
import AVKit
import AVFoundation

/// Controller hiển thị giao diện Gaming HUD trong cửa sổ PiP nổi
public final class HUDViewController: UIViewController {
    public let fpsLabel = UILabel()
    public let ramLabel = UILabel()
    public let pingLabel = UILabel()
    public let dotView = UIView()
    public let liveLabel = UILabel()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. Nền Cyberpunk tối và viền Neon Cyan
        view.backgroundColor = UIColor(red: 0.05, green: 0.07, blue: 0.12, alpha: 0.95)
        view.layer.cornerRadius = 14
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor(red: 0.0, green: 0.95, blue: 1.0, alpha: 0.85).cgColor
        view.clipsToBounds = true
        
        // 2. Nhãn FPS
        fpsLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 28, weight: .black)
        fpsLabel.textColor = UIColor(red: 0.0, green: 1.0, blue: 0.5, alpha: 1.0)
        fpsLabel.text = "FPS  60"
        
        // Chấm LIVE
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
        
        // Đường kẻ phân cách
        let separator = UIView()
        separator.backgroundColor = UIColor(white: 1.0, alpha: 0.15)
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        // 3. Nhãn RAM & PING
        ramLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        ramLabel.textColor = .white
        ramLabel.text = "RAM: 2.0 GB (50%)"
        
        pingLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        pingLabel.textColor = UIColor(red: 0.0, green: 0.95, blue: 1.0, alpha: 1.0)
        pingLabel.text = "PING: 15 ms • CPU: 10%"
        
        let bottomStack = UIStackView(arrangedSubviews: [ramLabel, pingLabel])
        bottomStack.axis = .vertical
        bottomStack.spacing = 3
        
        let mainStack = UIStackView(arrangedSubviews: [topStack, separator, bottomStack])
        mainStack.axis = .vertical
        mainStack.spacing = 6
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            dotView.widthAnchor.constraint(equalToConstant: 8),
            dotView.heightAnchor.constraint(equalToConstant: 8),
            
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
            mainStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            mainStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10)
        ])
    }
    
    public func updateStats() {
        let monitor = SystemMonitor.shared
        let fpsVal = Int(monitor.fps)
        fpsLabel.text = "FPS  \(fpsVal)"
        fpsLabel.textColor = fpsVal >= 55 ? UIColor(red: 0.0, green: 1.0, blue: 0.5, alpha: 1.0) : UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
        
        ramLabel.text = String(format: "RAM: %.1f GB (%.0f%%)", monitor.usedRAM_MB / 1024.0, monitor.ramUsagePercent)
        
        pingLabel.text = String(format: "PING: %d ms • CPU: %.0f%%", monitor.pingMs, monitor.cpuUsagePercent)
        pingLabel.textColor = monitor.pingMs < 40 ? UIColor(red: 0.0, green: 0.95, blue: 1.0, alpha: 1.0) : (monitor.pingMs < 80 ? UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) : UIColor(red: 1.0, green: 0.3, blue: 0.4, alpha: 1.0))
    }
}

/// Trình quản lý PiP độc quyền - Sử dụng AVPictureInPictureVideoCallViewController để KHÔNG BAO GIỜ BỊ MÀN HÌNH ĐEN
public final class PiPHUDManager: NSObject, ObservableObject {
    public static let shared = PiPHUDManager()
    
    @Published public var isPiPActive: Bool = false
    @Published public var isPiPSupported: Bool = false
    
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
    
    public func startPiP() {
        guard let pip = pipController else { return }
        if !pip.isPictureInPictureActive {
            startUpdating()
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
