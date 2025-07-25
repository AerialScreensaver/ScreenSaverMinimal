//
//  InstanceTracker.swift
//  ScreenSaverMinimal
//
//  Created for multi-monitor instance tracking and macOS stacking bug debugging
//

import Foundation

// MARK: - Notification Extensions
extension Notification.Name {
    static let instanceCountChanged = Notification.Name("instanceCountChanged")
}

class InstanceTracker {
    static let shared = InstanceTracker()
    
    private let queue = DispatchQueue(label: "instance.tracker", qos: .utility)
    private var instanceCounter = 0
    private var instances: [Int: WeakRef] = [:]
    
    private init() {}
    
    func registerInstance(_ instance: ScreenSaverMinimalView) -> Int {
        let instanceNumber = queue.sync {
            instanceCounter += 1
            instances[instanceCounter] = WeakRef(instance)
            return instanceCounter
        }
        
        // Post notification on main queue for UI updates
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .instanceCountChanged, object: nil)
        }
        
        return instanceNumber
    }
    
    var totalInstances: Int {
        return queue.sync {
            // Clean up deallocated instances
            let oldCount = instances.count
            instances = instances.filter { $0.value.value != nil }
            let newCount = instances.count
            
            // Post notification if count changed due to cleanup
            if oldCount != newCount {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .instanceCountChanged, object: nil)
                }
            }
            
            return newCount
        }
    }
    
    // Convenience method for getting count without potential side effects
    func getTotalInstanceCount() -> Int {
        return totalInstances
    }
}

class WeakRef {
    weak var value: ScreenSaverMinimalView?
    
    init(_ value: ScreenSaverMinimalView) {
        self.value = value
    }
}
