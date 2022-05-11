//
//  DataStore.swift
//  PopMovies
//
//  Created by Niko on 21.04.22.
//print(Thread.isMainThread)

import Foundation
import UIKit
import Alamofire

class PosterLoadOperation: Operation {
    // 1
    var moviePoster: UIImage?
    var loadingCompleteHandler: ((UIImage, String) -> Void)?
  
    private let _id: Int
    private let _posterLink: String
    private let _title: String
    private let _forIndex: IndexPath
  
    // 2
    init(id: Int, posterLink: String, title: String, forIndex: IndexPath) {
        _id = id
        _posterLink = posterLink
        _title = title
        _forIndex = forIndex
    }
    
    // 3
    override func main() {
        // TODO: Work it!!
    
        // 1
        if isCancelled { return }
            
        // 2
        let defaults = UserDefaults.standard
        
        let dirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Movies")
        //
        if let url_1 = defaults.string(forKey: Constants.baseURL), let url_2 = defaults.string(forKey: Constants.size) {
            let url = url_1 + url_2 + _posterLink
            
            let queue = DispatchQueue(label: "org.themoviedb.api", qos: .background)
            
            AF.request(url).responseData(queue: queue) { [weak self] response in
                guard let self = self else { return }
                switch response.result {
                    case .success:
                    //
                    let data = response.data!
                    // Save image fileswhen connected
                    if self._forIndex.item < 40 {
                        if let writeURL = dirURL?.appendingPathComponent("\(self._id).jpg") {
                            // Write image to jpg file
                            do {
                                try data.write(to: writeURL)
                            }
                            catch {
                                print("Error saving jpg: \(error)")
                            }
                        }
                    }
                    let image = UIImage(data: data)
                    self.moviePoster = image
                    //
                    if let loadingCompleteHandler = self.loadingCompleteHandler {
                        
                        DispatchQueue.main.async {
                            loadingCompleteHandler(image!, self._title)
                        }
                    }
                    case .failure:
                    //
                    print("Request Failure")
                }
            }
        }
        //
        if isCancelled { return }

    }
}

