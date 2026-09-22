import SwiftUI

public struct StorageRingView: View {
    public let breakdown: StorageBreakdown
    
    public init(breakdown: StorageBreakdown) {
        self.breakdown = breakdown
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background Track
                Circle()
                    .stroke(Color(uiColor: .systemGray5), lineWidth: 18)
                    .frame(width: 170, height: 170)
                
                // Used Storage Arc
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(max(breakdown.usedPercentage, 0.02), 1.0)))
                    .stroke(
                        LinearGradient(
                            colors: [Color.blue, Color.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .frame(width: 170, height: 170)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: breakdown.usedPercentage)
                
                // Center Stats
                VStack(spacing: 4) {
                    Text("\(Int(breakdown.usedPercentage * 100))%")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primary)
                    
                    Text("Used")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 8)
            
            // Storage Stats Bar
            HStack(spacing: 24) {
                VStack(alignment: .center, spacing: 2) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                        Text("Used")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(breakdown.formattedUsedDisk)
                        .font(.subheadline.weight(.bold))
                }
                
                Divider()
                    .frame(height: 28)
                
                VStack(alignment: .center, spacing: 2) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 8, height: 8)
                        Text("Free")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(breakdown.formattedFreeDisk)
                        .font(.subheadline.weight(.bold))
                }
                
                Divider()
                    .frame(height: 28)
                
                VStack(alignment: .center, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 9))
                            .foregroundStyle(.orange)
                        Text("Cleanable")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(breakdown.formattedReclaimable)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(14)
        }
        .padding(20)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}
