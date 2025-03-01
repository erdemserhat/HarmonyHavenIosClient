import SwiftUI
import MarkdownUI

struct ArticleDetailView: View {
    let article: Article
    @State private var categoryName: String = ""
    private let categoryService = ArticleCategoryService()
    
    var body: some View {
        // Use GeometryReader to get screen dimensions
        GeometryReader { geometry in
            ScrollView {
                // Fixed width container with explicit margins
                VStack(alignment: .leading, spacing: 0) {
                    // Image with 2:1 aspect ratio (twice as wide as tall)
                    let imageWidth = max(geometry.size.width - 32, 0)
                    let imageHeight = max(imageWidth / 2, 0) // 2:1 aspect ratio
                    
                    if let imageURL = article.imageURL {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .overlay(
                                        ProgressView()
                                            .scaleEffect(1.5)
                                    )
                                    .frame(width: imageWidth, height: imageHeight)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: imageWidth, height: imageHeight)
                                    .clipped()
                            case .failure:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.largeTitle)
                                            .foregroundColor(.gray)
                                    )
                                    .frame(width: imageWidth, height: imageHeight)
                            @unknown default:
                                EmptyView()
                                    .frame(width: imageWidth, height: imageHeight)
                            }
                        }
                        .cornerRadius(8)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                            .frame(width: imageWidth, height: imageHeight)
                            .cornerRadius(8)
                    }
                    
                    Spacer(minLength: 20)
                    
                    // Content with fixed width
                    VStack(alignment: .leading, spacing: 20) {
                        // Category badge with name
                        Text(categoryName.isEmpty ? "Category" : categoryName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(16)
                        
                        // Title
                        Text(article.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Publish date
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.gray)
                            Text(article.formattedPublishDate)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Content preview (highlighted)
                        Text(article.contentPreview)
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(16)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Main content
                        Markdown(article.content)
                            .markdownTheme(.basic)
                            .padding(.vertical, 8)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer(minLength: 40)
                    }
                    .frame(width: max(geometry.size.width - 32, 0))
                }
                .frame(width: max(geometry.size.width, 0))
                .padding(.top, 16)
                .padding(.bottom, 24)
                // Center the content horizontally
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(width: max(geometry.size.width, 0))
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(article.title)
                        .font(.headline)
                        .lineLimit(1)
                    if !categoryName.isEmpty {
                        Text(categoryName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onAppear {
            // Fetch category name when view appears
            fetchCategoryName()
        }
    }
    
    // Fetch category name based on article's categoryId
    private func fetchCategoryName() {
        categoryService.fetchCategories { result in
            switch result {
            case .success(let categories):
                // Find the category that matches the article's categoryId
                if let category = categories.first(where: { $0.id == article.categoryId }) {
                    self.categoryName = category.name
                } else {
                    self.categoryName = "Category #\(article.categoryId)"
                }
            case .failure:
                self.categoryName = "Category #\(article.categoryId)"
            }
        }
    }
}
