//
//  Globals&Constants.swift
//  PopMovies
//
//  Created by Niko on 09.04.22.
//

import Foundation
import Alamofire
import SwiftyJSON
import RealmSwift
import Connectivity

// MARK: - Singleton class for managing most of application needs
final class AppManager: NSObject {

    // MARK: - Nested type, Enum for error notification
    enum AppManagerError: Error {
        case movieDownloadError
    }
    
    // MARK: - Properties
    
    // Realm database entry
    var realm: Realm
    
    // MARK - Device connectivity check
    var isConnected: Bool {
        let connectivity = Connectivity()
        return (connectivity.isConnectedViaWiFiWithoutInternet || connectivity.isConnectedViaCellularWithoutInternet)
    }
    
    // MARK: - InactivityFlag for detecting when app is inactive
    var inactivityFlag = false
        
    //
    lazy var imageDictionary: Dictionary<Int, UIImage> = [:]
    lazy var dataRequestDictionary: Dictionary<Int, DataRequest> = [:]
    
    // Genres JSON Array
    lazy var genresArray: [JSON]? = {
        let genresFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Genres.json")
        //
        if let path = genresFilePath, let data = try? Data(contentsOf: path) {
            return try? JSON(data: data).array
        }
        return nil
    }()
    
    // MARK: - Singleton creation
    static let getInstance = AppManager()
    // Initializer preventing that singleton is only one
    private override init() {
        realm = try! Realm()
        super.init()
    }
    
    // MARK: - URL updating methods
    
    // For updating base url and image size for image url creation
    func updatingUrlAndSize() {
        if isConnected {
            AF.request(Constants.configuration, parameters: ["api_key": Constants.key]).responseData { response in
                switch response.result {
                case .success:
                    //
                    let data = response.data!
                    //
                    if let json = try? JSON(data: data){
                        
                        let defaults = UserDefaults.standard
                        
                        defaults.set(json["images"]["secure_base_url"].string, forKey: "BaseUrl")
                        
                        defaults.set(json["images"]["backdrop_sizes"][0].string, forKey: "Size")
                    }
                case .failure:
                    //
                    print("Request Failure")
                }
            }
        }
    }
    
    // For Genres data updating
    func updatingGenres() {
        // Update only when connected
        if isConnected {
            let fileManager = FileManager.default
            
            AF.request(Constants.genres, parameters: ["api_key": Constants.key]).responseData { response in
                
                switch response.result {
                case .success:
                    //
                    var data = response.data!
                    if let json = (try? JSON(data: data))?["genres"] {
                        do {
                            data = try json.rawData()
                            if let writeURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Genres.json") {
                                let temporaryURL = writeURL
                                do {
                                    // Remove file
                                    try? fileManager.removeItem(at: temporaryURL)
                                    
                                    // MARK - Write json to file
                                    try data.write(to: writeURL)
                                }
                                catch {
                                    print("Error removing/writing file: \(error)")
                                }
                            }
                        }
                        catch {
                            print("Error encoding/saving item array: \(error)")
                        }
                    }
                case .failure:
                    //
                    print("Request Failure")
                }
            }
        }
    }

    // For cleaning "Movies" directory
    func cleanDirectory() {
        if isConnected {
            let fileManager = FileManager.default
            let filePath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            if let nestedFolderURL = filePath?.appendingPathComponent("Movies"){
                // Check if the directory, "Movies", exists and create if not
                if !fileManager.fileExists(atPath: nestedFolderURL.relativePath) {
                    do {
                        //Create directory here
                        try fileManager.createDirectory(at: nestedFolderURL, withIntermediateDirectories: false, attributes: nil)
                    }
                    catch {
                        print("Error creating folder: \(error)")
                    }
                }
                else {
                    // if it exists, clean it
                    do {
                        let fileURLs = try fileManager.contentsOfDirectory(at: nestedFolderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                        for fileURL in fileURLs where fileURL.pathExtension == "jpg" {
                            try FileManager.default.removeItem(at: fileURL)
                        }
                    }
                    catch {
                        print(error)
                    }
                }
            }
        }
    }

    // For getting poster image
    func getPosterImage(posterID: String, handler: @escaping (AFDataResponse<Data>) -> Void) {
        let defaults = UserDefaults.standard
        if let url_1 = defaults.string(forKey: Constants.baseURL), let url_2 = defaults.string(forKey: Constants.size) {
            let url = url_1 + url_2 + posterID

            let queue = DispatchQueue(label: "org.themoviedb.api", qos: .background, attributes: .concurrent)

            AF.request(url).responseData(queue: queue,  completionHandler: handler)
        }
    }
    
    // MARK: Model manipulated methods
    // Pull movie catalog info
    func pullCatalog(page: Int, with handler: @escaping (Array<Movie>?, Error?)->Void) {
        // Request and hendling of the returned json
        let queue = DispatchQueue(label: "org.themoviedb", qos: .background)
        AF.request(Constants.popular, parameters: ["api_key": Constants.key, "page":"\(page)"]).responseData(queue: queue) { response in
            switch response.result {
            case .success:
                // returned data
                var data = response.data!
                //
                if let json = (try? JSON(data: data))?["results"] {
                    do {
                        data = try json.rawData()
                        // Serialize json to array of our model objects
                        let parsedData = try JSONDecoder().decode([Movie].self, from: data)
                        // Apply our handler
                        handler(parsedData, nil)
                    }
                    catch {
                        print("Error encoding/saving item array: \(error)")
                    }
                }
            case .failure:
                //
                print("Request Failure")
                // Apply our handler
                handler(nil, AppManagerError.movieDownloadError)
            }
        }
    }
    
    // For ViewModel saving in Realm database
    func save(movieViewModel: MovieViewModel){
        // save only if Primary key (i.e. id is different)
        let existingMovie = realm.object(ofType: MovieViewModel.self, forPrimaryKey: movieViewModel.id)

        if existingMovie == nil {
            do {
                try self.realm.write {
                    self.realm.add(movieViewModel)
                }
            }
            catch{
                print("Error saving movie in database: \(error)")
            }
        }
    }

    // For reading database
    func getAllMovieModels() -> Results<MovieViewModel> {
        return realm.objects(MovieViewModel.self)
    }
    
    // For alert making
    func alertAndSettings(controller: UIViewController, message: String) {
        
        let alertController = UIAlertController (title: Constants.alertTitle, message: message, preferredStyle: .alert)

        let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
            
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsUrl) {
                                
                UIApplication.shared.open(settingsUrl, completionHandler: nil)
            }
        }
        alertController.addAction(settingsAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alertController.addAction(cancelAction)

        controller.present(alertController, animated: true, completion: nil)
    }
}
