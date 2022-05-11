//
//  PlayerViewController.swift
//  PopMovies
//
//  Created by Niko on 13.04.22.
//

import UIKit
import YoutubeKit

final class PlayerViewController: UIViewController {

    // MARK: - Properties
    @IBOutlet weak var ytPlayer: UIView!
    var player: YTSwiftyPlayer!
    var trailerLink: String!
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // hide back button
        navigationItem.setHidesBackButton(true, animated: false)
        
        // Create a new player
        let player = YTSwiftyPlayer(frame: CGRect(x: 0, y: 0, width: ytPlayer.bounds.size.width, height: ytPlayer.bounds.size.height),
                                    playerVars: [.playsInline(false), .videoID(trailerLink)])

        // Arrange our Player
        player.isOpaque = false
        player.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        player.autoplay = true
        player.loadPlayer()
        // Set delegate for detect callback information from the player.
        player.delegate = self
        // Player added to superview
        ytPlayer.addSubview(player)
    }
    
    //MARK: - Done button click
    @IBAction func doneClick(_ sender: UIBarButtonItem) {
        // MARK - Dismiss controller with player when click on Done button
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Extension of PlayerViewController for adopting YTSwiftyPlayerDelegate
extension PlayerViewController: YTSwiftyPlayerDelegate {
    func player(_ player: YTSwiftyPlayer, didChangeState state: YTSwiftyPlayerState) {
        // MARK - Dismiss controller with player when playback ends
        if state == .ended {
            player.stopVideo()
            navigationController?.popViewController(animated: true)
        }
    }
}
