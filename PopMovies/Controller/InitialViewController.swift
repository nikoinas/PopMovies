//
//  ViewController.swift
//  PopMovies
//
//  Created by Niko on 09.04.22.
//

import UIKit
import Alamofire
import SwiftyJSON
import RealmSwift

protocol PopMovies {
    
}

// MARK: - Initial controller class
class InitialViewController: UIViewController {    
    
    // MARK: - Properties
    @IBOutlet weak var searchTextBar: UISearchBar!
    
    @IBOutlet weak var catalogCollectionView: UICollectionView!
    
    var firstConnectionImageView: UIImageView?
    
    private var isLoading = true
    
    // View model properties
    private var movieViewModels: Results<MovieViewModel>?
    
    private var movieViewModelsSlice: Slice<Results<MovieViewModel>>?
    
    private var movieModelsArray: Array<MovieViewModel>? {
            manager.isConnected ? movieViewModels?.toArray() : movieViewModelsSlice?.toArray()
    }

    // For device orientation and type
    private var deviceOrientation = UIDeviceOrientation.unknown
    private let deviceType = UIDevice.current.userInterfaceIdiom
    
    // Manager
    private let manager = AppManager.getInstance
    
    // For search activation
    private var searching = false
    
    // Page counter
    private var pageCounter = 1
    
    // Manage operation queue
    private let loadingQueue = OperationQueue()
    private var posterLoadingOperations: [IndexPath: PosterLoadOperation] = [:]
    
    // MARK: - Methods
    // MARK: Standard methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // First some updates here
        // Update json file for base_url and image size
        manager.updatingUrlAndSize()
        // Update json file for ganres data
        manager.updatingGenres()
        // Clean directory "Movies"
        manager.cleanDirectory()

        
        
        // Configuration at starting point
        configureViewWithCatalog()
        // Download data
        runAtStart()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !manager.isConnected {
            // Check if first entry
            if !UserDefaults.standard.bool(forKey: "NotFirstTime"){
                let image = UIImage(named: "frstconn.png")
                firstConnectionImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height))
                firstConnectionImageView?.image = image
                view.addSubview(firstConnectionImageView!)
            }
            
            manager.alertAndSettings(controller: self, message: Constants.alertMessage)
        }
    }

    // UIContentContainer method detecting device orientation change
    override func viewWillTransition(to size: CGSize,
                            with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        deviceOrientation = UIDevice.current.orientation
    }

    
    // MARK: - Other methods
    // MARK: Configuration
    // Controller's view configuration method
    private func configureViewWithCatalog() {
        // Configuring NavigationItem
        let backItem = UIBarButtonItem()
        backItem.title = "Movie Catalog"
        navigationItem.backBarButtonItem = backItem
        // Find out device orientation
        deviceOrientation = UIDevice.current.orientation
        // Set serch icon color
        setIconColor(UIColor.white)
        // Set searchbar delegate
        searchTextBar.delegate = self
        // Set catalogCollectionView delegats
        catalogCollectionView.delegate = self
        catalogCollectionView.dataSource = self
        catalogCollectionView.prefetchDataSource = self
        // Set simple standard layout for catalogCollectionView
        catalogCollectionView.collectionViewLayout = UICollectionViewFlowLayout()
        // Notification for getting when return after Setting app
        NotificationCenter.default.addObserver(self, selector: #selector(runAtStart), name: Notification.Name("startingPoint"), object: nil)
    }
    
    // Color setter for search icon
    private func setIconColor(_ color: UIColor) {
        // Text field in search bar.
        let textField = searchTextBar.value(forKey: "searchField") as! UITextField

        let glassIconView = textField.leftView as! UIImageView
        glassIconView.image = glassIconView.image?.withRenderingMode(.alwaysTemplate)
        glassIconView.tintColor = UIColor.white

        let clearButton = textField.value(forKey: "clearButton") as! UIButton
        clearButton.setImage(clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate), for: .normal)
        clearButton.tintColor = color
    }
    
    // MARK: Data manipulating methods
    @objc func runAtStart() {
        //
        // Get movieviewmodel data from previous run
        movieViewModels = manager.realm.objects(MovieViewModel.self)
        // Clean database and reload data if connected
        if manager.isConnected {
            try! manager.realm.write {
                // Deleting
                manager.realm.delete(movieViewModels!)
            }
            // Set page counter to 1
            //manager.pageCounter = 1
            // Repopulate model property again with empty base
            movieViewModels = manager.realm.objects(MovieViewModel.self)
            // Fetch new data as several pages and reload.
            //fetchCatalog(page: manager.pageCounter)
            for i in 1...2 {
                pageCounter = i
                fetchCatalog(page: pageCounter)
            }
            //
            UserDefaults.standard.set(true, forKey: "NotFirstTime")
            firstConnectionImageView?.removeFromSuperview()
        }
        else {
            if let model = movieViewModels, model.count != 0 {
                movieViewModelsSlice = manager.realm.objects(MovieViewModel.self).prefix(upTo: 40)

                catalogCollectionView.reloadData()
            }
        }
    }
    
    // Data fetching method
    func fetchCatalog(page: Int) {
        // Pull catalog data
        manager.pullCatalog(page: page) { (movies, err) in
            if let err = err {
                print("Failed to fetch movies: \(err)")
                return
            }
            else {
                DispatchQueue.main.async {
                    movies?.forEach{ self.manager.save(movieViewModel: MovieViewModel(movie: $0))}
                    self.movieViewModelsSlice = self.manager.realm.objects(MovieViewModel.self).prefix(upTo: 40)

                    self.catalogCollectionView.reloadData()
                }
            }
        }
    }
}

