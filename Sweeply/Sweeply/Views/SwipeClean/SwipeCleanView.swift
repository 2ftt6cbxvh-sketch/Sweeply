import SwiftUI
import Photos

public struct SwipeCleanView: View {
    @StateObject private var viewModel = SwipeCleanViewModel()
    @StateObject private var permissionService = PermissionService.shared
    @State private var dragOffset: CGSize = .zero
    public let onCleanRequested: (CleanBatch) -> Void
    
    public init(onCleanRequested: @escaping (CleanBatch) -> Void) {
        self.onCleanRequested = onCleanRequested
    }
    
    public var body: some View {
        ZStack {
            AmbientGlassBackdrop()
            
            VStack(spacing: 16) {
                // Top Counter
                HStack(spacing: 20) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("\(viewModel.keptAssets.count) Kept")
                            .font(.subheadline.weight(.semibold))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Image(systemName: "trash.fill")
                            .foregroundStyle(.red)
                        Text("\(viewModel.trashedAssets.count) To Clean (\(viewModel.formattedTrashedBytes))")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                // Card Deck Stack
                ZStack {
                    if viewModel.deck.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 50))
                                .foregroundStyle(.blue)
                            
                            Text("All Caught Up!")
                                .font(.title3.weight(.bold))
                            
                            Text("You've reviewed all photos in this deck.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            if !viewModel.trashedAssets.isEmpty {
                                Button {
                                    if let batch = viewModel.prepareCleanBatch() {
                                        onCleanRequested(batch)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "trash.fill")
                                        Text("Review & Clean \(viewModel.trashedAssets.count) Photos")
                                    }
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.red)
                                    .cornerRadius(14)
                                }
                                .padding(.top, 8)
                            }
                            
                            Button("Load More Photos") {
                                viewModel.loadDeck()
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(20)
                        .padding(20)
                    } else {
                        // Background Card peek
                        if viewModel.deck.count > 1 {
                            let nextAsset = viewModel.deck[1]
                            ThumbnailImageView(asset: nextAsset.phAsset, targetSize: CGSize(width: 400, height: 500))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .cornerRadius(20)
                                .scaleEffect(0.95)
                                .offset(y: 10)
                                .opacity(0.6)
                                .padding(20)
                        }
                        
                        // Active Top Card
                        if let current = viewModel.currentAsset {
                            ZStack(alignment: .topTrailing) {
                                ThumbnailImageView(asset: current.phAsset, targetSize: CGSize(width: 500, height: 600))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .cornerRadius(20)
                                    .clipped()
                                
                                // Drag Stamp Overlays
                                HStack {
                                    if dragOffset.width > 30 {
                                        Text("KEEP")
                                            .font(.title.weight(.heavy))
                                            .foregroundStyle(.green)
                                            .padding(10)
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green, lineWidth: 3))
                                            .rotationEffect(.degrees(-15))
                                            .padding(20)
                                    }
                                    
                                    Spacer()
                                    
                                    if dragOffset.width < -30 {
                                        Text("CLEAN")
                                            .font(.title.weight(.heavy))
                                            .foregroundStyle(.red)
                                            .padding(10)
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red, lineWidth: 3))
                                            .rotationEffect(.degrees(15))
                                            .padding(20)
                                    }
                                }
                                
                                // Bottom Photo Info Card
                                VStack {
                                    Spacer()
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(current.formattedDate)
                                                .font(.caption)
                                                .foregroundStyle(.white.opacity(0.8))
                                            Text(current.formattedSize)
                                                .font(.headline)
                                                .foregroundStyle(.white)
                                        }
                                        Spacer()
                                    }
                                    .padding(14)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.clear, Color.black.opacity(0.75)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .cornerRadius(20)
                                }
                            }
                            .padding(20)
                            .offset(x: dragOffset.width, y: dragOffset.height * 0.2)
                            .rotationEffect(.degrees(Double(dragOffset.width / 18)))
                            .gesture(
                                DragGesture()
                                    .onChanged { gesture in
                                        dragOffset = gesture.translation
                                    }
                                    .onEnded { gesture in
                                        if gesture.translation.width > 120 {
                                            withAnimation(.spring()) {
                                                dragOffset = CGSize(width: 500, height: 0)
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                                viewModel.swipeRight()
                                                dragOffset = .zero
                                            }
                                        } else if gesture.translation.width < -120 {
                                            withAnimation(.spring()) {
                                                dragOffset = CGSize(width: -500, height: 0)
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                                viewModel.swipeLeft()
                                                dragOffset = .zero
                                            }
                                        } else {
                                            withAnimation(.spring()) {
                                                dragOffset = .zero
                                            }
                                        }
                                    }
                            )
                        }
                    }
                }
                .frame(maxHeight: 520)
                
                // Bottom Button Bar
                HStack(spacing: 24) {
                    // Undo
                    Button {
                        viewModel.undo()
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.yellow)
                            .frame(width: 52, height: 52)
                            .background(Color.yellow.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .disabled(viewModel.keptAssets.isEmpty && viewModel.trashedAssets.isEmpty)
                    
                    // Swipe Left (Clean)
                    Button {
                        withAnimation(.spring()) {
                            viewModel.swipeLeft()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.red)
                            .frame(width: 64, height: 64)
                            .background(Color.red.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .disabled(viewModel.deck.isEmpty)
                    
                    // Swipe Right (Keep)
                    Button {
                        withAnimation(.spring()) {
                            viewModel.swipeRight()
                        }
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.green)
                            .frame(width: 64, height: 64)
                            .background(Color.green.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .disabled(viewModel.deck.isEmpty)
                }
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Swipe to Clean")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !viewModel.trashedAssets.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Review (\(viewModel.trashedAssets.count))") {
                        if let batch = viewModel.prepareCleanBatch() {
                            onCleanRequested(batch)
                        }
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.red)
                }
            }
        }
        .onAppear {
            if permissionService.hasPhotosAccess && viewModel.deck.isEmpty {
                viewModel.loadDeck()
            }
        }
    }
}
