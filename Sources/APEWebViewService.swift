//
//  APEWebViewService.swift
//  ApesterKit
//
//  Created by Hasan Sa on 12/07/2017.
//  Copyright © 2017 Apester. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import AdSupport

private struct APEConfig {
  
  enum Payload: String {
    case advertisingId, trackingEnabled, bundleId
  }
  
  static let javascriptFunctionName = "getAdTrackingInfo"
}


/// APEWebViewService provides a light-weight framework that loads Apester Unit in a webView
public class APEWebViewService: NSObject {
  
  fileprivate var bundleIdentifier: String?
  fileprivate var webView: APEWebViewProtocol?
  
  fileprivate var javaScriptString: String {
    
    // input payload
    var inputPayload: [String: Any] = [:]
    
    // get the device advertisingIdentifier
    if let identifierManager = ASIdentifierManager.shared(), let idfa = identifierManager.advertisingIdentifier {
      inputPayload[APEConfig.Payload.advertisingId.rawValue] = idfa.uuidString
      inputPayload[APEConfig.Payload.trackingEnabled.rawValue] = identifierManager.isAdvertisingTrackingEnabled
    }
    // get the app bundleIdentifier
    if let bundleIdentifier = self.bundleIdentifier {
      inputPayload[APEConfig.Payload.bundleId.rawValue] = bundleIdentifier
    }
    // Serialize the Swift object into Data
    let serializedData = try! JSONSerialization.data(withJSONObject: inputPayload, options: [])
    // Encode the data into JSON string
    let encodedData = String(data: serializedData, encoding: String.Encoding.utf8)
    
    return "\(APEConfig.javascriptFunctionName)('\(encodedData!)')"
  }
  
  /// APEWebViewService shared instance
  public static let shared = APEWebViewService()
  
  // MARK: - API
  
  /**
   webview can be either UIWebView or WKWebView only
  
   - Parameters:
     - webView: either UIWebview or WKWebView instance
     - completionHandler: an optional callback with APEResult response
   
   ### Usage Example: ###
   *  self is an instance of UIViewController
   
   ````
   APEWebViewService.shared.register(with: self.webView)
   ````
   * or
   
   ````
   APEWebViewService.shared.register(with: self.webView) { result in
     switch result {
       case .success(let success):
       // do something
       case .failure(let failure):
       // do something
     }
   }
   ````
 */
  public func register(with webView: APEWebViewProtocol, completionHandler: ((APEResult<Bool>) -> Void)? = nil) {
    
    self.webView = webView
    completionHandler?(APEResult.success(true))
  }
  
  /** 
   call this function once the webview did start load - the UIWebView delegate trigger event
  
   - Parameters:
     - sender: must be a ViewController class
     - completionHandler: an optional callback with APEResult response
   ### Usage Example: ###
   *  self is an instance of UIViewController
   
   ````
   APEWebViewService.shared.webView(didStartLoad: self.classForCoder)
   ````
   * or
   
   ````
   APEWebViewService.shared.webView(didStartLoad: self.classForCoder) { result in 
    switch result {
      case .success(let success):
        // do something
      case .failure(let failure):
        // do something
    }
   }
   ````
  */
  public func webView(didStartLoad sender: AnyClass, completionHandler: ((APEResult<Bool>) -> Void)? = nil) {
    
    guard extractBundle(from: sender) else {
      completionHandler?(APEResult.failure("invalid bundle identifier"))
      return
    }
    completionHandler?(APEResult.success(true))
  }
  
  /**
   call this function once the webview did finish load - the UIWebView delegate trigger event
  
   - Parameters:
     - sender: must be a ViewController class
     - completionHandler: an optional callback with APEResult response
   ### Usage Example: ###
   *  self is an instance of UIViewController
   ````
   APEWebViewService.shared.webView(didFinishLoad: self.classForCoder)
   ````
   
   * or
   ````
   APEWebViewService.shared.webView(didFinishLoad: self.classForCoder) { result in
     switch result {
       case .success(let success):
       // do something
       case .failure(let failure):
       // do something
     }
   }
   ````
  */
  public func webView(didFinishLoad sender: AnyClass, completionHandler: ((APEResult<Bool>) -> Void)? = nil) {
    
    guard self.webView != nil else {
      completionHandler?(APEResult.failure("must register webView"))
      return
    }
    guard extractBundle(from: sender) else {
      completionHandler?(APEResult.failure("invalid bundle identifier"))
      return
    }
    // Now pass this dictionary to javascript function (Assuming it exists in the HTML code)
    self.evaluateJavaScript()
    completionHandler?(APEResult.success(true))
  }
  
  /**
   call this function once the webview did fail load - the UIWebView delegate trigger event
  
   - Parameters:
     - sender: must be a ViewController class
     - failuer: failuer the webview load failuer error occred
     - completionHandler: an optional callback with APEResult response
   ### Usage Example: ###
   *  self is an instance of UIViewController
   
   ````
   APEWebViewService.shared.webView(didFailLoad: self.classForCoder, failuer: error)
   ````
   
   * or
   
   ````
   APEWebViewService.shared.webView(didFailLoad: self.classForCoder, failuer: error) { result in
     switch result {
       case .success(let success):
       // do something
       case .failure(let failure):
       // do something
     }
   }
   ````
  */
  public func webView(didFailLoad sender: AnyClass, failuer: Error?, completionHandler: ((APEResult<Bool>) -> Void)? = nil) {
    
    guard self.webView != nil else {
      completionHandler?(APEResult.failure("must register webView"))
      return
    }
    completionHandler?(APEResult.success(true))
  }
  
}

// MARK: - PRIVATE
fileprivate extension APEWebViewService {
  
  fileprivate func extractBundle(from sender: AnyClass) -> Bool {
    guard self.bundleIdentifier == nil else {
      return true
    }
    guard let bundleIdentifier = Bundle(for: sender.self).bundleIdentifier else {
      return false
    }
    self.bundleIdentifier = bundleIdentifier
    return true
  }
  
  fileprivate func evaluateJavaScript() {
    if let webView = webView as? UIWebView {
      // invoke stringByEvaluatingJavaScript in case of you are using UIWebView
      let _ = webView.stringByEvaluatingJavaScript(from: self.javaScriptString)
      
    } else if let webView = webView as? WKWebView {
      // invoke stringByEvaluatingJavaScript(_: completionHandler) in case of you are using WKWebView
      webView.evaluateJavaScript(self.javaScriptString){ (_, _) in }
    }
  }
}
