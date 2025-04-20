import SwiftUI
import AVKit
import AVFoundation

// Static manager to ensure only one video plays at a time
class VideoPlayerManager {
    static let shared = VideoPlayerManager()
    private var currentPlayer: AVPlayer?
    private var isAudioSessionConfigured = false
    private var currentVideoId: Int?
    private var preloadedPlayers: [Int: AVPlayer] = [:]
    
    private init() {
        configureAudioSession()
    }
    
    func configureAudioSession() {
        if !isAudioSessionConfigured {
            do {
                // Use mixWithOthers to allow background music to continue
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
                try AVAudioSession.sharedInstance().setActive(true)
                isAudioSessionConfigured = true
                print("Audio session configured successfully")
            } catch {
                print("Failed to set audio session category: \(error)")
            }
        }
    }
    
    func play(player: AVPlayer, videoId: Int) {
        // If this is already the current video, just resume playback
        if currentVideoId == videoId && currentPlayer == player {
            currentPlayer?.play()
            return
        }
        
        // Stop any currently playing video
        currentPlayer?.pause()
        
        // Set and play the new video
        currentPlayer = player
        currentVideoId = videoId
        
        // Ensure audio session is configured before playing
        configureAudioSession()
        
        // Play with a slight delay to ensure proper setup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            player.play()
        }
    }
    
    func pause() {
        currentPlayer?.pause()
    }
    
    func pauseIfPlaying(videoId: Int) {
        if currentVideoId == videoId {
            currentPlayer?.pause()
        }
    }
    
    func preloadVideo(for videoId: Int, url: URL) {
        // Don't preload if already preloaded
        if preloadedPlayers[videoId] != nil {
            return
        }
        
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        
        // Store in preloaded players dictionary
        preloadedPlayers[videoId] = player
        
        // Limit preloaded players to 3 to avoid memory issues
        if preloadedPlayers.count > 3 {
            let oldestKey = preloadedPlayers.keys.sorted().first
            if let key = oldestKey, key != videoId {
                preloadedPlayers.removeValue(forKey: key)
            }
        }
    }
    
    func getPreloadedPlayer(for videoId: Int) -> AVPlayer? {
        return preloadedPlayers[videoId]
    }
    
    func cleanup() {
        currentPlayer?.pause()
        currentPlayer = nil
        currentVideoId = nil
        
        // Clear all preloaded players
        for (_, player) in preloadedPlayers {
            player.pause()
        }
        preloadedPlayers.removeAll()
        
        // Deactivate audio session when cleaning up
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            isAudioSessionConfigured = false
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
}

struct QuoteCardView: View {
    let quote: Quote
    let onAppear: () -> Void
    
    @State private var isImageLoaded = false
    @State private var player: AVPlayer?
    @State private var isVideoReady = false
    @State private var playerItemObservation: NSKeyValueObservation?
    @State private var isVisible = false
    @State private var loadError: Error?
    @State private var loadingProgress: Float = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
                
