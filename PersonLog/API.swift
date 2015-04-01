//
//  API.swift
//  PersonLog
//
//  Created by Yasyf Mohamedali on 2015-03-26.
//  Copyright (c) 2015 Yasyf Mohamedali. All rights reserved.
//

import Foundation
import SwiftHTTP

class API {
    let apiRoot = "https://person-log-web.herokuapp.com/api/v1"
    //let apiRoot = "http://localhost:5000/api/v1"
    let session = NSURLSession.sharedSession()
    
    func buildRequest() -> HTTPTask {
        var request = HTTPTask()
        request.baseURL = apiRoot
        request.responseSerializer = JSONResponseSerializer()
        return request
    }
    
    func doRequest(methodFunction: (String, Dictionary<String, AnyObject>?, (HTTPResponse) -> Void, (NSError, HTTPResponse?) -> Void) -> Void, route: NSString, parameters: Dictionary<String, String>?, success: (Dictionary<String, AnyObject>) -> Void) {
        let emptyResponse: Dictionary = [String:AnyObject]()
        methodFunction(route, parameters, {(response: HTTPResponse) in
            if let responseDict = response.responseObject as? Dictionary<String,AnyObject> {
                success(responseDict)
            } else {
                success(emptyResponse)
            }
            }, {(error: NSError, response: HTTPResponse?) in
                println("Error: \(error)")
                success(emptyResponse)
        })
    }
    
    
    func get(route: NSString, parameters: Dictionary<String, String>?, success: (Dictionary<String, AnyObject>) -> Void) {
        doRequest({(url: String, parameters: Dictionary<String, AnyObject>?, success: (HTTPResponse) -> Void, failure: (NSError, HTTPResponse?) -> Void) in
                self.buildRequest().GET(url, parameters: parameters, success: success, failure: failure)
            }, route: route, parameters: parameters, success)
    }
    
    func post(route: NSString, parameters: Dictionary<String, String>?, success: (Dictionary<String, AnyObject>) -> Void) {
        doRequest({(url: String, parameters: Dictionary<String, AnyObject>?, success: (HTTPResponse) -> Void, failure: (NSError, HTTPResponse?) -> Void) in
                self.buildRequest().POST(url, parameters: parameters, success: success, failure: failure)
            }, route: route, parameters: parameters, success)
    }
}