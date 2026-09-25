import SwiftUI

public enum StorageDisplayMode: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case cleanable = "Cleanable"
    case breakdown = "Categories"
    
    public var id: Self { self }
    
    public var icon: String {
        switch self {
        case .overview: return "internaldrive.fill"
        case .cleanable: return "sparkles"
        case .breakdown: return "chart.bar.xaxis"
        }
    }
}

/// Standout partitioned Storage Intelligence view featuring dynamic data charts,
/// interactive mode controls, and a floating circular progress ring on the right.
public struct StoragePartitionView: View {
    public let breakdown: StorageBreakdown
    @State private var displayMode: StorageDisplayMode = .overview
    @State private var isExpanded: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    public init(breakdown: StorageBreakdown) {
        self.breakdown = breakdown
        if ProcessInfo.processInfo.arguments.contains("-mode-cleanable") {
            _displayMode = State(initialValue: .cleanable)
        } else if ProcessInfo.processInfo.arguments.contains("-mode-categories") {
            _displayMode = State(initialValue: .breakdown)
        }
        if ProcessInfo.processInfo.arguments.contains("-expand-pill") {
            _isExpanded = State(initialValue: true)
        }
    }
    
    public var body: some View {
        VStack(spacing: 14) {
            // MARK: - Top Partition Controls (The Expandable Dashboard Pills)
            partitionControls
            
            // MARK: - Main Partition Hero (Left: Dynamic Data Charts, Right: Floating Circle Ring)
            HStack(alignment: .center, spacing: 14) {
                // Left Column: Dynamic Data Charts based on selected mode
                VStack(alignment: .leading, spacing: 8) {
                    switch displayMode {
                    case .overview:
                        overviewChartContent
                    case .cleanable:
                        cleanableChartContent
                    case .breakdown:
                        breakdownChartContent
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: displayMode)
                
                // Right Column: Floating Circle Progress Gauge
                FloatingStorageRing(
                    breakdown: breakdown,
                    mode: displayMode
                )
                .frame(width: 98, height: 98)
            }
            
            // MARK: - Expanded Detailed Data Breakdown Section
            if isExpanded {
                Divider()
                    .background(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.40))
                    .padding(.horizontal, 2)
                    .transition(.opacity)
                
                expandedBreakdownSection
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Bottom Expand / Collapse Tap Affordance
            expandToggleAffordance
        }
        .liquidGlass(cornerRadius: 24, padding: 16)
    }
    
    // MARK: - Mode Switcher Controls (Dashboard Pills)
    
    @ViewBuilder
    private var partitionControls: some View {
        HStack(spacing: 6) {
            ForEach(StorageDisplayMode.allCases) { mode in
                Button {
                    HapticService.shared.selection()
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        if displayMode == mode {
                            // Tapping the active pill toggles expand/collapse
                            isExpanded.toggle()
                        } else {
                            // Tapping another pill switches mode AND expands details
                            displayMode = mode
                            isExpanded = true
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 11, weight: .bold))
                        Text(mode.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                        
                        if displayMode == mode {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.85) : Color(red: 0.05, green: 0.40, blue: 0.90))
                                .contentTransition(.symbolEffect(.replace))
                        }
                    }
                    .foregroundStyle(
                        displayMode == mode
                            ? (colorScheme == .dark ? Color.white : Color(red: 0.05, green: 0.10, blue: 0.25))
                            : Color.secondary
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background {
                        if displayMode == mode {
                            Capsule()
                                .fill(
                                    colorScheme == .dark
                                        ? Color.white.opacity(0.18)
                                        : Color.white.opacity(0.92)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(colorScheme == .dark ? 0.45 : 0.95),
                                                    Color.white.opacity(colorScheme == .dark ? 0.10 : 0.35)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 4, y: 1)
                        } else {
                            Capsule()
                                .fill(Color.clear)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(
                    colorScheme == .dark
                        ? Color(white: 0.07).opacity(0.8)
                        : Color(uiColor: .systemGray6).opacity(0.85)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.30), lineWidth: 0.5)
                )
        )
    }
    
    // MARK: - Mode 1: Overview Chart Content
    
    @ViewBuilder
    private var overviewChartContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Circle()
                    .fill(Color(red: 0.15, green: 0.55, blue: 1.0))
                    .frame(width: 6, height: 6)
                Text("TOTAL STORAGE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(breakdown.formattedUsedDisk)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.primary)
                Text("of \(breakdown.formattedTotalDisk)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            
            // Capacity gradient bar
            GeometryReader { geo in
                let pct = min(max(CGFloat(breakdown.usedPercentage), 0.05), 1.0)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.10) : Color(uiColor: .systemGray5))
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.10, green: 0.50, blue: 1.0),
                                    Color(red: 0.30, green: 0.35, blue: 0.95),
                                    Color(red: 0.55, green: 0.20, blue: 0.90)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * pct)
                }
            }
            .frame(height: 8)
            .padding(.vertical, 2)
            
            // Available badge pill
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 5, height: 5)
                        .shadow(color: .green.opacity(0.6), radius: 3)
                    Text("\(breakdown.formattedFreeDisk) free")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.primary.opacity(0.85))
                }
                
                if breakdown.totalReclaimableBytes > 0 {
                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    
                    HStack(spacing: 3) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.orange)
                        Text("\(breakdown.formattedReclaimable) cleanable")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
    }
    
    // MARK: - Mode 2: Cleanable Space Chart Content
    
    @ViewBuilder
    private var cleanableChartContent: some View {
        let totalItems = breakdown.similarPhotosCount + breakdown.screenshotsCount + breakdown.largeVideosCount + breakdown.blurryPhotosCount
        let cleanablePct = breakdown.percentageOfFilledStorage(bytes: breakdown.totalReclaimableBytes)
        
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.orange)
                Text("RECLAIMABLE JUNK")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.orange)
                    .tracking(0.5)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(breakdown.formattedReclaimable)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange, Color(red: 1.0, green: 0.35, blue: 0.25)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("can be freed")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            
            // Cleanable potential bar
            GeometryReader { geo in
                let ratio = min(max(CGFloat(cleanablePct / 100.0), 0.06), 1.0)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.10) : Color(uiColor: .systemGray5))
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color(red: 1.0, green: 0.40, blue: 0.20)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * ratio)
                }
            }
            .frame(height: 8)
            .padding(.vertical, 2)
            
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.green)
                Text("\(totalItems) items across duplicates & clips • \(String(format: "%.1f%%", cleanablePct)) of filled disk")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
    
    // MARK: - Mode 3: Categories Breakdown Chart Content
    
    @ViewBuilder
    private var breakdownChartContent: some View {
        let used = max(Double(breakdown.usedDiskBytes), 1.0)
        let videosPct = CGFloat(Double(breakdown.largeVideosBytes) / used)
        let similarPct = CGFloat(Double(breakdown.similarPhotosBytes) / used)
        let screenshotsPct = CGFloat(Double(breakdown.screenshotsBytes) / used)
        
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Circle()
                    .fill(Color.purple)
                    .frame(width: 6, height: 6)
                Text("CATEGORY SHARE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
            }
            
            categoryMiniRow(
                color: Color.orange,
                label: "Videos",
                sizeText: ByteCountFormatter.string(fromByteCount: breakdown.largeVideosBytes, countStyle: .file),
                ratio: max(videosPct, 0.08)
            )
            
            categoryMiniRow(
                color: Color.blue,
                label: "Similar",
                sizeText: ByteCountFormatter.string(fromByteCount: breakdown.similarPhotosBytes, countStyle: .file),
                ratio: max(similarPct, 0.06)
            )
            
            categoryMiniRow(
                color: Color.purple,
                label: "Screenshots",
                sizeText: ByteCountFormatter.string(fromByteCount: breakdown.screenshotsBytes, countStyle: .file),
                ratio: max(screenshotsPct, 0.04)
            )
        }
    }
    
    private func categoryMiniRow(color: Color, label: String, sizeText: String, ratio: CGFloat) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 76, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color(uiColor: .systemGray5))
                    Capsule()
                        .fill(color)
                        .frame(width: max(geo.size.width * min(ratio, 1.0), 6))
                }
            }
            .frame(height: 6)
            
            Text(sizeText)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .frame(width: 48, alignment: .trailing)
        }
    }
    
    // MARK: - Expanded Breakdown Container
    
    @ViewBuilder
    private var expandedBreakdownSection: some View {
        VStack(spacing: 12) {
            switch displayMode {
            case .overview:
                expandedOverviewSection
            case .cleanable:
                expandedCleanableSection
            case .breakdown:
                expandedBreakdownDetailsSection
            }
        }
        .padding(.top, 4)
    }
    
    // MARK: - Expand / Collapse Affordance
    
    @ViewBuilder
    private var expandToggleAffordance: some View {
        Button {
            HapticService.shared.selection()
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 4) {
                Text(isExpanded ? "Collapse Breakdown" : "Tap pill to view deep storage breakdown")
                    .font(.system(size: 11, weight: .semibold))
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(Color.secondary)
            .padding(.top, 2)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Expanded Overview Details
    
    @ViewBuilder
    private var expandedOverviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.blue)
                Text("DISK ANATOMY ALLOCATION")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                Spacer()
                Text("\(Int(breakdown.usedPercentage * 100))% Utilized")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            
            // Stacked capacity bar
            diskAnatomyStackedBar
            
            // Legend
            diskAnatomyLegend
            
            // 2x2 Deep Metric Cards
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                metricCard(
                    icon: "sparkles",
                    iconColor: .orange,
                    title: "Cleanable Junk",
                    value: breakdown.formattedReclaimable,
                    subtitle: String(format: "%.1f%% of filled disk", breakdown.percentageOfFilledStorage(bytes: breakdown.totalReclaimableBytes))
                )
                metricCard(
                    icon: "photo.stack",
                    iconColor: .blue,
                    title: "Media Library",
                    value: ByteCountFormatter.string(fromByteCount: totalMediaBytes, countStyle: .file),
                    subtitle: "\(totalMediaCount) files"
                )
                metricCard(
                    icon: "checkmark.circle.fill",
                    iconColor: .green,
                    title: "Free Space",
                    value: breakdown.formattedFreeDisk,
                    subtitle: String(format: "%.1f%% available", breakdown.freePercentage * 100.0)
                )
                metricCard(
                    icon: "arrow.up.forward.circle.fill",
                    iconColor: .cyan,
                    title: "Post-Clean Space",
                    value: ByteCountFormatter.string(fromByteCount: breakdown.freeDiskBytes + breakdown.totalReclaimableBytes, countStyle: .file),
                    subtitle: "+\(breakdown.formattedReclaimable) recovery"
                )
            }
        }
    }
    
    // MARK: - Expanded Cleanable Details
    
    @ViewBuilder
    private var expandedCleanableSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.orange)
                Text("RECLAIMABLE JUNK BREAKDOWN")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.orange)
                    .tracking(0.5)
                Spacer()
                Text("\(totalCleanableItems) items ready")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 6) {
                cleanableDetailRow(
                    icon: "photo.stack.fill",
                    color: .blue,
                    title: "Similar Photos & Bursts",
                    subtitle: "\(breakdown.similarPhotosCount) duplicates & burst series",
                    sizeText: ByteCountFormatter.string(fromByteCount: breakdown.similarPhotosBytes, countStyle: .file),
                    sharePct: cleanableShare(bytes: breakdown.similarPhotosBytes)
                )
                cleanableDetailRow(
                    icon: "video.fill",
                    color: .orange,
                    title: "Large Videos",
                    subtitle: "\(breakdown.largeVideosCount) heavy video clips",
                    sizeText: ByteCountFormatter.string(fromByteCount: breakdown.largeVideosBytes, countStyle: .file),
                    sharePct: cleanableShare(bytes: breakdown.largeVideosBytes)
                )
                cleanableDetailRow(
                    icon: "iphone",
                    color: .purple,
                    title: "Screenshots & Receipts",
                    subtitle: "\(breakdown.screenshotsCount) temporary screen captures",
                    sizeText: ByteCountFormatter.string(fromByteCount: breakdown.screenshotsBytes, countStyle: .file),
                    sharePct: cleanableShare(bytes: breakdown.screenshotsBytes)
                )
                cleanableDetailRow(
                    icon: "eye.slash.fill",
                    color: .pink,
                    title: "Blurry & Pocket Photos",
                    subtitle: "\(breakdown.blurryPhotosCount) low-clarity shots",
                    sizeText: ByteCountFormatter.string(fromByteCount: breakdown.blurryPhotosBytes, countStyle: .file),
                    sharePct: cleanableShare(bytes: breakdown.blurryPhotosBytes)
                )
                if breakdown.duplicateContactsCount > 0 {
                    cleanableDetailRow(
                        icon: "person.2.fill",
                        color: .green,
                        title: "Duplicate Contacts",
                        subtitle: "\(breakdown.duplicateContactsCount) contacts across \(breakdown.duplicateContactsSets) sets",
                        sizeText: "\(breakdown.duplicateContactsSets) sets",
                        sharePct: nil
                    )
                }
            }
            
            HStack(spacing: 8) {
                Image(systemName: "bolt.shield.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.orange)
                Text("Safe Clean: Items remain in Recently Deleted for 30 days")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.primary.opacity(0.85))
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.orange.opacity(colorScheme == .dark ? 0.15 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.orange.opacity(0.25), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Expanded Categories Details
    
    @ViewBuilder
    private var expandedBreakdownDetailsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.purple)
                Text("CATEGORY STORAGE ANALYTICS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                Spacer()
                Text("\(totalMediaCount) Total Files")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 6) {
                categoryAnalyticsCard(
                    icon: "video.fill",
                    color: .orange,
                    name: "Large Videos",
                    countText: "\(breakdown.largeVideosCount) files",
                    sizeText: ByteCountFormatter.string(fromByteCount: breakdown.largeVideosBytes, countStyle: .file),
                    avgSizeText: avgFileSize(bytes: breakdown.largeVideosBytes, count: breakdown.largeVideosCount),
                    pctOfMedia: mediaShare(bytes: breakdown.largeVideosBytes)
                )
                categoryAnalyticsCard(
                    icon: "photo.stack.fill",
                    color: .blue,
                    name: "Similar Photos",
                    countText: "\(breakdown.similarPhotosCount) files",
                    sizeText: ByteCountFormatter.string(fromByteCount: breakdown.similarPhotosBytes, countStyle: .file),
                    avgSizeText: avgFileSize(bytes: breakdown.similarPhotosBytes, count: breakdown.similarPhotosCount),
                    pctOfMedia: mediaShare(bytes: breakdown.similarPhotosBytes)
                )
                categoryAnalyticsCard(
                    icon: "iphone",
                    color: .purple,
                    name: "Screenshots",
                    countText: "\(breakdown.screenshotsCount) files",
                    sizeText: ByteCountFormatter.string(fromByteCount: breakdown.screenshotsBytes, countStyle: .file),
                    avgSizeText: avgFileSize(bytes: breakdown.screenshotsBytes, count: breakdown.screenshotsCount),
                    pctOfMedia: mediaShare(bytes: breakdown.screenshotsBytes)
                )
                categoryAnalyticsCard(
                    icon: "eye.slash.fill",
                    color: .cyan,
                    name: "Blurry Photos",
                    countText: "\(breakdown.blurryPhotosCount) files",
                    sizeText: ByteCountFormatter.string(fromByteCount: breakdown.blurryPhotosBytes, countStyle: .file),
                    avgSizeText: avgFileSize(bytes: breakdown.blurryPhotosBytes, count: breakdown.blurryPhotosCount),
                    pctOfMedia: mediaShare(bytes: breakdown.blurryPhotosBytes)
                )
            }
        }
    }
    
    // MARK: - Reusable UI Components
    
    @ViewBuilder
    private var diskAnatomyStackedBar: some View {
        let total = max(Double(breakdown.totalDiskBytes), 1.0)
        let reclaimable = Double(breakdown.totalReclaimableBytes)
        let mediaTotal = Double(totalMediaBytes)
        let keepMedia = max(mediaTotal - reclaimable, 0.0)
        let systemAndApps = max(Double(breakdown.usedDiskBytes) - mediaTotal, 0.0)
        let free = Double(breakdown.freeDiskBytes)
        
        GeometryReader { geo in
            let w = geo.size.width
            let rSys = CGFloat(systemAndApps / total)
            let rKeep = CGFloat(keepMedia / total)
            let rRec = CGFloat(reclaimable / total)
            let rFree = CGFloat(free / total)
            
            HStack(spacing: 2) {
                Rectangle()
                    .fill(Color.gray.opacity(0.65))
                    .frame(width: max(w * rSys, 4))
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: max(w * rKeep, 4))
                
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: max(w * rRec, 4))
                
                Rectangle()
                    .fill(Color.green)
                    .frame(width: max(w * rFree, 4))
            }
            .clipShape(Capsule())
        }
        .frame(height: 8)
    }
    
    @ViewBuilder
    private var diskAnatomyLegend: some View {
        let systemAndApps = max(breakdown.usedDiskBytes - totalMediaBytes, 0)
        
        HStack(spacing: 6) {
            legendItem(color: Color.gray.opacity(0.65), text: "OS/Apps", size: ByteCountFormatter.string(fromByteCount: systemAndApps, countStyle: .file))
            legendItem(color: Color.blue, text: "Keep", size: ByteCountFormatter.string(fromByteCount: max(totalMediaBytes - breakdown.totalReclaimableBytes, 0), countStyle: .file))
            legendItem(color: Color.orange, text: "Junk", size: breakdown.formattedReclaimable)
            legendItem(color: Color.green, text: "Free", size: breakdown.formattedFreeDisk)
        }
    }
    
    private func legendItem(color: Color, text: String, size: String) -> some View {
        HStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
            Text("\(text) (\(size))")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
    
    private func metricCard(
        icon: String,
        iconColor: Color,
        title: String,
        value: String,
        subtitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Text(value)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
            
            Text(subtitle)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    colorScheme == .dark
                        ? Color.white.opacity(0.04)
                        : Color.white.opacity(0.60)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.35), lineWidth: 0.8)
                )
        )
    }
    
    private func cleanableDetailRow(
        icon: String,
        color: Color,
        title: String,
        subtitle: String,
        sizeText: String,
        sharePct: Double?
    ) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(colorScheme == .dark ? 0.20 : 0.12))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.primary)
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(sizeText)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                
                if let share = sharePct {
                    Text(String(format: "%.1f%% of junk", share))
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(color)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    colorScheme == .dark
                        ? Color.white.opacity(0.04)
                        : Color.white.opacity(0.60)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.35), lineWidth: 0.8)
                )
        )
    }
    
    private func categoryAnalyticsCard(
        icon: String,
        color: Color,
        name: String,
        countText: String,
        sizeText: String,
        avgSizeText: String,
        pctOfMedia: Double
    ) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(color)
                
                Text(name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.primary)
                
                Spacer()
                
                Text(countText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Text("•")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                
                Text(sizeText)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
            }
            
            HStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color(uiColor: .systemGray5))
                        Capsule()
                            .fill(color)
                            .frame(width: max(geo.size.width * CGFloat(min(pctOfMedia / 100.0, 1.0)), 6))
                    }
                }
                .frame(height: 6)
                
                Text(String(format: "%.1f%% of media (avg %@)", pctOfMedia, avgSizeText))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    colorScheme == .dark
                        ? Color.white.opacity(0.04)
                        : Color.white.opacity(0.60)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.35), lineWidth: 0.8)
                )
        )
    }
    
    // MARK: - Calculations
    
    private var totalMediaBytes: Int64 {
        breakdown.largeVideosBytes + breakdown.similarPhotosBytes + breakdown.screenshotsBytes + breakdown.blurryPhotosBytes
    }
    
    private var totalMediaCount: Int {
        breakdown.largeVideosCount + breakdown.similarPhotosCount + breakdown.screenshotsCount + breakdown.blurryPhotosCount
    }
    
    private var totalCleanableItems: Int {
        breakdown.similarPhotosCount + breakdown.screenshotsCount + breakdown.largeVideosCount + breakdown.blurryPhotosCount
    }
    
    private func cleanableShare(bytes: Int64) -> Double? {
        guard breakdown.totalReclaimableBytes > 0 && bytes > 0 else { return nil }
        return (Double(bytes) / Double(breakdown.totalReclaimableBytes)) * 100.0
    }
    
    private func mediaShare(bytes: Int64) -> Double {
        guard totalMediaBytes > 0 && bytes > 0 else { return 0.0 }
        return (Double(bytes) / Double(totalMediaBytes)) * 100.0
    }
    
    private func avgFileSize(bytes: Int64, count: Int) -> String {
        guard count > 0 && bytes > 0 else { return "0 B" }
        let avg = bytes / Int64(count)
        return ByteCountFormatter.string(fromByteCount: avg, countStyle: .file)
    }
}

