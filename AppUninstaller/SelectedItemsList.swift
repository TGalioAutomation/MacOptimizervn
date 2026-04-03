import SwiftUI

struct SelectedItemsList: View {
    let items: [FileNode]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(items) { item in
                HStack(spacing: 12) {
                    // Checkmark
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(red: 0.2, green: 0.7, blue: 1.0))
                        .font(.system(size: 16))
                        .background(Circle().fill(Color.white).frame(width: 8, height: 8))
                    
                    // Folder Icon
                    Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path))
                        .resizable()
                        .frame(width: 32, height: 32)
                    
                    VStack(alignment: .leading, spacing: 2) {
                         Text(item.name)
                             .font(.system(size: 14, weight: .semibold))
                             .foregroundColor(.white)
                             .lineLimit(1)
                         Text(item.url.path)
                             .font(.system(size: 11))
                             .foregroundColor(.white.opacity(0.6))
                             .lineLimit(1)
                             .truncationMode(.middle)
                    }
                    
                    Spacer()
                    
                    Text(item.formattedSize)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(24)
        .frame(width: 400)
        .background(Color(red: 0.18, green: 0.18, blue: 0.20))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}
