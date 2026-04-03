import SwiftUI
import AppKit

struct ShredderView: View {
    @StateObject private var service = ShredderService()
    @Environment(\.localization) var localization
    
    // UI State Management
    @State private var showFileImporter = false
    
    var body: some View {
        ZStack {
            // Background
            BackgroundStyles.shredder
                .ignoresSafeArea()
            
            VStack {
                if service.isProcessing {
                    ShreddingProgressView(service: service)
                } else if !service.items.isEmpty {
                    if service.items.allSatisfy({ $0.status == "Done" || $0.status == "Failed" }) {
                        ShredderResultView(service: service)
                    } else {
                        ShredderSelectionView(service: service, showFileImporter: $showFileImporter)
                    }
                } else {
                    ShredderLandingView(showFileImporter: (Binding(get: {showFileImporter}, set: {showFileImporter = $0})), selectFiles: self.selectFiles)
                }
            }
        }
    }
    
    private func selectFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.prompt = "Select"
        
        panel.begin { response in
            if response == .OK {
                for url in panel.urls {
                    service.addItem(url: url)
                }
            }
        }
    }

}
