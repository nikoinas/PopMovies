//
//  CatalogCollectionViewCell.swift
//  PopMovies
//
//  Created by Niko on 09.04.22.
//

import UIKit
import Alamofire

// MARK: - View class - CatalogCollectionViewCell
final class CatalogCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    @IBOutlet weak var movieImageView: UIImageView!
    @IBOutlet weak var movieTitleLabel: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    
    // Counter for image saving on the device for using during offline
    //static var imageCounter = 0
    
//    var movieViewModel: MovieViewModel? {
//        didSet {
//            if movieViewModel != nil {
//                
//                movieTitleLabel.text = movieViewModel?.title
//                let id = movieViewModel!.id
//
//                let manager = AppManager.getInstance
//
//                let dirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Movies")
//                
//                if movieViewModel!.posterLink != "" {
//                    // 2 different scenario depending on the internet connectivity
//                    if manager.isConnected {
//                        //
//                        manager.getPosterImage(posterID: movieViewModel!.posterLink) { response in
//    
//                            switch response.result {
//                                case .success:
//                                //
//                                let data = response.data!
//                                // Save image fileswhen connected
//                                if CatalogCollectionViewCell.imageCounter <  40 {
//                                    CatalogCollectionViewCell.imageCounter += 1
//                                    if let writeURL = dirURL?.appendingPathComponent("\(id)") {
//                                        // Write image to jpg file
//                                        do {
//                                            try data.write(to: writeURL)
//                                        }
//                                        catch {
//                                            print("Error saving jpg: \(error)")
//                                        }
//                                    }
//                                }
//                                DispatchQueue.main.async {
//                                    self.movieImageView.image = nil
//                                    self.movieImageView.image = UIImage(data: data)
//                                }
//                                case .failure:
//                                //
//                                print("Request Failure")
//                            }
//                        }
//                    }
//                    else {
//                        // Reading image files from device when disconnected
//                        if let readPath = dirURL?.appendingPathComponent("\(id)"), let data = try? Data(contentsOf: readPath) {
//                            //
//                            DispatchQueue.main.async {
//                                self.movieImageView.image = nil
//                                self.movieImageView.image = UIImage(data: data)
//                            }
//                        }
//                        else {
//                            print("File doesn't exist!")
//                        }
//                    }
//                }
//                else {
//                    movieImageView.image = UIImage(named: "noposter.png")
//                }
//                movieImageView.layer.cornerRadius = 15.0
//                movieImageView.layer.borderWidth = 1
//            }
//        }
//    }
    
    
    override func prepareForReuse() {
        DispatchQueue.main.async {
            self.displayPoster(nil, nil)
        }
    }

    
    func updateAppearanceFor(_ image: UIImage?, _ title: String?, animated: Bool) {
        
        DispatchQueue.main.async {
            if animated {
                UIView.animate(withDuration: 0.5) {
                    self.displayPoster(image, title)
                }
            }
            else {
                self.displayPoster(image, title)
            }
        }
    }

    
    private func displayPoster(_ image: UIImage?, _ title: String?) {
        if let image = image {
            movieTitleLabel.text = title
            movieImageView.image = image
          
            movieTitleLabel.alpha = 1
            movieImageView.alpha = 1
          
            loadingIndicator.alpha = 0
            loadingIndicator.stopAnimating()
            //backgroundColor = #colorLiteral(red: 0.9338415265, green: 0.9338632822, blue: 0.9338515401, alpha: 1)
            movieImageView.layer.cornerRadius = 15.0
            movieImageView.layer.borderWidth = 1
        }
        else {
            movieTitleLabel.alpha = 0
            movieImageView.alpha = 0
            
            loadingIndicator.alpha = 1
            loadingIndicator.startAnimating()
            //backgroundColor = #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1)
            movieImageView.layer.cornerRadius = 15.0
            movieImageView.layer.borderWidth = 1

        }
    }

    
}
