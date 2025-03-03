import XCTest
@testable import Harmony_Haven

final class QuoteDTOTests: XCTestCase {
    
    func testDecodingArrayResponse() throws {
        // Given
        let jsonString = """
        [
            {
                "id": 1,
                "quote": "Test quote 1",
                "writer": "Test writer 1",
                "imageUrl": "https://example.com/image1.jpg",
                "quoteCategory": 21,
                "isLiked": false
            },
            {
                "id": 2,
                "quote": "Test quote 2",
                "imageUrl": "https://example.com/image2.jpg",
                "quoteCategory": 21,
                "isLiked": true
            }
        ]
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let response = try JSONDecoder().decode(QuotesResponse.self, from: jsonData)
        
        // Then
        XCTAssertEqual(response.quotes.count, 2)
        XCTAssertEqual(response.totalCount, 2)
        XCTAssertEqual(response.currentPage, 1)
        XCTAssertEqual(response.totalPages, 1)
        
        // Verify first quote
        XCTAssertEqual(response.quotes[0].id, 1)
        XCTAssertEqual(response.quotes[0].quote, "Test quote 1")
        XCTAssertEqual(response.quotes[0].writer, "Test writer 1")
        XCTAssertEqual(response.quotes[0].imageUrl, "https://example.com/image1.jpg")
        XCTAssertEqual(response.quotes[0].quoteCategory, 21)
        XCTAssertFalse(response.quotes[0].isLiked)
        
        // Verify second quote (with missing writer)
        XCTAssertEqual(response.quotes[1].id, 2)
        XCTAssertEqual(response.quotes[1].quote, "Test quote 2")
        XCTAssertNil(response.quotes[1].writer)
        XCTAssertEqual(response.quotes[1].imageUrl, "https://example.com/image2.jpg")
        XCTAssertEqual(response.quotes[1].quoteCategory, 21)
        XCTAssertTrue(response.quotes[1].isLiked)
    }
    
    func testDecodingObjectResponse() throws {
        // Given
        let jsonString = """
        {
            "quotes": [
                {
                    "id": 1,
                    "quote": "Test quote 1",
                    "writer": "Test writer 1",
                    "imageUrl": "https://example.com/image1.jpg",
                    "quoteCategory": 21,
                    "isLiked": false
                }
            ],
            "totalCount": 100,
            "currentPage": 2,
            "totalPages": 10
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let response = try JSONDecoder().decode(QuotesResponse.self, from: jsonData)
        
        // Then
        XCTAssertEqual(response.quotes.count, 1)
        XCTAssertEqual(response.totalCount, 100)
        XCTAssertEqual(response.currentPage, 2)
        XCTAssertEqual(response.totalPages, 10)
        
        // Verify quote
        XCTAssertEqual(response.quotes[0].id, 1)
        XCTAssertEqual(response.quotes[0].quote, "Test quote 1")
        XCTAssertEqual(response.quotes[0].writer, "Test writer 1")
    }
    
    func testDecodingObjectResponseWithAlternativeKeys() throws {
        // Given
        let jsonString = """
        {
            "data": [
                {
                    "id": 1,
                    "quote": "Test quote 1",
                    "writer": "Test writer 1",
                    "imageUrl": "https://example.com/image1.jpg",
                    "quoteCategory": 21,
                    "isLiked": false
                }
            ],
            "total": 100,
            "page": 2,
            "pages": 10
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let response = try JSONDecoder().decode(QuotesResponse.self, from: jsonData)
        
        // Then
        XCTAssertEqual(response.quotes.count, 1)
        XCTAssertEqual(response.totalCount, 100)
        XCTAssertEqual(response.currentPage, 2)
        XCTAssertEqual(response.totalPages, 10)
        
        // Verify quote
        XCTAssertEqual(response.quotes[0].id, 1)
        XCTAssertEqual(response.quotes[0].quote, "Test quote 1")
        XCTAssertEqual(response.quotes[0].writer, "Test writer 1")
    }
} 