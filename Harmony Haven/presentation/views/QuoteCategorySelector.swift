import SwiftUI

struct QuoteCategory: Identifiable {
    let id: Int
    let name: String
}

struct QuoteCategorySelector: View {
    @Binding var selectedCategoryId: Int
    let onCategorySelected: (Int) -> Void
    
    // Sample categories - in a real app, these would come from an API
    private let categories = [
        QuoteCategory(id: 21, name: "Motivation"),
        QuoteCategory(id: 22, name: "Love"),
        QuoteCategory(id: 23, name: "Success"),
        QuoteCategory(id: 24, name: "Wisdom"),
        QuoteCategory(id: 25, name: "Happiness")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle indicator
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 20)
            
            Text("Select Category")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.bottom, 20)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ForEach(categories) { category in
                    CategoryButton(
                        title: category.name,
                        isSelected: category.id == selectedCategoryId,
                        action: {
                            selectedCategoryId = category.id
                            onCategorySelected(category.id)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .padding(.bottom, 20)
        .background(Color(.systemBackground))
        .cornerRadius(20, corners: [.topLeft, .topRight])
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .cornerRadius(12)
        }
    }
}

// Extension to apply corner radius to specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
} 