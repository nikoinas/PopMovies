//
//  MovieViewModel.swift
//  PopMovies
//
//  Created by Niko on 09.04.22.
//

import UIKit
import RealmSwift
import Alamofire
import SwiftyJSON

// MARK: ViewModel class
final class MovieViewModel: Object {
    // MARK: - Properties
    @objc dynamic var id = 0
    @objc dynamic var title = ""
    @objc dynamic var posterLink = ""
    @objc dynamic var overview = ""
    @objc dynamic var genresTogether = ""
    @objc dynamic var date = ""
    @objc dynamic var trailerLink = ""

    // MARK: - Initializers
    // Initializer not inherited from superclass and needed
    override init(){super.init()}
    
    // Initializer of our ViewModel class
    init(movie: Movie) {
        id = movie.id ?? 0
        title = movie.title ?? ""
        posterLink = movie.posterLink ?? ""
        overview = movie.overview ?? ""
        date = movie.releaseDate ?? ""
        
        // Get data as JSON-array and transform genres numbers to joined genres string
        if let genresArray = AppManager.getInstance.genresArray {
            let genresStringArray = movie.genres?.map { (id)->String in
                for genre in genresArray {
                    if id == genre["id"].int! {
                        return genre["name"].string!
                    }
                }
                return ""
            } ?? []
            genresTogether = genresStringArray.joined(separator: ", ")
        }
        super.init()
        // Request for constructing the trailer link
        if let id = movie.id {
            AF.request(Constants.trailer + "/\(id)/videos", parameters: ["api_key": Constants.key]).responseData { response in
                switch response.result {
                case .success:
                    // Returned data
                    let data = response.data!
                    // Parsed array
                    if let array = (try? JSON(data: data))?["results"].array{
                        for itemushka in array {
                            // Get first existed Youtube id for trailer link
                            if let key = itemushka["key"].string {
                                do {
                                    try AppManager.getInstance.realm.write {
                                        // Trailer link
                                        self.trailerLink = key
                                    }
                                }
                                catch{
                                    print("Error saving movie in database: \(error)")
                                }
                                break
                            }
                        }
                    }
                case .failure:
                    //
                    print("Request Failure")
                }
            }
        }
    }

    // MARK: override primaryKey to uniquely identify your notes how you want to
    override static func primaryKey() -> String? {
        return "id"
    }
}

