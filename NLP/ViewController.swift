//
//  ViewController.swift
//  NLP
//
//  Created by Arturo Reyes on 8/22/18.
//  Copyright © 2018 Arturo Reyes. All rights reserved.
//

import Foundation
import UIKit

enum NLPAPI {
    case apple, google
}

class ViewController: UIViewController, UISearchBarDelegate  {

    // MARK: Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var recordingView: UIView!
    
    // MARK: Properties
    let database = NSArray(contentsOf: Bundle.main.url(forResource: "productDatabase", withExtension: "plist")!) as! [[String: Any]]
    var currentAPI: NLPAPI = .apple
    var appleNLP: AppleNLP? = nil
    var googleNLP: GoogleNLP? = nil
    var parsedDatabase = [Product]()
    var resultsSearchController = CustomSearchController(searchResultsController: nil)
    let noResultsString = "No results obtained from your search. Please try a different search."
    var shouldShowAlert = false
    var matchingItems = [Product]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
            if shouldShowAlert && matchingItems.count == 0 {
                postSimpleAlert(noResultsString)
            }
        }
    }
 
    // MARK: Initializers
    override func viewDidLoad() {
        super.viewDidLoad()
        parseDatabase()
        recordingView.isHidden = true
        let textAttributes = [NSAttributedStringKey.foregroundColor:UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationItem.title = "Apple NLP API"
        
        // Set tableview
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 200
        tableView.tableHeaderView = resultsSearchController.dictationSearchBar
        
        // Set search controller and search bar
        resultsSearchController.dictationSearchBar.placeholder = "Search for a product..."
        resultsSearchController.dictationSearchBar.sizeToFit()
        resultsSearchController.dictationSearchBar.delegate = self
        resultsSearchController.dictationSearchBar.recordingDelegate = self
        resultsSearchController.dictationSearchBar.uiRecordingDelegate = self
        resultsSearchController.hidesNavigationBarDuringPresentation = false
        resultsSearchController.dimsBackgroundDuringPresentation = true
        resultsSearchController.dictationSearchBar.searchBarStyle = .prominent
        definesPresentationContext = true
        
    }
    
    /// Store database in an array of objects for optimized handling
    func parseDatabase() {
        for product in database {
            parsedDatabase.append(Product(product))
        }
    }
    
    /// Post an alert to the user for errors
    func postSimpleAlert(_ title: String) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: UIAlertControllerStyle.alert)
        let dismiss = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil)
        alert.addAction(dismiss)
        self.present(alert, animated: true, completion: nil)
    }
    
    /// Switch between Apple's and Google's NLP API to analyze different results (Google proved to be more accurate)
    @IBAction func changeCurrentAPI(_ sender: UIBarButtonItem) {
        switch currentAPI {
        case .apple:
            currentAPI = .google
            navigationItem.title = "Google NLP API"
        default:
            currentAPI = .apple
            navigationItem.title = "Apple NLP API"
        }
    }
    
    // MARK: SearchBar Delegate Methods
    fileprivate func performSearch(_ searchBar: UISearchBar) {
        if searchBar.text != nil || searchBar.text != "" {
            switch currentAPI {
            case .apple:
                appleNLP = AppleNLP(textToProcess: searchBar.text!)
                appleNLP?.getMeaningfulKeywords() { [unowned self] (result) in
                    guard result.count > 0 else {
                        // Handle no meaningful words found
                        self.postSimpleAlert(self.noResultsString)
                        return }
                    print("searchQuery: \(result)")
                    self.matchingItems = self.parsedDatabase.filter({$0.keywords.sharesElements(with: Array(result))})
                }
            
            case .google:
                googleNLP = GoogleNLP(textToProcess: searchBar.text!)
                googleNLP?.getMeaningfulKeywords() { [unowned self] (googleResult, error) in
                    guard googleResult.count > 0 else {
                        // Handle no meaningful words found
                        let alertString = (error == nil) ? self.noResultsString : error
                        self.postSimpleAlert(alertString!)
                        return }
                    print("searchQuery: \(googleResult)")
                    self.matchingItems = self.parsedDatabase.filter({$0.keywords.sharesElements(with: Array(googleResult))})
                }
            }
        }
        
        shouldShowAlert = true
    }
    
    /// Make search query only upon clicking search button since the query is ideally a service call
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch(searchBar)
    }
    
    /// Clear table when cancel button is clicked
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.isFirstResponder {
            searchBar.resignFirstResponder()
            searchBar.showsCancelButton = false
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.5) {
                    searchBar.showsCancelButton = false
                    searchBar.layoutIfNeeded()
                }
            }
        }
        shouldShowAlert = false
        matchingItems.removeAll()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5) {
                searchBar.showsCancelButton = true
                searchBar.layoutIfNeeded()
            }
        }
    }

}

// MARK: Recording Delegate Methods
extension ViewController: UIRecordingDelegate, SpeechRecordingDelegate {
    
    /// Show blurred view and stop button while user is recording text to search
    func enableRecordingUI() {
        
        if resultsSearchController.dictationSearchBar.isFirstResponder {
            resultsSearchController.dictationSearchBar.resignFirstResponder()
        }
        
        DispatchQueue.main.async {
            UIView.transition(with: self.recordingView, duration: 0.5, options: .transitionCrossDissolve, animations: {
                self.recordingView.isHidden = false
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    /// Recording was finished and there are results to perform search
    func didFinishRecordingWithResult() {
        performSearch(resultsSearchController.dictationSearchBar)
    }
    
    /// Stop button pressed to stop recording
    @IBAction func stopRecording(_ sender: Any) {
        
        resultsSearchController.dictationSearchBar.stopButtonPressed = true

        DispatchQueue.main.async {
            self.resultsSearchController.dictationSearchBar.searchField.rightView = self.resultsSearchController.dictationSearchBar.activityIndicator
            self.resultsSearchController.dictationSearchBar.activityIndicator.startAnimating()
            UIView.transition(with: self.recordingView, duration: 0.5, options: .transitionCrossDissolve, animations: {
                self.recordingView.isHidden = true
                self.recordingView.layoutIfNeeded()
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
}

// MARK: TableView Delegate Method
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath)
        let product = matchingItems[indexPath.row]
        cell.textLabel?.text = product.name
        cell.detailTextLabel?.text = product.features
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .white
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.backgroundView?.backgroundColor = .clear
    }
}

extension Array where Element: Comparable {
    
    /// returns true if the given array shares the same element with another array, in our case, if the same string is present in the second array
    func sharesElements(with other: [Element]) -> Bool {
        for element in other {
            if self.contains(element) {
                return true
            }
        }
        return false
    }
}

