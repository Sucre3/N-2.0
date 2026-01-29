import Foundation

struct BibleBook: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let chapters: Int

    init(name: String, chapters: Int) {
        self.id = name
        self.name = name
        self.chapters = chapters
    }
}

struct BibleData {
    static let oldTestament: [BibleBook] = [
        .init(name: "Geneza", chapters: 50),
        .init(name: "Exodul", chapters: 40),
        .init(name: "Leviticul", chapters: 27),
        .init(name: "Numeri", chapters: 36),
        .init(name: "Deuteronom", chapters: 34),
        .init(name: "Iosua", chapters: 24),
        .init(name: "Judecători", chapters: 21),
        .init(name: "Rut", chapters: 4),
        .init(name: "1 Samuel", chapters: 31),
        .init(name: "2 Samuel", chapters: 24),
        .init(name: "1 Împărați", chapters: 22),
        .init(name: "2 Împărați", chapters: 25),
        .init(name: "1 Cronici", chapters: 29),
        .init(name: "2 Cronici", chapters: 36),
        .init(name: "Ezra", chapters: 10),
        .init(name: "Neemia", chapters: 13),
        .init(name: "Estera", chapters: 10),
        .init(name: "Iov", chapters: 42),
        .init(name: "Psalmi", chapters: 150),
        .init(name: "Proverbe", chapters: 31),
        .init(name: "Eclesiastul", chapters: 12),
        .init(name: "Cântarea Cântărilor", chapters: 8),
        .init(name: "Isaia", chapters: 66),
        .init(name: "Ieremia", chapters: 52),
        .init(name: "Plângerile lui Ieremia", chapters: 5),
        .init(name: "Ezechiel", chapters: 48),
        .init(name: "Daniel", chapters: 12),
        .init(name: "Osea", chapters: 14),
        .init(name: "Ioel", chapters: 3),
        .init(name: "Amos", chapters: 9),
        .init(name: "Obadia", chapters: 1),
        .init(name: "Iona", chapters: 4),
        .init(name: "Mica", chapters: 7),
        .init(name: "Naum", chapters: 3),
        .init(name: "Habacuc", chapters: 3),
        .init(name: "Țefania", chapters: 3),
        .init(name: "Hagai", chapters: 2),
        .init(name: "Zaharia", chapters: 14),
        .init(name: "Maleahi", chapters: 4)
    ]

    static let newTestament: [BibleBook] = [
        .init(name: "Matei", chapters: 28),
        .init(name: "Marcu", chapters: 16),
        .init(name: "Luca", chapters: 24),
        .init(name: "Ioan", chapters: 21),
        .init(name: "Faptele Apostolilor", chapters: 28),
        .init(name: "Romani", chapters: 16),
        .init(name: "1 Corinteni", chapters: 16),
        .init(name: "2 Corinteni", chapters: 13),
        .init(name: "Galateni", chapters: 6),
        .init(name: "Efeseni", chapters: 6),
        .init(name: "Filipeni", chapters: 4),
        .init(name: "Coloseni", chapters: 4),
        .init(name: "1 Tesaloniceni", chapters: 5),
        .init(name: "2 Tesaloniceni", chapters: 3),
        .init(name: "1 Timotei", chapters: 6),
        .init(name: "2 Timotei", chapters: 4),
        .init(name: "Tit", chapters: 3),
        .init(name: "Filimon", chapters: 1),
        .init(name: "Evrei", chapters: 13),
        .init(name: "Iacov", chapters: 5),
        .init(name: "1 Petru", chapters: 5),
        .init(name: "2 Petru", chapters: 3),
        .init(name: "1 Ioan", chapters: 5),
        .init(name: "2 Ioan", chapters: 1),
        .init(name: "3 Ioan", chapters: 1),
        .init(name: "Iuda", chapters: 1),
        .init(name: "Apocalipsa", chapters: 22)
    ]

    static var allBooks: [BibleBook] { oldTestament + newTestament }
}