// MARK: - Floating Circle Progress Ring Component

public struct FloatingStorageRing: View {
    public let breakdown: StorageBreakdown
    public let mode: StorageDisplayMode
    @Environment(\.colorScheme) private var colorScheme
    
    public init(breakdown: StorageBreakdown, mode: StorageDisplayMode) {
        self.breakdown = breakdown
        self.mode = mode
    }
    
    private var targetProgress: Double {
        switch mode {
        case .overview:
            return min(max(breakdown.usedPercentage, 0.03), 1.0)
        case .cleanable:
            let pct = breakdown.percentageOfFilledStorage(bytes: breakdown.totalReclaimableBytes) / 100.0
            return min(max(pct, 0.04), 1.0)
        case .breakdown:
            let mediaBytes = breakdown.largeVideosBytes + breakdown.similarPhotosBytes + breakdown.screenshotsBytes
            let used = max(Double(breakdown.usedDiskBytes), 1.0)
            return min(max(Double(mediaBytes) / used, 0.05), 1.0)
        }
    }
    
    private var centerPercentageText: String {
        switch mode {
        case .overview:
            return "\(Int(breakdown.usedPercentage * 100))%"
        case .cleanable:
            let pct = breakdown.percentageOfFilledStorage(bytes: breakdown.totalReclaimableBytes)
            if pct < 0.1 && pct > 0 {
                return "<0.1%"
            } else if pct < 10.0 {
                return String(format: "%.1f%%", pct)
            } else {
                return "\(Int(pct))%"
            }
        case .breakdown:
            let mediaBytes = breakdown.largeVideosBytes + breakdown.similarPhotosBytes + breakdown.screenshotsBytes
            let used = max(Double(breakdown.usedDiskBytes), 1.0)
            let pct = (Double(mediaBytes) / used) * 100.0
            if pct < 0.1 && pct > 0 {
                return "<0.1%"
            } else if pct < 10.0 {
                return String(format: "%.1f%%", pct)
            } else {
                return "\(Int(pct))%"
            }
        }
    }
    
