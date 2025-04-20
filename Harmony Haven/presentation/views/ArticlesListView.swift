import SwiftUI

struct ArticlesListView: View {
    @StateObject private var articleViewModel = ArticleListViewModel()
    @State private var searchText: String = ""
    @EnvironmentObject private var navigationCoordinator: AppNavigationCoordinator
    
    // Filtered articles based on search text
    private var filteredArticles: [Article] {
        if searchText.isEmpty {
            return articleViewModel.articles
        } else {
            return articleViewModel.articles.filter { article in
                article.title.localizedCaseInsensitiveContains(searchText) ||
                article.contentPreview.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search articles", text: $searchText)
                    .font(.system(size: 16))
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Articles list
            ZStack {
                if articleViewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                } else if let error = articleViewModel.error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Could not load articles")
                            .font(.headline)
                        
                        Text(error.errorDescription)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Button(action: {
                            articleViewModel.refreshAllData()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Try Again")
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                } else if articleViewModel.articles.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "newspaper")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No articles found")
                            .font(.headline)
                        
                        Text("There are no articles available yet.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else if !searchText.isEmpty && filteredArticles.isEmpty {
                    // No search results
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No matching articles")
                            .font(.headline)
                        
                        Text("Try a different search term")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    List {
                        ForEach(filteredArticles, id: \.id) { article in
                            Button(action: {
                                navigationCoordinator.navigateTo(.articleDetail(article))
                            }) {
                                // Updated article layout: image on top (2:1), title and preview below
                                VStack(alignment: .leading, spacing: 8) {
                                    // Article image with 2:1 aspect ratio
                                    ZStack {
                                        if let imageURL = article.imageURL {
                                            AsyncImage(url: imageURL) { phase in
                                                switch phase {
                                                case .empty:
                                                    Rectangle()
                                                        .fill(Color.gray.opacity(0.2))
                                                        .overlay(
                                                            ProgressView()
                                                                .scaleEffect(0.7)
                                                        )
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                case .failure:
                                                    Rectangle()
                                                        .fill(Color.gray.opacity(0.2))
                                                        .overlay(
                                                            Image(systemName: "photo")
                                                                .foregroundColor(.gray)
                                                        )
                                                @unknown default:
                                                    EmptyView()
                                                }
                                            }
                                        } else {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.2))
                                                .overlay(
                                                    Image(systemName: "photo")
                                                        .foregroundColor(.gray)
                                                )
                                        }
                                    }
                                    .aspectRatio(2, contentMode: .fit) // 2:1 aspect ratio
                                    .cornerRadius(8)
                                    .clipped()
                                    
                                    // Article title
                                    Text(article.title)
                                        .font(.headline)
                                        .lineLimit(2)
                                    
                                    // Article content preview
                                    Text(article.contentPreview)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(3)
                                }
                                .padding(.vertical, 8)
                                .contentShape(Rectangle()) // Ensure the entire item is tappable
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        articleViewModel.refreshAllData()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("All Articles")
        .onAppear {
            articleViewModel.loadArticles()
        }
    }
} 