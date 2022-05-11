//
//  PopMoviesTests.swift
//  PopMoviesTests
//
//  Created by Niko on 09.04.22.
//

import XCTest
import RealmSwift
@testable import PopMovies


class PopMoviesTests: XCTestCase {
    
    let sut = AppManager.getInstance
    
    override func setUpWithError() throws {

        try super.setUpWithError()
        
        Realm.Configuration.defaultConfiguration.inMemoryIdentifier = self.name
        
        let realm = try! Realm()
        
        sut.realm = realm

    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: - Realm Database test
    func testRealmDatabase() throws {
        //let movieViewModel = movieViewModels[0]

        let movie = Movie(id: 675353, title: "Kukuris Bagi", posterLink: "2132vhe32r3v1er5rbhvrr.jpg", overview: "", genres: [28, 12, 80], releaseDate: "12.11.2015")

        let movieViewModel = MovieViewModel(movie: movie)

        sut.save(movieViewModel: movieViewModel)

        XCTAssertEqual(sut.getAllMovieModels().count, 1, "count should be 1")

    }
    
    // MARK: - Test for checking if genres aray exists
    func testGenresArrayExists() throws {
        //XCTAssertNotNil(AppManager.getInstance.genresArray, "Genres array doesn't exist!")

    }

    
    // MARK: - ViewModel test
    func testMovieViewModel() throws {
                
        let movie = Movie(id: 675353, title: "Kukuris Bagi", posterLink: "2132vhe32r3v1er5rbhvrr.jpg", overview: "", genres: [28, 12, 80], releaseDate: "12.11.2015")
        
        let movieViewModel = MovieViewModel(movie: movie)

        XCTAssertEqual(movieViewModel.id, movie.id)
        XCTAssertEqual(movieViewModel.title, movie.title)
        XCTAssertEqual(movieViewModel.posterLink, movie.posterLink)
        XCTAssertEqual(movieViewModel.overview, movie.overview)
        XCTAssertEqual(movieViewModel.date, movie.releaseDate)
        
        //XCTAssertEqual(movieViewModel.trailerLink, "YkZ1aAPApAc")
        //XCTAssertEqual(movieViewModel.genresTogether, "Action, Adventure, Crime")
    }
}
