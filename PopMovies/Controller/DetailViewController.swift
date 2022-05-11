//
//  DetailViewController.swift
//  PopMovies
//
//  Created by Niko on 09.04.22.
//

import UIKit
import AVKit
import Alamofire
import YoutubeKit

final class DetailViewController: UIViewController {
    
    // MARK: - Properties
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var genresLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var overviewTextView: UITextView!

    var movieViewModel: MovieViewModel!
    var posterImage: UIImage!
    
    private var playerController: AVPlayerViewController!
    private let manager = AppManager.getInstance
    private var _trailerLink = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        // Getting the needed data from MoviewViewModel object
        titleLabel.text = movieViewModel.title
        dateLabel.text = movieViewModel.date
        overviewTextView.text = movieViewModel.overview
        genresLabel.text = movieViewModel.genresTogether
        _trailerLink = movieViewModel.trailerLink
                    
        if movieViewModel!.posterLink != "" {
            if manager.isConnected {
                manager.getPosterImage(posterID: movieViewModel!.posterLink) { response in
                    switch response.result {
                        case .success:
                        //
                        let data = response.data!
                            
                        DispatchQueue.main.async {
                            self.posterImageView.image = UIImage(data: data)
                        }
                        case .failure:
                        //
                        print("Request Failure")
                    }
                }
            }
            else {
                // Reading image files from device when disconnected
                if let readPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Movies").appendingPathComponent("\(movieViewModel.id).jpg"), let data = try? Data(contentsOf: readPath) {
                    //
                    DispatchQueue.main.async {
                        self.posterImageView.image = UIImage(data: data)
                    }
                }
                else {
                    print("File doesn't exist!")
                }
            }
        }
        else {
            posterImageView.image = UIImage(named: "noposter.png")
        }
    }
            
    // MARK - Player method
    @IBAction func playerClick(_ sender: UIButton) {
        // Show the player screen according to connectivity
        if manager.isConnected {
            if let vc = storyboard?.instantiateViewController(withIdentifier: "YTController") as? PlayerViewController {
                vc.trailerLink = _trailerLink
                show(vc, sender: nil)
            }
        }
        else {
            manager.alertAndSettings(controller: self, message: Constants.alertVideoMessage)
        }
    }
}
