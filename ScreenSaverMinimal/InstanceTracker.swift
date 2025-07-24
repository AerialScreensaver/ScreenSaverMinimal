//
//  InstanceTracker.swift
//  ScreenSaverMinimal
//
//  Created for multi-monitor instance tracking and macOS stacking bug debugging
//

import Foundation

class InstanceTracker {
    static let shared = InstanceTracker()
    
    private let queue = DispatchQueue(label: "instance.tracker", qos: .utility)
    private var instanceCounter = 0
    private var instances: [Int: WeakRef] = [:]
    
    private init() {}
    
    func registerInstance(_ instance: ScreenSaverMinimalView) -> Int {
        return queue.sync {
            instanceCounter += 1
            instances[instanceCounter] = WeakRef(instance)
            return instanceCounter
        }
    }
    
    var totalInstances: Int {
        return queue.sync {
            // Clean up deallocated instances
            instances = instances.filter { $0.value.value != nil }
            return instances.count
        }
    }
}

class WeakRef {
    weak var value: ScreenSaverMinimalView?
    
    init(_ value: ScreenSaverMinimalView) {
        self.value = value
    }
}
