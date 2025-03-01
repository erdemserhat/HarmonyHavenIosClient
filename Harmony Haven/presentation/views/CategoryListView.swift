import SwiftUI

struct CategoryListView: View {
    @ObservedObject var viewModel: CategoryListViewModel
    
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
                        viewModel.loadCategories()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
            } else if viewModel.categories.isEmpty {
                Text("No categories found")
                    .font(.title)
                    .foregroundColor(.gray)
            } else {
                List {
                    ForEach(viewModel.categories, id: \.id) { category in
                        NavigationLink(destination: ArticleListView(viewModel: ArticleListViewModel(), categoryId: category.id)) {
                            CategoryRow(category: category)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .onAppear {
            viewModel.loadCategories()
        }
        .navigationTitle("Categories")
    }
}

struct CategoryRow: View {
    let category: ArticleCategory
    
    var body: some View {
        HStack(spacing: 16) {
            if let imageURL = category.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Image(systemName: "folder")
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            } else {
                Image(systemName: "folder")
                    .foregroundColor(.gray)
                    .frame(width: 60, height: 60)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Text(category.name)
                .font(.headline)
        }
        .padding(.vertical, 8)
    }
} 