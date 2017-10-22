//
//  YelpSearchController.swift
//  RestaurantReviews
//
//  Created by Pasan Premaratne on 5/9/17.
//  Copyright © 2017 Treehouse. All rights reserved.
//

import UIKit

class YelpSearchController: UIViewController {
    
    // MARK: - Properties
    
    let searchController = UISearchController(searchResultsController: nil)
    @IBOutlet weak var tableView: UITableView!
    
    let dataSource = YelpSearchResultsDataSource()
    
    lazy var locationManager: LocationManager = {
        return LocationManager(delegate: self, permissionsDelegate: nil)
    }()
    
    lazy var client: YelpClient = {
        let yelpAccount = YelpAccount.loadFromKeychain()
        let oauthToken = yelpAccount!.accessToken
        
        return YelpClient(oauthToken: oauthToken)
    }()
    
    var coordinate: Coordinate? {
        didSet {
            if let coordinate = coordinate {
                showNearbyRestaurants(at: coordinate)
            }
        }
    }
    
    var isAuthorized: Bool {
        let isAuthorizedWithYelpToken = YelpAccount.isAuthorized
        let isAuthorizedForLocation = LocationManager.isAuthorized
        
        return isAuthorizedWithYelpToken && isAuthorizedForLocation
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSearchBar()
        setupTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if isAuthorized {
            locationManager.requestLocation()
        } else {
            checkPermissions()
        }
    }
    
    // MARK: - Table View
    func setupTableView() {
        self.tableView.dataSource = dataSource
        self.tableView.delegate = self
    }
    
    // MARK: OUR OWN LOCATION
    
    func showNearbyRestaurants(at coordinate: Coordinate) {
        client.search(withTerm: "", at: coordinate) { [weak self] result in
            switch result {
            case .success(let businesses):
                self?.dataSource.update(with: businesses)
                self?.tableView.reloadData()
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // MARK: - Search
    
    func setupSearchBar() {
        self.navigationItem.titleView = searchController.searchBar
        
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchResultsUpdater = self
    }
    
    // MARK: - Permissions
    
    /// Checks (1) if the user is authenticated against the Yelp API and has an OAuth
    /// token and (2) if the user has authorized location access for whenInUse tracking.
    func checkPermissions() {
        let isAuthorizedWithToken = YelpAccount.isAuthorized
        let isAuthorizedForLocation = LocationManager.isAuthorized
        
        let permissionsController = PermissionsController(isAuthorizedForLocation: isAuthorizedForLocation, isAuthorizedWithToken: isAuthorizedWithToken)
        present(permissionsController, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDelegate
extension YelpSearchController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showBusiness", sender: nil)
    }
}

// MARK: - Search Results
extension YelpSearchController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchTerm = searchController.searchBar.text, let coordinate = coordinate else { return }
        
        if !searchTerm.isEmpty {
            client.search(withTerm: searchTerm, at: coordinate) { [weak self] result in
                switch result {
                case .success(let businesses):
                    self?.dataSource.update(with: businesses)
                    self?.tableView.reloadData()
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
}

// MARK: - Navigation
extension YelpSearchController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showBusiness" {
            
        }
    }
}

// MARK: - Location Manager Delegate
extension YelpSearchController: LocationManagerDelegate {
    func obtainedCoordinates(_ coordinate: Coordinate) {
        self.coordinate = coordinate
        print(coordinate)
    }
    
    func failedWithError(_ error: LocationError) {
        print(error)
    }
}
