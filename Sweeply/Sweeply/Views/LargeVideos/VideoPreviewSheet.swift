import SwiftUI
import AVKit
import Photos

public struct VideoPreviewSheet: View {
    public let asset: MediaAsset
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer? = nil
    @State private var isLoading = true
    
    public init(asset: MediaAsset) {
        self.asset = asset
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let player = player {
                    VideoPlayer(player: player)
                        .ignoresSafeArea()
                        .onAppear {
                            player.play()
                        }
                        .onDisappear {
                            player.pause()
                        }
                } else {
                    Text("Could not load video preview")
                        .foregroundStyle(.white)
                }
            }
            .navigationTitle(asset.formattedSize)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .task {
                if let avAsset = await VideoService.shared.fetchAVAsset(for: asset.phAsset) {
                    let playerItem = AVPlayerItem(asset: avAsset)
                    self.player = AVPlayer(playerItem: playerItem)
                }
                self.isLoading = false
            }
        }
    }
}
