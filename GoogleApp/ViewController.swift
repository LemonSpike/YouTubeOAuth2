//
//  ViewController.swift
//  GoogleApp
//
//  Created by Pranav Kasetti on 15/08/2016.
//  Copyright © 2016 Pranav Kasetti. All rights reserved.
//

import GoogleAPIClientForREST
import GTMOAuth2
import UIKit

class ViewController: UIViewController {
    
    private let kKeychainItemName = "Gmail API"
    private let kClientID = "192877572614-k4ljl168palm9oq5skbgonsagf17t20h.apps.googleusercontent.com"
    
    // If modifying these scopes, delete your previously saved credentials by
    // resetting the iOS simulator or uninstall the app.
    private let scopes = [kGTLRAuthScopeYouTubeUpload, kGTLRAuthScopeYouTube]
    
    private let service = GTLRYouTubeService()
    let output = UITextView()
    var counter=0
    let query = GTLRYouTubeQuery_PlaylistItemsList.queryWithPart("snippet")
    
    // When the view loads, create necessary subviews
    // and initialize the Gmail API service
    override func viewDidLoad() {
        super.viewDidLoad()
        
        output.frame = view.bounds
        output.editable = false
        output.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        output.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        
        view.addSubview(output);
        
        print(scopes)
        
        if let auth = GTMOAuth2ViewControllerTouch.authForGoogleFromKeychainForName(
            kKeychainItemName,
            clientID: kClientID,
            clientSecret: nil) {
            service.authorizer = auth
            service.shouldFetchNextPages = false
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
        query.playlistId = "PLVC8GDo2AhwHf38gpDahIdN5KQT060Wmq"
        query.maxResults=3
        print(query)
        
        service.executeQuery(query,
                             delegate: self,
                             didFinishSelector: "displayResultWithTicket:finishedWithObject:error:"
        )
    }
    
    // Display the labels in the UITextView
    func displayResultWithTicket(ticket : GTLRServiceTicket,
                                 finishedWithObject playlistItemList: GTLRYouTube_PlaylistItemListResponse,
                                                    error : NSError?) {
        
        if let error = error {
            showAlert("Error", message: error.localizedDescription)
            return
        }
        if output.text=="Getting labels..." {
            var labelString = ""
            
            if !playlistItemList.items!.isEmpty {
                labelString += "Labels:\n"
                for label in playlistItemList.items! {
                    labelString += "\(label.snippet!.title)\n"
                }
            } else {
                labelString = "No labels found."
            }
            counter=counter+1
            output.text = labelString
        } else {
            if !playlistItemList.items!.isEmpty {
                var labelString = output.text as String
                for label in playlistItemList.items! {
                    labelString += "\(label.snippet!.title!)\n"
                }
                counter=counter+1
                output.text = labelString
            }
        }
        
        if ((playlistItemList.nextPageToken) != nil && counter==1) {
            let query2 = GTLRYouTubeQuery_PlaylistItemsList.queryWithPart("snippet")
            query2.playlistId = "PLVC8GDo2AhwHf38gpDahIdN5KQT060Wmq"
            query2.maxResults=3
            query2.pageToken = playlistItemList.nextPageToken
            service.executeQuery(query2,
                                 delegate: self,
                                 didFinishSelector: "displayResultWithTicket:finishedWithObject:error:"
            )
        }
        
    }
    
    
    // Creates the auth controller for authorizing access to Gmail API
    private func createAuthController() -> GTMOAuth2ViewControllerTouch {
        let scopeString = scopes.joinWithSeparator(" ")
        return GTMOAuth2ViewControllerTouch(
            scope: scopeString,
            clientID: kClientID,
            clientSecret: nil,
            keychainItemName: kKeychainItemName,
            delegate: self,
            finishedSelector: "viewController:finishedWithAuth:error:"
        )
        
    }
    
    func signOut() {
        GTMOAuth2ViewControllerTouch.removeAuthFromKeychainForName(kKeychainItemName)
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