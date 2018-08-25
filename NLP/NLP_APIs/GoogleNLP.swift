//
//  GoogleNLP.swift
//  NLP
//
//  Created by Arturo Reyes on 8/25/18.
//  Copyright © 2018 Arturo Reyes. All rights reserved.
//

import Foundation

struct Token {
    let text: String
    let tag: String
    let lemma: String
    
    init(with dict: [String:Any]) {
        var text = ""
        var tag = ""
        
        if let tokenText = dict["text"] as? [String:Any] {
            if let tokenContent = tokenText["content"] as? String {
                text = tokenContent
            }
        }
        
        if let partOfSpeech = dict["partOfSpeech"] as? [String:Any] {
            if let tokenTag = partOfSpeech["tag"] as? String {
                tag = tokenTag
            }
        }
        
        self.text = text
        self.tag = tag
        self.lemma = (dict["lemma"] as? String) ?? ""
    }
    
}

class GoogleNLP: NSObject {
    
    var session = URLSession.shared
    var requestData = [String:Any]()
    var tokens = [Token]()
    var searchQuery = Set<String>()
    
    init(textToProcess: String) {
        
        let document: [String:String] = [
            "type": GoogleClient.type,
            "content": textToProcess]
        
        requestData["document"] = document
        requestData["encodingType"] = GoogleClient.encodingType
    }
    
    func getMeaningfulKeywords(completionHandlerForMeaningful: @escaping (_ result: Set<String>, _ errorString: String?) -> Void) {
        taskForGoogle() { (result, error, errorString) in
            if let googleResults = result as? [String:Any] {
                if let tokenList = googleResults["tokens"] as? [[String:Any]] {
                    guard tokenList.count > 0 else { return }
                    for token in tokenList {
                        self.tokens.append(Token(with: token))
                    }
                }
            } else {
                if let error = errorString {
                    completionHandlerForMeaningful(self.searchQuery, errorString)
                }
            }
            
            for token in self.tokens {
                if token.tag == "NOUN" || token.tag == "ADJ" || token.tag == "X" {
                    self.searchQuery.insert(token.text.lowercased())
                    self.searchQuery.insert(token.lemma.lowercased())
                }
            }
            
            print("Google search query \(self.searchQuery)")
            completionHandlerForMeaningful(self.searchQuery, nil)
        }
    }
    
}
