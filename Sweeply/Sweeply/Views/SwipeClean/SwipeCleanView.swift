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

    // MARK: - Permission
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
                    if status == .authorized || status == .limited { viewModel.loadDeck() }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.2).tint(.blue)
            Text("Loading photos…").font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Main Deck Layout
    @ViewBuilder
    private var mainDeckContent: some View {
        VStack(spacing: 0) {
            counterHeader
                .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 12)

            ZStack {
                if viewModel.deck.isEmpty {
                    allCaughtUpCard.frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    if viewModel.deck.count > 1 {
                        let next = viewModel.deck[1]
                        cardView(for: next, isTop: false)
                            .id(next.id).scaleEffect(0.93).offset(y: 8).opacity(0.55)
                    }
                    if let current = viewModel.currentAsset {
                        cardView(for: current, isTop: true)
                            .id(current.id)
                            .offset(x: dragOffset.width, y: dragOffset.height * 0.18)
                            .rotationEffect(.degrees(Double(dragOffset.width / 26.0)))
                            .gesture(cardDragGesture)
                    }
                }
            }
            .frame(maxWidth: .infinity).frame(height: 470)
            .padding(.horizontal, 16)
            .shadow(color: Color.black.opacity(0.32), radius: 24, x: 0, y: 14)
            .shadow(color: Color.black.opacity(0.14), radius: 8,  x: 0, y: 4)
            .shadow(color: Color.black.opacity(0.06), radius: 2,  x: 0, y: 1)

            if !viewModel.deck.isEmpty {
                swipeInstructionStrip.padding(.top, 14)
            }

            Spacer(minLength: 8)

            deleteButton.padding(.horizontal, 20).padding(.bottom, 110)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Swipe Instruction Strip
    @ViewBuilder
    private var swipeInstructionStrip: some View {
        HStack(spacing: 0) {
            HStack(spacing: 5) {
                Image(systemName: "arrow.left").font(.system(size: 12, weight: .bold))
                Text("Delete").font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(dragOffset.width < -20 ? Color.red : Color.secondary)
            .opacity(dragOffset.width > 40 ? 0.25 : 1.0)
            .animation(.easeOut(duration: 0.12), value: dragOffset.width)

            Spacer()

            if abs(dragOffset.width) < 30 {
                Text("Swipe to decide")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.secondary.opacity(0.65))
                    .transition(.opacity.animation(.easeOut(duration: 0.12)))
            }

            Spacer()

            HStack(spacing: 5) {
                Text("Keep").font(.system(size: 13, weight: .semibold))
                Image(systemName: "arrow.right").font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(dragOffset.width > 20 ? Color.green : Color.secondary)
            .opacity(dragOffset.width < -40 ? 0.25 : 1.0)
            .animation(.easeOut(duration: 0.12), value: dragOffset.width)
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Delete Button (center, always accessible)
    @ViewBuilder
    private var deleteButton: some View {
        if viewModel.trashedAssets.isEmpty {
            HStack(spacing: 8) {
                Image(systemName: "trash").font(.system(size: 15, weight: .semibold))
                Text("No photos queued for deletion").font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(Color.secondary.opacity(0.45))
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.secondary.opacity(0.07)))
        } else {
            Button {
                HapticService.shared.impact(.heavy)
                if let batch = viewModel.prepareCleanBatch() {
                    onCleanRequested(batch)
                    viewModel.clearAfterClean()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "trash.fill").font(.system(size: 16, weight: .bold))
                    Text("Delete \(viewModel.trashedAssets.count) Photo\(viewModel.trashedAssets.count == 1 ? "" : "s")  ·  \(viewModel.formattedTrashedBytes)")
                        .font(.headline.weight(.bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.red))
                .shadow(color: Color.red.opacity(0.40), radius: 12, x: 0, y: 5)
            }
            .buttonStyle(SmoothCardButtonStyle())
        }
    }

    // MARK: - Drag Gesture
    private var cardDragGesture: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { g in guard !isSwipingCard else { return }; dragOffset = g.translation }
            .onEnded { g in
                guard !isSwipingCard else { return }
                let dx = g.translation.width
                let vx = g.predictedEndTranslation.width - g.translation.width
                if dx > 80 || vx > 120 { performSwipe(direction: .right) }
                else if dx < -80 || vx < -120 { performSwipe(direction: .left) }
                else { withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { dragOffset = .zero } }
            }
    }

    // MARK: - Counter Header
    @ViewBuilder
    private var counterHeader: some View {
        HStack {
            Label("\(viewModel.keptAssets.count) Kept", systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold)).foregroundStyle(.green)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .liquidGlass(cornerRadius: 14, padding: 0)

            Spacer()

            if !(viewModel.keptAssets.isEmpty && viewModel.trashedAssets.isEmpty) {
                Button {
                    HapticService.shared.selection()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { viewModel.undo() }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.uturn.backward").font(.system(size: 12, weight: .bold))
                        Text("Undo").font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .liquidGlass(cornerRadius: 14, padding: 0)
                }
                .buttonStyle(SmoothCardButtonStyle())
            }
        }
    }

    // MARK: - Single Card
    @ViewBuilder
    private func cardView(for asset: MediaAsset, isTop: Bool) -> some View {
        ZStack(alignment: .bottom) {
            Color(white: 0.07).frame(maxWidth: .infinity, maxHeight: .infinity)
            ThumbnailImageView(asset: asset.phAsset, targetSize: CGSize(width: 700, height: 900), contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if isTop { stampOverlay }
            infoVignette(asset: asset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
            .stroke(borderColor(isTop: isTop), lineWidth: isTop ? 2.0 : 1.2))
    }

    private func borderColor(isTop: Bool) -> Color {
        guard isTop else { return Color.white.opacity(0.18) }
        if dragOffset.width > 20 { return Color.green.opacity(min(0.5 + Double(dragOffset.width) / 200, 1.0)) }
        else if dragOffset.width < -20 { return Color.red.opacity(min(0.5 + Double(-dragOffset.width) / 200, 1.0)) }
        return Color.white.opacity(0.32)
    }

    @ViewBuilder
    private var stampOverlay: some View {
        VStack {
            HStack {
                let keepOp = min(max(Double(dragOffset.width / 55.0), 0), 1.0)
                if keepOp > 0 {
                    Text("KEEP")
                        .font(.system(size: 30, weight: .black, design: .rounded)).foregroundStyle(.green)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.green, lineWidth: 3))
                        .rotationEffect(.degrees(-16)).opacity(keepOp)
                        .padding(.leading, 20).padding(.top, 20)
                }
                Spacer()
                let deleteOp = min(max(Double(-dragOffset.width / 55.0), 0), 1.0)
                if deleteOp > 0 {
                    Text("DELETE")
                        .font(.system(size: 30, weight: .black, design: .rounded)).foregroundStyle(.red)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.red, lineWidth: 3))
                        .rotationEffect(.degrees(16)).opacity(deleteOp)
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
                Text(asset.formattedDate).font(.caption.weight(.medium)).foregroundStyle(Color.white.opacity(0.82))
                Text(asset.formattedSize).font(.headline.weight(.bold)).foregroundStyle(.white)
            }
            Spacer()
        }
        .padding(14)
        .background(LinearGradient(colors: [.clear, Color.black.opacity(0.80)], startPoint: .top, endPoint: .bottom))
    }

    // MARK: - All Caught Up
    @ViewBuilder
    private var allCaughtUpCard: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().fill(Color.blue.opacity(0.15)).frame(width: 80, height: 80)
                Image(systemName: "sparkles").font(.system(size: 38, weight: .bold)).foregroundStyle(Color.blue)
            }
            Text("All Caught Up!").font(.title2.weight(.bold))
            Text("You've reviewed all photos in this deck.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button("Load More Photos") { viewModel.loadDeck() }
                .font(.subheadline.weight(.semibold)).buttonStyle(.bordered)
        }
        .padding(24).frame(maxWidth: .infinity, maxHeight: .infinity)
        .liquidGlass(cornerRadius: 24, padding: 0)
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
            var tx = Transaction(); tx.disablesAnimations = true
            withTransaction(tx) { dragOffset = .zero; isSwipingCard = false }
        }
    }
}
