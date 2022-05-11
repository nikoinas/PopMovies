//
//  MovieModel.swift
//  PopMovies
//
//  Created by Niko on 09.04.22.
//

import Foundation


// MARK: - Model stuct - Movie
struct Movie: Decodable {
    // Nested Enum neede for direct JSON parsing
    enum CodingKeys: String, CodingKey {
        case id, title, overview
        case posterLink = "poster_path"
        case genres = "genre_ids"
        case releaseDate = "release_date"
    }
    
    // Properties
    var id: Int?
    var title: String?
    var posterLink: String?
    var overview: String?
    var genres: [Int]?
    var releaseDate: String?
}