    private var centerLabelText: String {
        switch mode {
        case .overview: return "Used"
        case .cleanable: return "Freeable"
        case .breakdown: return "Media"
        }
    }
    
    private var ringGradients: [Color] {
        switch mode {
        case .overview:
            return [
                Color(red: 0.15, green: 0.65, blue: 1.0),
                Color(red: 0.20, green: 0.45, blue: 0.98),
                Color(red: 0.50, green: 0.25, blue: 0.95)
            ]
        case .cleanable:
            return [
                Color(red: 1.0, green: 0.70, blue: 0.15),
                Color(red: 1.0, green: 0.45, blue: 0.15),
                Color(red: 1.0, green: 0.25, blue: 0.35)
            ]
        case .breakdown:
            return [
                Color.cyan,
                Color.blue,
                Color.purple
            ]
        }
    }
    
    public var body: some View {
        ZStack {
            // Background Glass Groove Track
            Circle()
                .stroke(
                    colorScheme == .dark
                        ? Color.white.opacity(0.08)
                        : Color(red: 0.15, green: 0.25, blue: 0.50).opacity(0.08),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 82, height: 82)
            
            // Active Liquid Arc (Single-pass hardware accelerated)
            Circle()
                .trim(from: 0.0, to: CGFloat(targetProgress))
                .stroke(
                    LinearGradient(
                        colors: ringGradients,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 9.5, lineCap: .round)
                )
                .frame(width: 82, height: 82)
                .rotationEffect(.degrees(-90))
                .shadow(color: ringGradients.first?.opacity(colorScheme == .dark ? 0.45 : 0.25) ?? Color.clear, radius: 6, x: 0, y: 2)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: targetProgress)
            
            // Center Pod
            VStack(spacing: 1) {
                Text(centerPercentageText)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .contentTransition(.numericText())
                
                Text(centerLabelText)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
        }
        .padding(6)
        .background(
            Circle()
                .fill(
                    colorScheme == .dark
                        ? Color.white.opacity(0.04)
                        : Color.white.opacity(0.40)
                )
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.25 : 0.6),
                                    Color.white.opacity(colorScheme == .dark ? 0.04 : 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                )
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.05), radius: 8, x: 0, y: 3)
        )
    }
}

// Backward-compatible alias
public typealias StorageSegmentBarView = StoragePartitionView