// MARK: - Extension of InitialViewController for adopting UICollectionViewDataSource
extension InitialViewController: UICollectionViewDataSource {
    // MARK: How many cells
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return movieModelsArray?.count ?? 0
        
    }

    // MARK: For Cell
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath:
                        IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CatalogCell", for: indexPath) as! CatalogCollectionViewCell
        
        let dirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Movies")
        
        if let movieViewModel = movieModelsArray?[indexPath.item] {
            if movieViewModel.posterLink != "" {
                if manager.isConnected {
                    cell.updateAppearanceFor(nil, nil, animated: false)
                }
                else {
                    // Reading image files from device when disconnected
                    if let readPath = dirURL?.appendingPathComponent("\(movieViewModel.id).jpg"), let data = try? Data(contentsOf: readPath) {
                        //
                        cell.updateAppearanceFor(UIImage(data: data), movieViewModel.title, animated: true)
                    }
                    else {
                        print("File doesn't exist!")
                    }
                }
            }
            else {
                cell.updateAppearanceFor(UIImage(named: "noposter.png"), movieViewModel.title, animated: false)
            }
        }
        return cell
    }
}

// MARK: - Extension of InitialViewController for adopting UICollectionViewDataSourcePrefetching
extension InitialViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        if manager.isConnected {
            for indexPath in indexPaths {
                // Don't apply when searching
                if !searching {
                    if indexPath.item == (movieViewModels?.count)!-1 {
                        pageCounter += 1
                        fetchCatalog(page: pageCounter)
                    }
                }
                // If already started downloading image then co/ntinue
                if let _ = posterLoadingOperations[indexPath] {
                    continue
                }
                // Otherwise start downloading on background
                if let movieViewModel = movieViewModels?[indexPath.item] {
                    // Initialize the poster loading operation
                    let posterLoader = PosterLoadOperation(id: movieViewModel.id, posterLink: movieViewModel.posterLink, title: movieViewModel.title, forIndex: indexPath)
                    loadingQueue.addOperation(posterLoader)
                    posterLoadingOperations[indexPath] = posterLoader
                }
            }
        }
    }
    
    //
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        if manager.isConnected {
            for indexPath in indexPaths {
                if let posterLoader = posterLoadingOperations[indexPath] {
                    posterLoader.cancel()
                    posterLoadingOperations.removeValue(forKey: indexPath)
                }
            }
        }            
    }
}
        

