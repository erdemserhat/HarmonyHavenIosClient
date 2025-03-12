import SwiftUI
import AVKit

struct VerticalTabViewStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                UIScrollView.appearance().isPagingEnabled = true
                
                // Find and configure the scroll view for vertical scrolling
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let scrollView = window.subviews.first?.subviews.first?.subviews.first as? UIScrollView {
                    scrollView.bounces = false
                    scrollView.showsVerticalScrollIndicator = false
                    scrollView.showsHorizontalScrollIndicator = false
                    
                    // Configure for vertical scrolling
                    scrollView.contentSize = CGSize(
                        width: UIScreen.main.bounds.width,
                        height: UIScreen.main.bounds.height * CGFloat(3) // Adjust based on number of items
                    )
                    scrollView.isPagingEnabled = true
                }
            }
    }
}

struct QuotesView: View {
    @StateObject private var viewModel = QuotesViewModel()
    @State private var visibleQuoteIds = Set<Int>()
    @State private var activeVideoQuoteId: Int? = nil
    @State private var currentIndex: Int = 0
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                TabView(selection: $currentIndex) {
                    ForEach(Array(viewModel.quotes.enumerated()), id: \.element.id) { index, quote in
                        ZStack(alignment: .bottom) {
                            // Main Quote Content
                            QuoteCardView(quote: quote, onAppear: {
                                visibleQuoteIds.insert(quote.id)
                                if quote.isVideo {
                                    activeVideoQuoteId = quote.id
                                }
                                preloadNextVideo(currentQuote: quote)
                                viewModel.loadNextPageIfNeeded(currentQuote: quote)
                            })
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            
                            // Overlay Content
                            HStack(alignment: .bottom) {
                                // Left side: Quote info
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(quote.writer)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text(quote.content)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Right side: Action buttons
                                VStack(spacing: 20) {
                                    Button(action: {
                                        // Like action
                                    }) {
                                        VStack {
                                            Image(systemName: "heart.fill")
                                                .font(.system(size: 28))
                                            Text("23.4K")
                                                .font(.caption)
                                        }
                                    }
                                    
                                    Button(action: {
                                        // Comment action
                                    }) {
                                        VStack {
                                            Image(systemName: "message.fill")
                                                .font(.system(size: 28))
                                            Text("1.2K")
                                                .font(.caption)
                                        }
                                    }
                                    
                                    Button(action: {
                                        // Share action
                                    }) {
                                        VStack {
                                            Image(systemName: "square.and.arrow.up")
                                                .font(.system(size: 28))
                                            Text("Share")
                                                .font(.caption)
                                        }
                                    }
                                }
                                .foregroundColor(.white)
                                .padding(.trailing, 16)
                                .padding(.bottom, 120) // Increased bottom padding
                                .frame(maxHeight: .infinity, alignment: .bottom) // This will push the buttons to the bottom
                            }
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.clear, .black.opacity(0.5)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                        .tabViewStyle(PageTabViewStyle())
                        .tag(index)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .onAppear {
                            if quote.isVideo {
                                if activeVideoQuoteId != nil && activeVideoQuoteId != quote.id {
                                    VideoPlayerManager.shared.pause()
                                }
                                activeVideoQuoteId = quote.id
                            }
                        }
                        .onDisappear {
                            visibleQuoteIds.remove(quote.id)
                            if quote.isVideo && activeVideoQuoteId == quote.id {
                                VideoPlayerManager.shared.pause()
                                activeVideoQuoteId = nil
                            }
                        }
                    }
                    
                    if viewModel.isFetchingNextPage {
                        ProgressView()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color.black)
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onAppear {
                    setupVerticalScrolling()
                }
            }
            .navigationBarHidden(true)
            .ignoresSafeArea()
            .onDisappear {
                VideoPlayerManager.shared.cleanup()
                activeVideoQuoteId = nil
            }
        }
        .onAppear {
            if viewModel.quotes.isEmpty {
                viewModel.loadQuotes()
            }
            
            // Configure tab bar appearance for this view
            UITabBar.appearance().backgroundColor = .black
            UITabBar.appearance().barTintColor = .black
            UITabBar.appearance().isTranslucent = false
        }
        .onDisappear {
            // Reset tab bar appearance when leaving the view
            UITabBar.appearance().backgroundColor = nil
            UITabBar.appearance().barTintColor = nil
            UITabBar.appearance().isTranslucent = true
        }
        .preferredColorScheme(.dark)
    }
    
    private func setupVerticalScrolling() {
        UIScrollView.appearance().isPagingEnabled = true
        
        // Find and configure the UIScrollView for vertical paging
        guard let window = UIApplication.shared.windows.first,
              let scrollView = window.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView else {
            return
        }
        
        scrollView.bounces = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.decelerationRate = .fast
        
        // Configure for vertical scrolling
        scrollView.transform = CGAffineTransform(rotationAngle: .pi / 2)
        scrollView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.height, height: UIScreen.main.bounds.width)
    }
    
    private func preloadNextVideo(currentQuote: Quote) {
        if let currentIndex = viewModel.quotes.firstIndex(where: { $0.id == currentQuote.id }) {
            let nextIndex = currentIndex + 1
            if nextIndex < viewModel.quotes.count {
                let nextQuote = viewModel.quotes[nextIndex]
                if nextQuote.isVideo, let url = URL(string: nextQuote.mediaUrl) {
                    VideoPlayerManager.shared.preloadVideo(for: nextQuote.id, url: url)
                }
            }
        }
    }
}

// Extension to safely access array elements
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct QuotesView_Previews: PreviewProvider {
    static var previews: some View {
        QuotesView()
    }
} 
