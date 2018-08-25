//
//  GoogleAPI.swift
//  NLP
//
//  Created by Arturo Reyes on 8/25/18.
//  Copyright © 2018 Arturo Reyes. All rights reserved.
//

import Foundation

struct GoogleClient {
    static let apikey = "AIzaSyCOvACsQf78KsgoYj2N1M6hQJ0PQfja09Q"
    static let APIScheme = "https"
    static let APIHost = "language.googleapis.com"
    static let APIPath = "/v1/documents:analyzeSyntax"
    static let keyParameter = "key"
    static let Post = "POST"
    static let AppHTTP = "X-Parse-Application-Id"
    static let APIHTPP = "X-Parse-REST-API-Key"
    static let encodingType = "UTF8"
    static let type = "PLAIN_TEXT"
    static let App = "application/json"
    static let Accept = "Accept"
    static let Content = "Content-Type"
    
}

extension GoogleNLP {
    
    func taskForGoogle(completionHandlerForTask: @escaping (_ result: AnyObject?, _ error: NSError?, _ errorString: String?) -> Void) -> URLSessionTask? {
        
        let parameters = [GoogleClient.keyParameter:GoogleClient.apikey]
        
        let request = NSMutableURLRequest(url: urlFromParameters(paremeters: parameters))
        request.httpMethod = GoogleClient.Post
        request.addValue(GoogleClient.App, forHTTPHeaderField: GoogleClient.Content)
        
        guard let data = requestData.convertToJSONData() else { return nil }
        request.httpBody = data
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForTask(nil, NSError(domain: "taskForMethod", code: 1, userInfo: userInfo), error)
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request")
                return
            }
            
            if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                print("Status code: \(statusCode)")
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard data != nil else {
                sendError("No data was returned by the request!")
                return
            }
            
            
            self.convertDataWithCompletionHandler(data!, completionHandlerForConvertData: completionHandlerForTask)
        }
        
        task.resume()
        return task
    }
    
    
    func urlFromParameters(paremeters: [String:String]) -> URL {
        
        var components = URLComponents()
        
        components.scheme = GoogleClient.APIScheme
        components.host = GoogleClient.APIHost
        components.path = GoogleClient.APIPath
        
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in paremeters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems?.append(queryItem)
        }
        
        return components.url!
    }
    
    func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?, _ errorString: String?) -> Void) {
        
        var parsedResult: AnyObject! = nil
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo), "Could not parse the data as JSON")
        }
        
        completionHandlerForConvertData(parsedResult, nil, nil)
    }
    
    
}

extension Dictionary {
    var jsonData: Data? {
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            return jsonData
        } catch {
            return nil
        }
    }
    
    func convertToJSONData() -> Data? {
        return jsonData
    }
}