// MARK: - Extension of InitialViewController for adopting UICollectionViewDelegateFlowLayout
extension InitialViewController: UICollectionViewDelegateFlowLayout {
    //  MARK: Cell sizes
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // check the idiom, iPhone or iPad
        var cellWidth = UIScreen.main.bounds.width, cellHeight = 0.0
        switch deviceType {
        case .phone:
            cellWidth = deviceOrientation == .portrait ? cellWidth/2.3 : cellWidth/5
        case .pad:
            cellWidth = UIScreen.main.bounds.width / 6
        default:
            break
        }
        cellHeight = cellWidth * 1.5

        return CGSize(width: cellWidth, height: cellHeight)
    }
}

// MARK: - Extension of InitialViewController for adopting UICollectionViewDelegate
extension InitialViewController: UICollectionViewDelegate {
    //
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Show the detail screen
        if let vc = storyboard?.instantiateViewController(withIdentifier: "DetailView") as? DetailViewController {
            //
            vc.movieViewModel = manager.isConnected ? movieViewModels?[indexPath.item] : movieViewModelsSlice?[indexPath.item]
            show(vc, sender: nil)
        }
    }
    
    // MARK: For controlling next data fetching
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {

        guard let cell = cell as? CatalogCollectionViewCell else { return }
        
        if let movieViewModel = movieModelsArray?[indexPath.item] {
            if movieViewModel.posterLink != "" {
                if manager.isConnected {
                    //
                    let updateCellClosure: (UIImage?, String?) -> Void = { (image, title) in
                        cell.updateAppearanceFor(image, title, animated: true)
                        self.posterLoadingOperations.removeValue(forKey: indexPath)
                    }
                    //
                    if let posterLoader = posterLoadingOperations[indexPath] {
                        //
                        if let image = posterLoader.moviePoster {
                            cell.updateAppearanceFor(image, movieViewModels?[indexPath.item].title, animated: false)
                            posterLoadingOperations.removeValue(forKey: indexPath)
                        }
                        else {
                            //
                            posterLoader.loadingCompleteHandler = updateCellClosure
                        }
                    }
                    else {
                        
                        if let movieViewModel = movieViewModels?[indexPath.item] {
                            //
                            let posterLoader = PosterLoadOperation(id: movieViewModel.id, posterLink: movieViewModel.posterLink, title: movieViewModel.title, forIndex: indexPath)
                            
                            //
                            posterLoader.loadingCompleteHandler = updateCellClosure
                            //
                            loadingQueue.addOperation(posterLoader)
                            //
                            posterLoadingOperations[indexPath] = posterLoader
                        }
                    }
                }
            }
        }
    }
    
    //
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if let posterLoader = posterLoadingOperations[indexPath] {
            posterLoader.cancel()
            posterLoadingOperations.removeValue(forKey: indexPath)
        }
    }
}

//MARK: - Extension of InitialViewController for adopting UISearchBarDelegate
extension InitialViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Activate searching flag
        searching = true
        
        if searchBar.text == "" {
            movieViewModels = AppManager.getInstance.realm.objects(MovieViewModel.self)
            movieViewModelsSlice = AppManager.getInstance.realm.objects(MovieViewModel.self).prefix(upTo: 40)
        }
        else {
            // For filtering movie catalog
            movieViewModels =  AppManager.getInstance.realm.objects(MovieViewModel.self).filter("title CONTAINS[cd] %@", searchBar.text!)
            
            if movieViewModels!.count != 0 {
                movieViewModelsSlice = Slice(base: movieViewModels!, bounds: Results<MovieViewModel>.Indices(0...movieViewModels!.count-1))
            }
            else {
                movieViewModelsSlice = movieViewModels?.prefix(upTo: 0)
            }
        }
        catalogCollectionView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Deactivate search flag
        if searchBar.text == "" {
            searching = false
        }
        searchTextBar.resignFirstResponder()
    }
}

extension Results {

    func toArray() -> [Element] {
        var array = [Element]()
        for result in self {
            array.append(result)
        }
        return array
    }
}

extension Slice {
    func toArray() -> [Element] {
        var array = [Element]()
        for result in self {
            array.append(result)
        }
        return array
    }
}
