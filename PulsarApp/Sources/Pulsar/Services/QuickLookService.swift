import Foundation
import AppKit
import QuickLookUI

public final class QuickLookService: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    public static let shared = QuickLookService()

    private var currentPreviewURL: URL?

    private override init() {
        super.init()
    }

    public func preview(url: URL) {
        currentPreviewURL = url
        DispatchQueue.main.async {
            guard let panel = QLPreviewPanel.shared() else { return }
            panel.dataSource = self
            panel.delegate = self
            panel.reloadData()
            panel.makeKeyAndOrderFront(nil)
        }
    }

    public func togglePreview(for url: URL) {
        if let panel = QLPreviewPanel.shared(), panel.isVisible && currentPreviewURL == url {
            panel.orderOut(nil)
            currentPreviewURL = nil
        } else {
            preview(url: url)
        }
    }

    public func closePreview() {
        if let panel = QLPreviewPanel.shared(), panel.isVisible {
            panel.orderOut(nil)
            currentPreviewURL = nil
        }
    }

    // MARK: - QLPreviewPanelDataSource
    public func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        return currentPreviewURL != nil ? 1 : 0
    }

    public func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        guard let url = currentPreviewURL else {
            return URL(fileURLWithPath: "") as NSURL
        }
        return url as NSURL
    }
}
