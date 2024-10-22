//
//  Logs.swift
//  LiveViewNativeGo
//
//  Created by Carson Katri on 10/22/24.
//

import SwiftUI
import OSLog
import Combine

@Observable final class Logs {
    private var store: OSLogStore!
    private var cancellable: AnyCancellable?
    
    var startDate: Date?
    
    var logs = Array<EnumeratedSequence<[OSLogEntryLog]>.Element>()
    
    init() {
        if let store = try? OSLogStore(scope: .currentProcessIdentifier) {
            self.store = store
            let predicate = NSPredicate(format: "subsystem IN %@", [
                "LiveViewNative",
                "com.dockyard.LiveViewNativeGo"
            ])
            self.cancellable = Timer
                .publish(every: 1, on: .current, in: .default)
                .autoconnect()
                .sink { date in
                    Task { [weak self] in
                        guard let self
                        else { return }
                        let position = self.startDate.flatMap({ self.store.position(date: $0) })
                        let logs = try self.store.getEntries(at: position, matching: predicate)
                        var logEntryLogs = logs.compactMap({ $0 as? OSLogEntryLog })
                        if let startDate = self.startDate {
                            logEntryLogs = logEntryLogs.filter({
                                $0.date >= startDate
                            })
                        }
                        self.logs = Array(logEntryLogs.enumerated())
                    }
                }
        }
    }
}
