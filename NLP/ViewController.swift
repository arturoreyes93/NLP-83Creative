//
//  ViewController.swift
//  NLP
//
//  Created by Arturo Reyes on 8/22/18.
//  Copyright © 2018 Arturo Reyes. All rights reserved.
//

import Foundation
import UIKit

struct Product {
    let name: String
    let features: String
    let keywords: [String]
    
    init(_ productDict: [String:Any]) {
        self.name = productDict["productName"] as! String
        self.features = productDict["productFeatures"] as! String
        self.keywords = productDict["keywords"] as! [String]
    }
}

class ViewController: UIViewController, UISearchBarDelegate  {

    // MARK: Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var recordingView: UIView!
    
    // MARK: Properties
    let database = NSArray(contentsOf: Bundle.main.url(forResource: "productDatabase", withExtension: "plist")!) as! [[String: Any]]
    var parsedDatabase = [Product]()
    var resultsSearchController = CustomSearchController(searchResultsController: nil)
    var tagger = NSLinguisticTagger(tagSchemes: [.lemma, .lexicalClass, .nameType], options: 0)
    let options: NSLinguisticTagger.Options = [.omitWhitespace, .joinNames]
    var range: NSRange!
    var searchQuery = Set<String>()
    var matchingItems = [Product]() {
        didSet {
            tableView.reloadData()
        }
    }
 
    // MARK: Initializers
    override func viewDidLoad() {
        super.viewDidLoad()
        parseDatabase()
        recordingView.isHidden = true
        navigationItem.title = "Search For A Product"
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = resultsSearchController.dictationSearchBar
        resultsSearchController.dictationSearchBar.placeholder = "Search here..."
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
    
    // Natural Language Methods
    
    /// Get meaningful keywords from search query text
    func getMeaningfulKeywords(_ text: String) {
        tagger.string = text
        range = NSRange(location: 0, length: text.utf16.count)
        getWordsWithPunctuation(text)
        getMeaningfulPartsOfSpeech(text) { (meaningful) in
            self.lemmatizationOfMeaningfulWords(text, meaningfulWords: meaningful) { (meaningfulAndRoots) in
                for word in meaningfulAndRoots {
                    self.searchQuery.insert(word.lowercased())
                }
            }
        }
    }
    
    func getWordsWithPunctuation(_ text: String) {
        var prevTokenType: NSLinguisticTag?
        var prevTokenRange: NSRange?
        var prevToken: String?
        var isDashWord = false
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .tokenType, options: options) {
            tag, tokenRange, _ in
            let token = (text as NSString).substring(with: tokenRange)
            print("\(token) : \(tag)")
//            if tag == NSLinguisticTag.dash {
//
//            }
        }
    }
    
    /// Add place name entities to search field
    func getNameEntities(_ text: String) {
        let tags: [NSLinguisticTag] = [.placeName, .organizationName]
        tagger.enumerateTags(in: range, unit: .word, scheme: .nameType, options: options) {
            tag, tokenRange, _ in
            if let tag = tag, tags.contains(tag) {
                let name = (text as NSString).substring(with: tokenRange)
                searchQuery.insert(name.lowercased())
                print("name: \(name)")
            }
        }
    }
    
    /// Extract nouns, adjectives and other words from search query text
    func getMeaningfulPartsOfSpeech(_ text: String, completionHandler: @escaping (_ result: [String]) -> Void) {
        var meaningfulWords = [String]()
        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass, options: options) {
            tag, tokenRange, _ in
            if let tag = tag {
                let word = (text as NSString).substring(with: tokenRange)
                print("\(word): \(tag.rawValue)")
                if tag == NSLinguisticTag.noun || tag == NSLinguisticTag.adjective || tag == NSLinguisticTag.otherWord {
                    meaningfulWords.append(word.lowercased())
                }
            }
        }
        print("meaningfulWords: \(meaningfulWords)")
        completionHandler(meaningfulWords)
    }
    
    /// Add the base root words from the meaningful words to increase search field
    func lemmatizationOfMeaningfulWords(_ text: String, meaningfulWords: [String], completionHandlerForLemma: @escaping (_ result: [String]) -> Void) {
        var meaningfulAndRootWords = meaningfulWords
        tagger.enumerateTags(in: range, unit: .word, scheme: .lemma, options: options) { tag, tokenRange, stop in
            if let lemma = tag?.rawValue {
                let word = (text as NSString).substring(with: tokenRange)
                if meaningfulWords.contains(word) {
                    meaningfulAndRootWords.append(lemma)
                }
                print("\(word): \(lemma)")
            }
        }
        
        completionHandlerForLemma(meaningfulAndRootWords)
        
        print("meaningfulAndRoot: \(meaningfulAndRootWords)")
    }
    
    // MARK: SearchBar Delegate Methods
    
    fileprivate func performSearch(_ searchBar: UISearchBar) {
        searchQuery.removeAll()
        if searchBar.text != nil || searchBar.text != "" {
            getMeaningfulKeywords(searchBar.text!)
            print("searchQuery: \(searchQuery)")
            matchingItems = parsedDatabase.filter({$0.keywords.sharesElements(with: Array(searchQuery))})
        }
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
    
    func enableRecordingUI() {
        
        DispatchQueue.main.async {
            UIView.transition(with: self.recordingView, duration: 0.5, options: .transitionCrossDissolve, animations: {
                self.recordingView.isHidden = false
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    func didFinishRecordingWithResult() {
        performSearch(resultsSearchController.dictationSearchBar)
    }
    
    
    @IBAction func stopRecording(_ sender: Any) {
        
        resultsSearchController.dictationSearchBar.stopButtonPressed = true
        
        DispatchQueue.main.async {
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
        return cell
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