                // Media content (image or video)
                if quote.isVideo {
                    if let player = player, isVideoReady {
                        ZStack {
                            Color.black
                            
                            VideoPlayer(player: player)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .edgesIgnoringSafeArea(.all)
                                .onAppear {
                                    if isVisible {
                                        // Use the manager to play this video
                                        VideoPlayerManager.shared.play(player: player, videoId: quote.id)
                                    }
                                }
                                .onDisappear {
                                    // Pause when this view disappears
                                    player.pause()
                                }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                    } else if loadError != nil {
                        // Show error state
                        VStack {
                            Image(systemName: "video.slash")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("Video failed to load")
                                .foregroundColor(.white)
                                .padding(.top, 8)
                            
                            Button(action: {
                                // Retry loading the video
                                loadError = nil
                                loadVideo()
                            }) {
                                Text("Retry")
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                            .padding(.top, 12)
                        }
                    } else {
                        // Enhanced loading state
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            if loadingProgress > 0 {
                                Text("\(Int(loadingProgress * 100))%")
                                    .foregroundColor(.white)
                                    .padding(.top, 8)
                            } else {
                                Text("Loading video...")
                                    .foregroundColor(.white)
                                    .padding(.top, 8)
                            }
                        }
                    }
                } else {
                    // Image
                    AsyncImage(url: URL(string: quote.mediaUrl)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                                .onAppear {
                                    isImageLoaded = true
                                }
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                
                // Quote text overlay
                VStack {
                    Spacer()
                    
                    Text(quote.content)
                        .font(.system(size: 24, weight: .semibold, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                        .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                isVisible = true
                onAppear()
                
                // Load video if needed
                if quote.isVideo, player == nil {
                    // Check if there's a preloaded player
                    if let preloadedPlayer = VideoPlayerManager.shared.getPreloadedPlayer(for: quote.id) {
                        player = preloadedPlayer
                        isVideoReady = true
                        if isVisible {
                            VideoPlayerManager.shared.play(player: preloadedPlayer, videoId: quote.id)
                        }
                    } else {
                        loadVideo()
                    }
                } else if quote.isVideo && isVideoReady && player != nil {
                    // If video is already loaded and ready, play it
                    VideoPlayerManager.shared.play(player: player!, videoId: quote.id)
                }
            }
            .onDisappear {
                isVisible = false
                
                // Clean up video player
                if quote.isVideo {
                    // Just pause the video but don't unload it to prevent flickering when scrolling
                    VideoPlayerManager.shared.pauseIfPlaying(videoId: quote.id)
                }
            }
        }
    }
    
    private func loadVideo() {
        guard let url = URL(string: quote.mediaUrl) else {
            loadError = NSError(domain: "QuoteCardView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            return
        }
        
        // Create an asset and item
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        // Add loading progress tracking
        let loadingStatusToken = asset.loadValuesAsynchronously(forKeys: ["playable"]) {
            DispatchQueue.main.async {
                var error: NSError? = nil
                let status = asset.statusOfValue(forKey: "playable", error: &error)
                
                if status == .failed {
                    self.loadError = error
                }
            }
        }
        
        // Create the player
        let newPlayer = AVPlayer(playerItem: playerItem)
        
        // Set initial volume
        newPlayer.volume = 1.0
        
        // Observe the status of the player item
        playerItemObservation = playerItem.observe(\.status, options: [.new, .old]) { item, _ in
            DispatchQueue.main.async {
                if item.status == .readyToPlay {
                    self.isVideoReady = true
                    self.loadingProgress = 1.0
                    
                    // If the view is visible, start playing
                    if self.isVisible {
                        VideoPlayerManager.shared.play(player: newPlayer, videoId: self.quote.id)
                    }
                } else if item.status == .failed {
                    print("Video failed to load: \(String(describing: item.error))")
                    self.loadError = item.error
                }
            }
        }
        
        // Add loading progress observation
        let progressObserver = playerItem.observe(\.loadedTimeRanges, options: [.new]) { item, _ in
            guard let timeRange = item.loadedTimeRanges.first?.timeRangeValue else { return }
            let duration = CMTimeGetSeconds(asset.duration)
            let loadedDuration = CMTimeGetSeconds(timeRange.duration)
            let progress = Float(loadedDuration / duration)
            
            DispatchQueue.main.async {
                self.loadingProgress = progress
            }
        }
        
        // Add notification for when playback ends
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            // Loop the video by seeking back to start
            newPlayer.seek(to: CMTime.zero)
            newPlayer.play()
        }
        
        // Store the player
        player = newPlayer
    }
    
    private func cleanupPlayer() {
        // Remove notification observer
        if let player = player, let playerItem = player.currentItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        }
        
        player?.pause()
        playerItemObservation?.invalidate()
        playerItemObservation = nil
        player = nil
        isVideoReady = false
        loadError = nil
        loadingProgress = 0
    }
} 
