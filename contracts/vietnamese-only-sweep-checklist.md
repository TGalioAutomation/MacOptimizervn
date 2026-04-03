# Vietnamese-Only Sweep Checklist

Muc tieu:
- Khong con text tieng Trung trong source runtime.
- Khong con nhanh song ngu Anh/Viet.
- App chi ho tro tieng Viet.

Gate tong:
- `rg 'currentLanguage == \\.vietnamese|\\.english|englishTitle|englishDescription|englishName|toggleLanguage' AppUninstaller` = `0`
- `rg '\\p{Han}' AppUninstaller --glob '*.swift'` = `0`
- `./build.sh` thanh cong
- Mo duoc `build/MacOptimizer.app`

## P0

### Dev 1 - Localization Core
- Owner:
  [LocalizationManager.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/LocalizationManager.swift)
  [NavigationSidebar.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/NavigationSidebar.swift)
  [Styles.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/Styles.swift)
- Muc tieu:
  - Bo `AppLanguage.english`
  - Bo `toggleLanguage()`
  - Bo moi pattern `currentLanguage == .vietnamese ? ... : ...`
  - Co dinh app sang tieng Viet
- Done khi:
  - Khong con `.english`
  - Khong con `englishTitle`, `englishDescription`, `englishName`
  - Khong con nut doi ngon ngu

### Lead/QA - Gate P0
- Chay:
  - `rg 'currentLanguage == \\.vietnamese|\\.english|englishTitle|englishDescription|englishName|toggleLanguage' AppUninstaller`
- Merge P0 truoc khi mo P1/P2

## P1

### Dev 2 - Privacy Stack
- Owner:
  [PrivacyScannerService.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/PrivacyScannerService.swift)
  [PrivacyView.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/PrivacyView.swift)
  [ProtectionService.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/ProtectionService.swift)
- Muc tieu:
  - Viet hoa enum, displayPath, permission label, notification, alert, scan status
- Done khi:
  - `rg '\\p{Han}'` tren 3 file ve `0`

### Dev 3 - Smart Scan / Deep Clean
- Owner:
  [SmartCleanerService.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/SmartCleanerService.swift)
  [SmartCleanerView.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/SmartCleanerView.swift)
  [DeepCleanScanner.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/DeepCleanScanner.swift)
  [DeepCleanView.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/DeepCleanView.swift)
- Muc tieu:
  - Xoa text Trung trong category, progress message, item name runtime, CTA, result card
  - Xoa token loi nhu `XVAR0ZX`, `HzVAR0ZX`
- Done khi:
  - Khong con text Trung hien thi o flow Smart Scan / Deep Clean

### Dev 4 - Maintenance / Optimizer / Safety
- Owner:
  [MaintenanceView.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/MaintenanceView.swift)
  [SystemOptimizer.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/SystemOptimizer.swift)
  [SafetyGuard.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/SafetyGuard.swift)
  [FileRemover.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/FileRemover.swift)
- Muc tieu:
  - Viet hoa task name, warning/risk text, maintenance label, privileged-delete messaging
- Done khi:
  - Moi warning hien thi voi user la tieng Viet

### Dev 5 - Uninstaller / File / Update
- Owner:
  [AppUninstallerView.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/AppUninstallerView.swift)
  [AppDetailView.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/AppDetailView.swift)
  [LargeFileView.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/LargeFileView.swift)
  [LargeFileDetailsSplitView.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/LargeFileDetailsSplitView.swift)
  [FileExplorerView.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/FileExplorerView.swift)
  [AppUpdaterView.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/AppUpdaterView.swift)
  [UpdateCheckerService.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/UpdateCheckerService.swift)
- Muc tieu:
  - Xoa text Trung/Anh con lai o uninstall, large files, explorer, updater
- Done khi:
  - CTA, dialog, result message o nhom file-tools la tieng Viet thong nhat

## P2

### Dev 6 - Menu Bar / Monitor
- Owner:
  [MenuBar](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/MenuBar)
  [MonitorView.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/MonitorView.swift)
  [ConsoleComponents](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/ConsoleComponents)
  [SystemMonitorService.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/SystemMonitorService.swift)
- Muc tieu:
  - Xoa text Trung trong widget, detail view, alert window, process/network labels
- Done khi:
  - Menu bar va monitor chi con tieng Viet

### Dev 7 - Malware / Legacy / Sweep
- Owner:
  [MalwareScanner.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/MalwareScanner.swift)
  [Models.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/Models.swift)
  [JunkCleanerView.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/JunkCleanerView.swift)
  [TrashView.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/TrashView.swift)
  [SmartScanLegacySupport.swift](/Users/apex/Desktop/MacOptimizervn/AppUninstaller/SmartScanLegacySupport.swift)
- Muc tieu:
  - Don module ria va legacy
  - Sweep toan repo cho text Trung con sot
- Done khi:
  - `rg '\\p{Han}' AppUninstaller --glob '*.swift'` ve `0`

## QA Checklist
- [ ] Gate P0 pass
- [ ] Gate text Trung pass
- [ ] `./build.sh` pass
- [ ] `open build/MacOptimizer.app` pass
- [ ] Smoke test:
  - [ ] Smart Scan
  - [ ] Deep Clean
  - [ ] Privacy
  - [ ] Uninstaller
  - [ ] Large Files
  - [ ] Menu Bar
