//
//  APEWebViewService.swift
//  ApesterKit
//
//  Created by Hasan Sa on 12/07/2017.
//  Copyright © 2017 Apester. All rights reserved.
//

import Foundation
import WebKit

/// APEWebViewService provides a light-weight framework that loads Apester Unit in a webView
public class APEWebViewService: NSObject {
    /// APEWebViewService shared instance
    public static let shared = APEWebViewService()

    /// the app main bundle
    fileprivate var bundle: Bundle?
    fileprivate var unitHeightHandlers: [Int: APEUnitHeightHandler] = [:]
    fileprivate var unitsLoadedSet = Set<Int>()

    // the converted apesterLoadCallback js file to  string
    fileprivate lazy var loadCallbackJSString: String = {
        return APEBundle.contentsOfFile(APEConfig.WebView.loadCallbackFileName)
    }()

    // the converted apesterLoadCallback js file to  string
    fileprivate lazy var registerJSString: String = {
        return APEBundle.contentsOfFile(APEConfig.WebView.registerJSFileName)
    }()

    // the function with payload params string
    fileprivate var adevrtisingParamsJSFunctionString: String? {
        // Serialize the Swift object into Data
        if let serializedData = try? JSONSerialization.data(withJSONObject: APEBundle.bundleInfoPayload(with: self.bundle), options: []) ,
            // Encode the data into JSON string
            let encodedData = String(data: serializedData, encoding: String.Encoding.utf8) {
            return "\(APEConfig.WebView.initAdevrtisingParamsFunctionName)('\(encodedData)')"
        }
        return nil
    }

    // evaluateJavaScript on UIWebView or WKWebView
    fileprivate func evaluateJavaScript(_ javaScriptString: String? = nil, webView: WKWebView) -> String? {
        guard let javaScriptString = javaScriptString else {
            return nil
        }

        // invoke stringByEvaluatingJavaScript(_: completionHandler) in case of you are using WKWebView
        webView.evaluateJavaScript(javaScriptString) { (_, _) in }
        return ""
    }
}

// MARK: - WKScriptMessageHandler
extension APEWebViewService: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let handler = self.unitHeightHandlers[userContentController.hashValue] else {
            return
        }
        // This takes a while, but eventually we'll the proper height here.
        guard let number = message.body as? NSNumber else { return }
        handler(APEResult.success(CGFloat(truncating: number) + 15))
        self.unitHeightHandlers[userContentController.hashValue] = nil
    }
}


// MARK: - Interface
public extension APEWebViewService {

    typealias APEResultHandler = ((APEResult<Bool>) -> Void)
    typealias APEUnitHeightHandler = ((APEResult<CGFloat>) -> Void)

    /**
     call register(bundle:webview:unitHeightHandler:completionHandler:) function from viewDidLoad

     - Parameters:
         - bundle: the app main bundle
         - webview: the viewcontroller webview subview
         - unitHeightHandler: an optional callback with APEResult response of the apester unit height
         - completionHandler: an optional callback with APEResult response of the api success or failure

     ### Usage Example: ###

     ````
     override func viewDidLoad() {
     super.viewDidLoad()
     APEWebViewService.shared.register(bundle: Bundle.main, webView: webView, unitHeightHandler: { [weak self] result in
     switch result {
     case .success(let height):
     print(height)
     case .failure(let err):
     print(err)
     }
     })
     // your stuff here
     }
     ````
     */
    func register(bundle: Bundle, webView: WKWebView,
                  unitHeightHandler: APEUnitHeightHandler? = nil, completionHandler: APEResultHandler? = nil) {
        self.bundle = bundle

        // Create a config and add the listener and the custom script
        let config = webView.configuration

        // Load the script to be inserted into the template
        let script = WKUserScript(source: registerJSString, injectionTime: .atDocumentStart, forMainFrameOnly: true)

        config.userContentController.removeScriptMessageHandler(forName: APEConfig.WebView.callbackFunction)
        config.userContentController.add(self, name: APEConfig.WebView.callbackFunction)
        config.userContentController.addUserScript(script)

        if let unitHeightHandler = unitHeightHandler {
            self.unitHeightHandlers[config.userContentController.hashValue] = unitHeightHandler
        }


        completionHandler?(APEResult.success(self.bundle != nil))
    }

    /**
     call didStartLoad(webView:) function once the webview delegate didStartLoad triggered,
     then APEWebViewService will evaluateJavaScript on the webview with extracting params from the app bundle.

     - Parameters:
         - webView: must be an instance of UIWebView Or WKWebview
         - completionHandler: an optional callback with APEResult response

     ### Usage Example: ###

     ````
     // UIWebViewDelegate -
     func webViewDidStartLoad(_ webView: UIWebView) {
     APEWebViewService.shared.didStartLoad(webView: webView)
     }
     ````
     * or

     ````
     // WKNavigationDelegate -
     func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
     APEWebViewService.shared.didStartLoad(webView: webView)
     }
     ````
     */
    func didStartLoad(webView: WKWebView, completionHandler: APEResultHandler? = nil) {
        guard !unitsLoadedSet.contains(webView.configuration.userContentController.hashValue) else {
            return
        }
        unitsLoadedSet.insert(webView.configuration.userContentController.hashValue)

        // declaration of loadCallbackJS (initAdevrtisingParams function)
        var res = self.evaluateJavaScript(self.loadCallbackJSString, webView: webView)

        // call initAdevrtisingParams function with the device params info
        res = self.evaluateJavaScript(self.adevrtisingParamsJSFunctionString, webView: webView)
        completionHandler?(APEResult.success(res != nil))
    }
}
