import SwiftUI
import Photos

public struct SwipeCleanView: View {
    @StateObject private var viewModel = SwipeCleanViewModel()
    @StateObject private var permissionService = PermissionService.shared
    @State private var dragOffset: CGSize = .zero
    @State private var isSwipingCard: Bool = false
    public let onCleanRequested: (CleanBatch) -> Void
    
    public init(onCleanRequested: @escaping (CleanBatch) -> Void) {
        self.onCleanRequested = onCleanRequested
    }
    
    public var body: some View {
        ZStack {
            AmbientGlassBackdrop()
            
            Group {
                if !permissionService.hasPhotosAccess {
                    permissionRequiredView
                } else if viewModel.isLoading && viewModel.deck.isEmpty {
                    loadingView
                } else {
                    mainDeckContent
                }
            }
        }
        .navigationTitle("Swipe to Clean")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !viewModel.trashedAssets.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if let batch = viewModel.prepareCleanBatch() {
                            onCleanRequested(batch)
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 12))
                            Text("Review (\(viewModel.trashedAssets.count))")
                                .font(.subheadline.weight(.bold))
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
        }
        .task {
            permissionService.checkCurrentStatuses()
            if !permissionService.hasPhotosAccess && permissionService.photoStatus == .notDetermined {
                let status = await permissionService.requestPhotosPermission()
                if (status == .authorized || status == .limited) && viewModel.deck.isEmpty {
                    viewModel.loadDeck()
                }
            } else if permissionService.hasPhotosAccess && viewModel.deck.isEmpty {
                viewModel.loadDeck()
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var permissionRequiredView: some View {
        PermissionNoticeView(
            title: "Photo Access Required",
            message: "Sweeply needs access to your photos to swipe and review storage.",
            isDenied: permissionService.photoStatus == .denied
        ) {
            if permissionService.photoStatus == .denied {
                permissionService.openSettings()
            } else {
                Task {
                    let status = await permissionService.requestPhotosPermission()
                    if status == .authorized || status == .limited {
                        viewModel.loadDeck()
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.blue)
            Text("Loading photos for Fast Deck...")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var mainDeckContent: some View {
        GeometryReader { geo in
            let availH = geo.size.height
            // Header ~56pt, action bar ~80pt, gaps ~40pt → ~54% for the card
            let cardH = availH * 0.54

            VStack(spacing: 0) {
                // Top Counter Bar
                counterHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                // Card Deck Stack
                ZStack {
                    if viewModel.deck.isEmpty {
                        allCaughtUpCard
                    } else {
                        // Peek card underneath
                        if viewModel.deck.count > 1 {
                            let nextAsset = viewModel.deck[1]
                            cardView(for: nextAsset, isTop: false)
                                .id(nextAsset.id)
                                .scaleEffect(0.94)
                                .offset(y: 10)
                                .opacity(0.65)
                        }

                        // Active top card
                        if let current = viewModel.currentAsset {
                            cardView(for: current, isTop: true)
                                .id(current.id)
                                .offset(x: dragOffset.width, y: dragOffset.height * 0.25)
                                .rotationEffect(.degrees(Double(dragOffset.width / 22.0)))
                                .gesture(
                                    DragGesture()
                                        .onChanged { gesture in
                                            guard !isSwipingCard else { return }
                                            dragOffset = gesture.translation
                                        }
                                        .onEnded { gesture in
                                            guard !isSwipingCard else { return }
                                            let translation = gesture.translation.width
                                            let velocity = gesture.predictedEndTranslation.width - gesture.translation.width

                                            if translation > 80 || velocity > 120 {
                                                performSwipe(direction: .right)
                                            } else if translation < -80 || velocity < -120 {
                                                performSwipe(direction: .left)
                                            } else {
                                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                                    dragOffset = .zero
                                                }
                                            }
                                        }
                                )
                        }
                    }
                }
                .frame(height: cardH)
                .padding(.horizontal, 16)

                Spacer(minLength: 12)

                // Bottom Action Controls
                actionButtonsBar
                    .padding(.bottom, 100)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private var counterHeader: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.green)
                Text("\(viewModel.keptAssets.count) Kept")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .liquidGlass(cornerRadius: 14, padding: 0)
            
            Spacer()
            
            HStack(spacing: 6) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.red)
                Text("\(viewModel.trashedAssets.count) To Clean (\(viewModel.formattedTrashedBytes))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .liquidGlass(cornerRadius: 14, padding: 0)
        }
    }
    
    // MARK: - Single Card View
    
    @ViewBuilder
    private func cardView(for asset: MediaAsset, isTop: Bool) -> some View {
        ZStack(alignment: .bottom) {
            // Photo Thumbnail
            ThumbnailImageView(
                asset: asset.phAsset,
                targetSize: CGSize(width: 800, height: 1000)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            
            // Stamp Overlays on Top Card
            if isTop {
                VStack {
                    HStack {
                        // KEEP STAMP
                        let keepOpacity = min(max(Double(dragOffset.width / 60.0), 0.0), 1.0)
                        if keepOpacity > 0 {
                            Text("KEEP")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundStyle(Color.green)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.green, lineWidth: 3.5)
                                )
                                .rotationEffect(.degrees(-16))
                                .opacity(keepOpacity)
                                .padding(.leading, 24)
                                .padding(.top, 24)
                        }
                        
                        Spacer()
                        
                        // CLEAN STAMP
                        let cleanOpacity = min(max(Double(-dragOffset.width / 60.0), 0.0), 1.0)
                        if cleanOpacity > 0 {
                            Text("CLEAN")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundStyle(Color.red)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.red, lineWidth: 3.5)
                                )
                                .rotationEffect(.degrees(16))
                                .opacity(cleanOpacity)
                                .padding(.trailing, 24)
                                .padding(.top, 24)
                        }
                    }
                    Spacer()
                }
            }
            
            // Bottom Info Vignette
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(asset.formattedDate)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.85))
                    Text(asset.formattedSize)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.white)
                }
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "hand.draw.fill")
                        .font(.caption2)
                    Text("Swipe")
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(Color.white.opacity(0.75))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.white.opacity(0.20)))
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.30), radius: 12, x: 0, y: 6)
    }
    
    // MARK: - All Caught Up Card
    
    @ViewBuilder
    private var allCaughtUpCard: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "sparkles")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(Color.blue)
            }
            
            Text("All Caught Up!")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.primary)
            
            Text("You've reviewed all photos in this deck.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            if !viewModel.trashedAssets.isEmpty {
                Button {
                    if let batch = viewModel.prepareCleanBatch() {
                        onCleanRequested(batch)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash.fill")
                        Text("Review & Clean \(viewModel.trashedAssets.count) Items")
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.red.opacity(0.35), radius: 8, y: 4)
                }
                .buttonStyle(SmoothCardButtonStyle())
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
            
            Button("Load More Photos") {
                viewModel.loadDeck()
            }
            .font(.subheadline.weight(.semibold))
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .liquidGlass(cornerRadius: 24, padding: 24)
    }
    
    // MARK: - Bottom Action Buttons
    
    @ViewBuilder
    private var actionButtonsBar: some View {
        HStack(spacing: 28) {
            // Undo
            Button {
                HapticService.shared.selection()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    viewModel.undo()
                }
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(viewModel.keptAssets.isEmpty && viewModel.trashedAssets.isEmpty ? Color.secondary.opacity(0.3) : Color.yellow)
                    .frame(width: 52, height: 52)
                    .background(
                        Circle()
                            .fill(Color.yellow.opacity(viewModel.keptAssets.isEmpty && viewModel.trashedAssets.isEmpty ? 0.05 : 0.15))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.yellow.opacity(viewModel.keptAssets.isEmpty && viewModel.trashedAssets.isEmpty ? 0.1 : 0.4), lineWidth: 1)
                    )
            }
            .buttonStyle(SmoothCardButtonStyle())
            .disabled(viewModel.keptAssets.isEmpty && viewModel.trashedAssets.isEmpty)
            
            // Clean (Left)
            Button {
                performSwipe(direction: .left)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(viewModel.deck.isEmpty ? Color.secondary.opacity(0.3) : Color.red)
                    .frame(width: 66, height: 66)
                    .background(
                        Circle()
                            .fill(Color.red.opacity(viewModel.deck.isEmpty ? 0.05 : 0.15))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.red.opacity(viewModel.deck.isEmpty ? 0.1 : 0.45), lineWidth: 1.2)
                    )
                    .shadow(color: Color.red.opacity(viewModel.deck.isEmpty ? 0 : 0.25), radius: 8, y: 3)
            }
            .buttonStyle(SmoothCardButtonStyle())
            .disabled(viewModel.deck.isEmpty || isSwipingCard)
            
            // Keep (Right)
            Button {
                performSwipe(direction: .right)
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(viewModel.deck.isEmpty ? Color.secondary.opacity(0.3) : Color.green)
                    .frame(width: 66, height: 66)
                    .background(
                        Circle()
                            .fill(Color.green.opacity(viewModel.deck.isEmpty ? 0.05 : 0.15))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.green.opacity(viewModel.deck.isEmpty ? 0.1 : 0.45), lineWidth: 1.2)
                    )
                    .shadow(color: Color.green.opacity(viewModel.deck.isEmpty ? 0 : 0.25), radius: 8, y: 3)
            }
            .buttonStyle(SmoothCardButtonStyle())
            .disabled(viewModel.deck.isEmpty || isSwipingCard)
        }
    }
    
    // MARK: - Swipe Action Execution
    
    private enum SwipeDirection {
        case left
        case right
    }
    
    private func performSwipe(direction: SwipeDirection) {
        guard !viewModel.deck.isEmpty, !isSwipingCard else { return }
        isSwipingCard = true
        HapticService.shared.impact(direction == .left ? .heavy : .medium)
        
        let targetX: CGFloat = direction == .right ? 600 : -600
        
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            dragOffset = CGSize(width: targetX, height: 20)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            if direction == .right {
                viewModel.swipeRight()
            } else {
                viewModel.swipeLeft()
            }
            
            // Reset dragOffset synchronously without animation so next card starts centered
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                dragOffset = .zero
                isSwipingCard = false
            }
        }
    }
}
