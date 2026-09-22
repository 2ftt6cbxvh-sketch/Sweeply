import SwiftUI

public struct PermissionNoticeView: View {
    public let title: String
    public let message: String
    public let isDenied: Bool
    public let onAction: () -> Void
    
    public init(title: String, message: String, isDenied: Bool, onAction: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.isDenied = isDenied
        self.onAction = onAction
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 72, height: 72)
                
                Image(systemName: isDenied ? "lock.shield.fill" : "hand.raised.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.blue)
            }
            
            Text(title)
                .font(.title3.weight(.bold))
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                Text("100% Private & On-Device Only")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
            
            Button(action: onAction) {
                Text(isDenied ? "Open Settings" : "Allow Access")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)
        }
        .padding(24)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 20)
    }
}
