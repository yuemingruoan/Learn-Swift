import Foundation

struct TodoDTO: Decodable {
    let userId: Int
    let id: Int
    let title: String
    let completed: Bool
}

struct CreateStudyRecordRequestDTO: Encodable {
    let chapter: Int
    let title: String
    let durationMinutes: Int
}

struct StudyRecordResponseDTO: Decodable {
    let id: Int
    let chapter: Int
    let title: String
    let durationMinutes: Int
    let status: String
}
