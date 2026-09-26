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

    // MARK: - Body

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
        // Title already set by MainTabView's NavigationStack — don't duplicate
        .toolbar {
            if !viewModel.trashedAssets.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if let batch = viewModel.prepareCleanBatch() {
                            onCleanRequested(batch)
                            viewModel.clearAfterClean()
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

    // MARK: - Permission / Loading

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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.blue)
            Text("Loading photos…")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Main Deck Layout

    @ViewBuilder
    private var mainDeckContent: some View {
        VStack(spacing: 0) {

            // ── Stats bar ──────────────────────────────────────────────────
            counterHeader
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 12)

            // ── Card window — floating, 470 pt ────────────────────────────
            ZStack {
                if viewModel.deck.isEmpty {
                    allCaughtUpCard
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Back card (peek)
                    if viewModel.deck.count > 1 {
                        let next = viewModel.deck[1]
                        cardView(for: next, isTop: false)
                            .id(next.id)
                            .scaleEffect(0.93)
                            .offset(y: 8)
                            .opacity(0.55)
                    }

                    // Top (draggable) card
                    if let current = viewModel.currentAsset {
                        cardView(for: current, isTop: true)
                            .id(current.id)
                            .offset(x: dragOffset.width, y: dragOffset.height * 0.18)
                            .rotationEffect(.degrees(Double(dragOffset.width / 26.0)))
                            .gesture(cardDragGesture)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 470)
            .padding(.horizontal, 16)
            // ── Floating elevation — three shadow layers ───────────────────
            .shadow(color: Color.black.opacity(0.32), radius: 24, x: 0, y: 14)
            .shadow(color: Color.black.opacity(0.14), radius: 8,  x: 0, y: 4)
            .shadow(color: Color.black.opacity(0.06), radius: 2,  x: 0, y: 1)

            Spacer(minLength: 0)

            // ── Action buttons ─────────────────────────────────────────────
            actionButtonsBar
                .padding(.top, 16)
                // 84 pt dock height + 20 pt margin + extra safety = 110
                .padding(.bottom, 110)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Drag Gesture

    private var cardDragGesture: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { g in
                guard !isSwipingCard else { return }
                dragOffset = g.translation
            }
            .onEnded { g in
                guard !isSwipingCard else { return }
                let dx = g.translation.width
                let vx = g.predictedEndTranslation.width - g.translation.width
                if dx > 80 || vx > 120 {
                    performSwipe(direction: .right)
                } else if dx < -80 || vx < -120 {
                    performSwipe(direction: .left)
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        dragOffset = .zero
                    }
                }
            }
    }

    // MARK: - Counter Header

    @ViewBuilder
    private var counterHeader: some View {
        HStack {
            Label("\(viewModel.keptAssets.count) Kept", systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .liquidGlass(cornerRadius: 14, padding: 0)

            Spacer()

            Label(
                "\(viewModel.trashedAssets.count) To Clean  \(viewModel.formattedTrashedBytes)",
                systemImage: "trash.fill"
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.red)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .liquidGlass(cornerRadius: 14, padding: 0)
        }
    }

    // MARK: - Single Card

    @ViewBuilder
    private func cardView(for asset: MediaAsset, isTop: Bool) -> some View {
        ZStack(alignment: .bottom) {
            // ── Letterbox / pillarbox background ──────────────────────────
            Color(white: 0.07)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // ── Photo — always fully visible, letterboxed if needed ───────
            ThumbnailImageView(
                asset: asset.phAsset,
                targetSize: CGSize(width: 700, height: 900),
                contentMode: .fit
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // ── KEEP / CLEAN stamps ───────────────────────────────────────
            if isTop {
                stampOverlay
            }

            // ── Bottom vignette ───────────────────────────────────────────
            infoVignette(asset: asset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(borderColor(isTop: isTop), lineWidth: isTop ? 2.0 : 1.2)
        )
        // Per-card shadow removed — floating shadow is on the container ZStack
    }

    private func borderColor(isTop: Bool) -> Color {
        guard isTop else { return Color.white.opacity(0.18) }
        if dragOffset.width > 20 {
            return Color.green.opacity(min(0.5 + Double(dragOffset.width) / 200, 1.0))
        } else if dragOffset.width < -20 {
            return Color.red.opacity(min(0.5 + Double(-dragOffset.width) / 200, 1.0))
        }
        return Color.white.opacity(0.32)
    }

    @ViewBuilder
    private var stampOverlay: some View {
        VStack {
            HStack {
                let keepOp = min(max(Double(dragOffset.width / 55.0), 0), 1.0)
                if keepOp > 0 {
                    Text("KEEP")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.green, lineWidth: 3))
                        .rotationEffect(.degrees(-16))
                        .opacity(keepOp)
                        .padding(.leading, 20).padding(.top, 20)
                }
                Spacer()
                let cleanOp = min(max(Double(-dragOffset.width / 55.0), 0), 1.0)
                if cleanOp > 0 {
                    Text("CLEAN")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.red, lineWidth: 3))
                        .rotationEffect(.degrees(16))
                        .opacity(cleanOp)
                        .padding(.trailing, 20).padding(.top, 20)
                }
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func infoVignette(asset: MediaAsset) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(asset.formattedDate)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.82))
                Text(asset.formattedSize)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "hand.draw.fill").font(.caption2)
                Text("Swipe").font(.caption2.weight(.bold))
            }
            .foregroundStyle(Color.white.opacity(0.75))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Capsule().fill(Color.white.opacity(0.18)))
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.80)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - All Caught Up

    @ViewBuilder
    private var allCaughtUpCard: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().fill(Color.blue.opacity(0.15)).frame(width: 80, height: 80)
                Image(systemName: "sparkles")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(Color.blue)
            }
            Text("All Caught Up!")
                .font(.title2.weight(.bold))
            Text("You've reviewed all photos in this deck.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if !viewModel.trashedAssets.isEmpty {
                Button {
                    if let batch = viewModel.prepareCleanBatch() {
                        onCleanRequested(batch)
                        viewModel.clearAfterClean()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash.fill")
                        Text("Review & Clean \(viewModel.trashedAssets.count) Items")
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.red.opacity(0.35), radius: 8, y: 4)
                }
                .buttonStyle(SmoothCardButtonStyle())
                .padding(.horizontal, 20)
            }

            Button("Load More Photos") { viewModel.loadDeck() }
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.bordered)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .liquidGlass(cornerRadius: 24, padding: 0)
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtonsBar: some View {
        HStack(spacing: 24) {
            // Undo
            circleButton(
                icon: "arrow.uturn.backward",
                size: 50, iconSize: 18,
                color: .yellow,
                disabled: viewModel.keptAssets.isEmpty && viewModel.trashedAssets.isEmpty
            ) {
                HapticService.shared.selection()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { viewModel.undo() }
            }

            // Delete / Clean
            circleButton(
                icon: "xmark",
                size: 64, iconSize: 25,
                color: .red,
                disabled: viewModel.deck.isEmpty || isSwipingCard
            ) {
                performSwipe(direction: .left)
            }

            // Keep
            circleButton(
                icon: "checkmark",
                size: 64, iconSize: 25,
                color: .green,
                disabled: viewModel.deck.isEmpty || isSwipingCard
            ) {
                performSwipe(direction: .right)
            }
        }
    }

    @ViewBuilder
    private func circleButton(
        icon: String, size: CGFloat, iconSize: CGFloat,
        color: Color, disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .bold))
                .foregroundStyle(disabled ? color.opacity(0.25) : color)
                .frame(width: size, height: size)
                .background(Circle().fill(color.opacity(disabled ? 0.05 : 0.14)))
                .overlay(Circle().stroke(color.opacity(disabled ? 0.10 : 0.45), lineWidth: 1.2))
                .shadow(color: color.opacity(disabled ? 0 : 0.28), radius: 8, y: 3)
        }
        .buttonStyle(SmoothCardButtonStyle())
        .disabled(disabled)
    }

    // MARK: - Swipe Execution

    private enum SwipeDirection { case left, right }

    private func performSwipe(direction: SwipeDirection) {
        guard !viewModel.deck.isEmpty, !isSwipingCard else { return }
        isSwipingCard = true
        HapticService.shared.impact(direction == .left ? .heavy : .medium)

        let targetX: CGFloat = direction == .right ? 500 : -500

        withAnimation(.spring(response: 0.26, dampingFraction: 0.80)) {
            dragOffset = CGSize(width: targetX, height: 16)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            if direction == .right { viewModel.swipeRight() } else { viewModel.swipeLeft() }
            var tx = Transaction()
            tx.disablesAnimations = true
            withTransaction(tx) {
                dragOffset = .zero
                isSwipingCard = false
            }
        }
    }
}
