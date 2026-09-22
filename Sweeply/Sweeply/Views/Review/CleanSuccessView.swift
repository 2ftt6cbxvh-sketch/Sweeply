import SwiftUI

public struct CleanSuccessView: View {
    public let freedBytes: Int64
    public let onDismiss: () -> Void
    
    public init(freedBytes: Int64, onDismiss: @escaping () -> Void) {
        self.freedBytes = freedBytes
        self.onDismiss = onDismiss
    }
    
    public var formattedFreed: String {
        ByteCountFormatter.string(fromByteCount: freedBytes, countStyle: .file)
    }
    
    public var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            // Confetti Animation
            ConfettiView()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Celebration Badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.2), Color.blue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 130, height: 130)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.green, Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 8) {
                    Text("Space Freed!")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text(formattedFreed)
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.green)
                    
                    Text("Successfully cleaned from your device storage.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // Recovery reminder
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Items can be recovered from Recently Deleted for 30 days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 24)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Text("Back to Dashboard")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.blue)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}
