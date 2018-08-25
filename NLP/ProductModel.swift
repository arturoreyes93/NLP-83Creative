//
//  ProductModel.swift
//  NLP
//
//  Created by Arturo Reyes on 8/24/18.
//  Copyright © 2018 Arturo Reyes. All rights reserved.
//

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
