//
//  AppleNLP.swift
//  NLP
//
//  Created by Arturo Reyes on 8/25/18.
//  Copyright © 2018 Arturo Reyes. All rights reserved.
//

import Foundation

class AppleNLP {
    
    var text: String!
    var tagger = NSLinguisticTagger(tagSchemes: [.lemma, .lexicalClass, .nameType], options: 0)
    let options: NSLinguisticTagger.Options = [.omitWhitespace, .joinNames]
    var range: NSRange!
    var searchQuery = Set<String>()
    
    init(textToProcess: String) {
        self.text = textToProcess
        tagger.string = text
        range = NSRange(location: 0, length: text.utf16.count)
    }
    
    
    // Natural Language Methods
    
    /// Get meaningful keywords from search query text
    func getMeaningfulKeywords(completionHandlerForMeaningful: @escaping (_ result: Set<String>) -> Void) {
        getMeaningfulPartsOfSpeech(text) { (meaningful) in
            self.lemmatizationOfMeaningfulWords(self.text, meaningfulWords: meaningful) { [unowned self] (meaningfulAndRoots) in
                for word in meaningfulAndRoots {
                    self.searchQuery.insert(word.lowercased())
                }
            }
        }
        
        completionHandlerForMeaningful(searchQuery)
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
    
    
}
