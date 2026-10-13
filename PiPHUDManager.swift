import Foundation
import UIKit
import AVKit
import AVFoundation
import CoreMedia
import VideoToolbox

/// Quản lý luồng hiển thị cửa sổ nổi Picture-in-Picture (PiP) đè lên màn hình game
public final class PiPHUDManager: NSObject, ObservableObject {
    public static let shared = PiPHUDManager()
    
    @Published public var isPiPActive: Bool = false
    @Published public var isPiPSupported: Bool = false
    
    private var pipController: AVPictureInPictureController?
    private var sampleBufferLayer = AVSampleBufferDisplayLayer()
    private var renderTimer: Timer?
    private var pixelBufferPool: CVPixelBufferPool?
    
    // Cấu hình kích thước khung hình nổi PiP (Chuẩn 400x180 px tỉ lệ siêu nét)
    private let frameWidth: Int = 400
    private let frameHeight: Int = 180
    
    private override init() {
        super.init()
        setupAudioSession()
        checkPiPSupport()
    }
    
    private func setupAudioSession() {
        do {
            // Cần audio session playback để iOS cho phép PiP chạy ngầm khi mở game khác
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Lỗi cấu hình AVAudioSession: \(error)")
        }
    }
    
    private func checkPiPSupport() {
        isPiPSupported = AVPictureInPictureController.isPictureInPictureSupported()
    }
    
    /// Khởi tạo layer PiP và gán vào một UIView trong App
    public func setupPiP(in parentView: UIView) {
        guard isPiPSupported else { return }
        
        sampleBufferLayer.frame = CGRect(x: 0, y: 0, width: 200, height: 90)
        sampleBufferLayer.videoGravity = .resizeAspect
        parentView.layer.addSublayer(sampleBufferLayer)
        
        if #available(iOS 15.0, *) {
            let contentSource = AVPictureInPictureController.ContentSource(sampleBufferDisplayLayer: sampleBufferLayer, playbackDelegate: self)
            pipController = AVPictureInPictureController(contentSource: contentSource)
            pipController?.delegate = self
            pipController?.canStartPictureInPictureAutomaticallyFromInline = true
        }
        
        createPixelBufferPool()
    }
    
    public func startPiP() {
        guard let pip = pipController, !pip.isPictureInPictureActive else { return }
        
        startRenderingFrames()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            pip.startPictureInPicture()
        }
    }
    
    public func stopPiP() {
        pipController?.stopPictureInPicture()
        stopRenderingFrames()
    }
    
    private func startRenderingFrames() {
        stopRenderingFrames()
        // Render 30 FPS để mượt mà mà vẫn siêu tiết kiệm pin
        renderTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.renderCurrentHUDFrame()
        }
    }
    
    private func stopRenderingFrames() {
        renderTimer?.invalidate()
        renderTimer = nil
    }
    
    private func createPixelBufferPool() {
        let poolAttributes: [String: Any] = [kCVPixelBufferPoolMinimumBufferCountKey as String: 3]
        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: frameWidth,
            kCVPixelBufferHeightKey as String: frameHeight,
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        CVPixelBufferPoolCreate(kCFAllocatorDefault, poolAttributes as CFDictionary, pixelBufferAttributes as CFDictionary, &pixelBufferPool)
    }
    
    /// Vẽ bảng thông số Gaming HUD trực tiếp vào khung video PiP
    private func renderCurrentHUDFrame() {
        guard let pool = pixelBufferPool else { return }
        var maybePixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &maybePixelBuffer)
        guard status == kCVReturnSuccess, let pixelBuffer = maybePixelBuffer else { return }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        let data = CVPixelBufferGetBaseAddress(pixelBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: data,
            width: frameWidth,
            height: frameHeight,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
            return
        }
        
        UIGraphicsPushContext(context)
        
        // 1. Nền tối Cyber Gaming
        let rect = CGRect(x: 0, y: 0, width: frameWidth, height: frameHeight)
        context.setFillColor(UIColor(red: 0.05, green: 0.07, blue: 0.12, alpha: 0.95).cgColor)
        context.fill(rect)
        
        // 2. Viền phát sáng Neon Cyan
        let borderPath = UIBezierPath(roundedRect: rect.insetBy(dx: 4, dy: 4), cornerRadius: 14)
        borderPath.lineWidth = 3
        UIColor(red: 0.0, green: 0.95, blue: 1.0, alpha: 0.8).setStroke()
        borderPath.stroke()
        
        let monitor = SystemMonitor.shared
        
        // 3. Vẽ Chỉ số FPS
        let fpsText = String(format: "FPS  %.0f", monitor.fps)
        let fpsAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 34, weight: .black),
            .foregroundColor: monitor.fps >= 55 ? UIColor(red: 0.0, green: 1.0, blue: 0.5, alpha: 1.0) : UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
        ]
        fpsText.draw(at: CGPoint(x: 20, y: 22), withAttributes: fpsAttr)
        
        // 4. Vẽ Chỉ số RAM & PING
        let ramText = String(format: "RAM: %.1f GB (%.0f%%)", monitor.usedRAM_MB / 1024.0, monitor.ramUsagePercent)
        let ramAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        ramText.draw(at: CGPoint(x: 20, y: 75), withAttributes: ramAttr)
        
        let pingText = String(format: "PING: %d ms • CPU: %.0f%%", monitor.pingMs, monitor.cpuUsagePercent)
        let pingAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .semibold),
            .foregroundColor: monitor.pingMs < 30 ? UIColor(red: 0.0, green: 0.95, blue: 1.0, alpha: 1.0) : UIColor(red: 1.0, green: 0.3, blue: 0.4, alpha: 1.0)
        ]
        pingText.draw(at: CGPoint(x: 20, y: 115), withAttributes: pingAttr)
        
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        
        // Đóng gói CMSampleBuffer và gửi tới layer PiP
        feedPixelBufferToLayer(pixelBuffer)
    }
    
    private func feedPixelBufferToLayer(_ pixelBuffer: CVPixelBuffer) {
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &formatDescription)
        guard let format = formatDescription else { return }
        
        var timing = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 30),
            presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),
            decodeTimeStamp: .invalid
        )
        
        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: format,
            sampleTiming: &timing,
            sampleBufferOut: &sampleBuffer
        )
        
        guard let buffer = sampleBuffer else { return }
        
        if sampleBufferLayer.status == .failed {
            sampleBufferLayer.flush()
        }
        
        if sampleBufferLayer.isReadyForMoreMediaData {
            sampleBufferLayer.enqueue(buffer)
        }
    }
}

// MARK: - AVPictureInPictureControllerDelegate
extension PiPHUDManager: AVPictureInPictureControllerDelegate {
    public func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        DispatchQueue.main.async { self.isPiPActive = true }
    }
    
    public func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        DispatchQueue.main.async {
            self.isPiPActive = false
            self.stopRenderingFrames()
        }
    }
}

// MARK: - AVPictureInPictureSampleBufferPlaybackDelegate
extension PiPHUDManager: AVPictureInPictureSampleBufferPlaybackDelegate {
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {}
    public func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        return CMTimeRange(start: .zero, duration: CMTime(value: 100000, timescale: 1))
    }
    public func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool { return false }
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, didTransitionToRenderSize newRenderSize: CMVideoDimensions) {}
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, skipByInterval skipInterval: CMTime, completion completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
