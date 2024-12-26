//
//  LogsScreen.swift
//  LiveViewNativeGo
//
//  Created by Carson Katri on 10/22/24.
//

import SwiftUI
import OSLog

struct LogsScreen: View {
    @State private var logs = Logs()
    @State private var selection: Int?
    
    let dateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
    
    var body: some View {
        List(logs.logs, id: \.offset, selection: $selection) { entry in
            let (_, log) = entry
            VStack(alignment: .leading) {
                HStack {
                    Text(log.subsystem)
                    Spacer()
                    Text(log.date, formatter: dateFormatter)
                }
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Text(log.composedMessage)
                    .font(.body.monospaced())
            }
            #if os(tvOS)
            .focusable()
            #endif
            #if !os(tvOS)
            .contextMenu {
                Button("Copy") {
                    #if os(macOS)
                    let pasteboard = NSPasteboard.general
                    pasteboard.declareTypes([.string], owner: nil)
                    pasteboard.setString(log.composedMessage, forType: .string)
                    #else
                    UIPasteboard.general.string = log.composedMessage
                    #endif
                }
            }
            #endif
            .listRowBackground(Group {
                switch log.level {
                case .error:
                    Color.red.opacity(0.2)
                default:
                    EmptyView()
                }
            })
        }
        .defaultScrollAnchor(.bottom)
        #if os(iOS)
        .listStyle(.plain)
        #endif
        #if os(macOS)
        .onCopyCommand {
            guard let selection else { return [] }
            return [NSItemProvider(object: logs.logs[selection].element.composedMessage as NSString)]
        }
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    logs.startDate = .now
                    logs.logs = []
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }
}

#Preview {
    LogsScreen()
}
