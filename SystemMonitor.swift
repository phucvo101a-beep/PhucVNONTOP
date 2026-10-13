import Foundation
import UIKit
import QuartzCore
import Darwin
import Combine

/// Lớp giám sát tài nguyên hệ thống theo thời gian thực (FPS, RAM, Ping, CPU)
public final class SystemMonitor: ObservableObject {
    public static let shared = SystemMonitor()
    
    @Published public var fps: Double = 60.0
    @Published public var usedRAM_MB: Double = 0.0
    @Published public var totalRAM_MB: Double = 0.0
    @Published public var ramUsagePercent: Double = 0.0
    @Published public var pingMs: Int = 15
    @Published public var cpuUsagePercent: Double = 0.0
    
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount: Int = 0
    private var timer: Timer?
    
    private init() {
        totalRAM_MB = Double(ProcessInfo.processInfo.physicalMemory) / (1024.0 * 1024.0)
    }
    
    public func start() {
        stop()
        
        // 1. Theo dõi FPS thực tế bằng CADisplayLink
        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
        displayLink?.add(to: .main, forMode: .common)
        
        // 2. Định kỳ cập nhật RAM, Ping, CPU mỗi 0.5 giây
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateRAM()
            self?.updateCPU()
            self?.measurePing()
        }
    }
    
    public func stop() {
        displayLink?.invalidate()
        displayLink = nil
        timer?.invalidate()
        timer = nil
        lastTimestamp = 0
        frameCount = 0
    }
    
    @objc private func handleDisplayLink(_ link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }
        frameCount += 1
        let delta = link.timestamp - lastTimestamp
        if delta >= 0.5 {
            let currentFPS = Double(frameCount) / delta
            DispatchQueue.main.async {
                self.fps = min(120.0, max(0.0, currentFPS))
            }
            frameCount = 0
            lastTimestamp = link.timestamp
        }
    }
    
    private func updateRAM() {
        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let hostPort = mach_host_self()
        
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let pageSize = Double(vm_kernel_page_size)
            let active = Double(vmStats.active_count) * pageSize
            let wired = Double(vmStats.wire_count) * pageSize
            let compressed = Double(vmStats.compressor_page_count) * pageSize
            let usedBytes = active + wired + compressed
            let usedMB = usedBytes / (1024.0 * 1024.0)
            
            DispatchQueue.main.async {
                self.usedRAM_MB = usedMB
                if self.totalRAM_MB > 0 {
                    self.ramUsagePercent = (usedMB / self.totalRAM_MB) * 100.0
                }
            }
        }
    }
    
    private func updateCPU() {
        var cpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0
        var numProcessors: natural_t = 0
        
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numProcessors, &cpuInfo, &numCpuInfo)
        if result == KERN_SUCCESS, let cpuInfo = cpuInfo {
            // Tính toán CPU usage cơ bản
            var inUse: Int32 = 0
            var total: Int32 = 0
            for i in 0..<Int(numProcessors) {
                let user = cpuInfo[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_USER)]
                let system = cpuInfo[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_SYSTEM)]
                let nice = cpuInfo[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_NICE)]
                let idle = cpuInfo[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_IDLE)]
                
                inUse += user + system + nice
                total += user + system + nice + idle
            }
            if total > 0 {
                let usage = (Double(inUse) / Double(total)) * 100.0
                DispatchQueue.main.async {
                    self.cpuUsagePercent = min(100.0, max(0.0, usage))
                }
            }
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(numCpuInfo))
        }
    }
    
    private func measurePing() {
        guard let url = URL(string: "https://1.1.1.1/cdn-cgi/trace") else { return }
        let startTime = CFAbsoluteTimeGetCurrent()
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 1.5)
        request.httpMethod = "HEAD"
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] _, response, _ in
            if response != nil {
                let latency = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000.0)
                DispatchQueue.main.async {
                    self?.pingMs = min(999, max(1, latency))
                }
            }
        }
        task.resume()
    }
}
