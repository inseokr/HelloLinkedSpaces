import Foundation

struct PhotoMetadata: Codable, Identifiable {
    let id: UUID
    let photoIdentifier: String
    let tags: [String]
    let analyzedDate: Date
    
    init(photoIdentifier: String, tags: [String]) {
        self.id = UUID()
        self.photoIdentifier = photoIdentifier
        self.tags = tags
        self.analyzedDate = Date()
    }
} 