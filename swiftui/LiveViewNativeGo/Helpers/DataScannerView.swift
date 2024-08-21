//
//  DataScannerView.swift
//  LiveViewNativeGo
//
//  Created by Carson Katri on 5/14/24.
//

#if os(iOS)
import SwiftUI
import VisionKit

/// A View that scans for codes.
/// 
/// A binding is updated with the recognized items,
/// and an action performed when a scanned item is tapped.
struct DataScannerView: UIViewControllerRepresentable {
    var isActive: Bool = true
    @Binding var items: [RecognizedItem]
    
    var recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType>
    var qualityLevel: DataScannerViewController.QualityLevel = .balanced
    var recognizesMultipleItems: Bool = false
    var isHighFrameRateTrackingEnabled: Bool = true
    var isPinchToZoomEnabled: Bool = true
    var isGuidanceEnabled: Bool = true
    var isHighlightingEnabled: Bool = false
    
    let onTap: (RecognizedItem) -> ()
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: recognizedDataTypes,
            qualityLevel: qualityLevel,
            recognizesMultipleItems: recognizesMultipleItems,
            isHighFrameRateTrackingEnabled: isHighFrameRateTrackingEnabled,
            isPinchToZoomEnabled: isPinchToZoomEnabled,
            isGuidanceEnabled: isGuidanceEnabled,
            isHighlightingEnabled: isHighlightingEnabled
        )
        controller.delegate = context.coordinator
        if isActive {
            try? controller.startScanning()
        } else {
            controller.stopScanning()
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if isActive {
            try? uiViewController.startScanning()
        } else {
            uiViewController.stopScanning()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(items: $items, onTap: onTap)
    }
    
    class Coordinator: DataScannerViewControllerDelegate {
        @Binding var items: [RecognizedItem]
        let onTap: (RecognizedItem) -> ()
        
        init(
            items: Binding<[RecognizedItem]>,
            onTap: @escaping (RecognizedItem) -> Void
        ) {
            self._items = items
            self.onTap = onTap
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            onTap(item)
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            items = updatedItems
        }
    }
}
#endif
