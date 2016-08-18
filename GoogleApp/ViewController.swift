//
//  ViewController.swift
//  GoogleApp
//
//  Created by Pranav Kasetti on 15/08/2016.
//  Copyright © 2016 Pranav Kasetti. All rights reserved.
//

import GoogleAPIClient
import GTMOAuth2
import UIKit

class ViewController: UIViewController {
    
    private let kKeychainItemName = "Gmail API"
    private let kClientID = "192877572614-h8luf2s48sp0b4ikub5fipb22gm00nb3.apps.googleusercontent.com"
    
    // If modifying these scopes, delete your previously saved credentials by
    // resetting the iOS simulator or uninstall the app.
    private let scopes = [kGTLAuthScopeYouTubeUpload]
    
    private let service = GTLServiceYouTube()
    let output = UITextView()
    
    // When the view loads, create necessary subviews
    // and initialize the Gmail API service
    override func viewDidLoad() {
        super.viewDidLoad()
        
        output.frame = view.bounds
        output.editable = false
        output.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        output.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        
        view.addSubview(output);
        
        if let auth = GTMOAuth2ViewControllerTouch.authForGoogleFromKeychainForName(
            kKeychainItemName,
            clientID: kClientID,
            clientSecret: "7o9FEQUiOmK885m15iyRLXgw") {
            service.authorizer = auth
        }
        
    }
    
    // When the view appears, ensure that the Gmail API service is authorized
    // and perform API calls
    override func viewDidAppear(animated: Bool) {
        if let authorizer = service.authorizer,
            canAuth = authorizer.canAuthorize where canAuth {
            fetchLabels()
        } else {
            presentViewController(
                createAuthController(),
                animated: true,
                completion: nil
            )
        }
    }
    
    // Construct a query and get a list of upcoming labels from the gmail API
    func fetchLabels() {
        output.text = "Getting labels..."
        
        let query = GTLQueryYouTube.queryForPlaylistsListWithPart("snippet")
        service.executeQuery(query,
                             delegate: self,
                             didFinishSelector: "displayResultWithTicket:finishedWithObject:error:"
        )
    }
    
    // Display the labels in the UITextView
    func displayResultWithTicket(ticket : GTLServiceTicket,
                                 finishedWithObject labelsResponse : GTLYouTubePlaylistListResponse,
                                                    error : NSError?) {
        
        if let error = error {
            showAlert("Error", message: error.localizedDescription)
            return
        }
        
        var labelString = ""
        
        if !labelsResponse.items().isEmpty {
            labelString += "Labels:\n"
            for label in labelsResponse.items() as! [GTLYouTubePlaylistItem] {
                labelString += "\(label.snippet.channelTitle)\n"
            }
        } else {
            labelString = "No labels found."
        }
        
        output.text = labelString
        
    }
    
    
    // Creates the auth controller for authorizing access to Gmail API
    private func createAuthController() -> GTMOAuth2ViewControllerTouch {
        let scopeString = scopes.joinWithSeparator(" ")
        return GTMOAuth2ViewControllerTouch(
            scope: scopeString,
            clientID: kClientID,
            clientSecret: "7o9FEQUiOmK885m15iyRLXgw",
            keychainItemName: kKeychainItemName,
            delegate: self,
            finishedSelector: "viewController:finishedWithAuth:error:"
        )
    }
    
    // Handle completion of the authorization process, and update the Gmail API
    // with the new credentials.
    func viewController(vc : UIViewController,
                        finishedWithAuth authResult : GTMOAuth2Authentication, error : NSError?) {
        
        if let error = error {
            service.authorizer = nil
            showAlert("Authentication Error", message: error.localizedDescription)
            return
        }
        
        service.authorizer = authResult
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Helper for showing an alert
    func showAlert(title : String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.Alert
        )
        let ok = UIAlertAction(
            title: "OK",
            style: UIAlertActionStyle.Default,
            handler: nil
        )
        alert.addAction(ok)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}