import SwiftUI

struct ArticleListView: View {
    @ObservedObject var viewModel: ArticleListViewModel
    @EnvironmentObject private var navigationCoordinator: AppNavigationCoordinator
    var categoryId: Int?
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if let error = viewModel.error {
                VStack {
                    Text("Error")
                        .font(.title)
                        .foregroundColor(.red)
                    
                    Text(error.errorDescription)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("Retry") {
                        if let categoryId = categoryId {
                            viewModel.loadArticlesByCategory(categoryId: categoryId)
                        } else {
                            viewModel.loadArticles()
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
            } else if viewModel.articles.isEmpty {
                Text("No articles found")
                    .font(.title)
                    .foregroundColor(.gray)
            } else {
                List {
                    ForEach(viewModel.articles, id: \.id) { article in
                        Button(action: {
                            navigationCoordinator.navigateTo(.articleDetail(article))
                        }) {
                            ArticleRow(article: article)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .onAppear {
            if let categoryId = categoryId {
                viewModel.loadArticlesByCategory(categoryId: categoryId)
            } else {
                viewModel.loadArticles()
            }
        }
        .navigationTitle(categoryId != nil ? "Articles" : "All Articles")
    }
}

struct ArticleRow: View {
    let article: Article
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Article image with consistent sizing
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
            .frame(width: 80, height: 80)
            .cornerRadius(8)
            .clipped()
            
            // Article content with proper spacing
            VStack(alignment: .leading, spacing: 6) {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(article.contentPreview)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(article.formattedPublishDate)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("Category #\(article.categoryId)")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle()) // Ensure the entire row is tappable
    }
} 