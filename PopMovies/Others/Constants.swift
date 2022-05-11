//
//  Constants.swift
//  PopMovies
//
//  Created by Niko on 09.04.22.
//  დამთავრებული ამ ეტაპზე

//MARK: - Constants in App
struct Constants {

    // Popular movies url
    static let popular = "https://api.themoviedb.org/3/movie/popular"
        
    //  Api-Key
    static let key = "03a9dfd3c42397a31ca7ef7c0d4529fb"
    
    // Configuration url
    static let configuration = "https://api.themoviedb.org/3/configuration"
    
    // Genres url
    static let genres = "https://api.themoviedb.org/3/genre/movie/list"
    
    // Trailer url
    static let trailer = "https://api.themoviedb.org/3/movie"
    
    // Alert
    static let alertTitle = "Connectivity Problems"
    static let alertMessage = "Go to Settings or stay offline!"
    static let alertVideoMessage = "You cannot watch the trailer! Go to Settings or stay offline!"
    
    // BaseUrl
    static let baseURL = "BaseUrl"
    // Size
    static let size = "Size"
}
