//
//  APEUnitWebView.swift
//  Apester
//
//  Created by Almog Haimovitch on 09/03/2020.
//  Copyright © 2020 Apester. All rights reserved.
//

import Foundation
import WebKit

@objcMembers public class APEUnitView: NSObject {
    
    public private(set) var unitWebView: WKWebView!
    private var containerView: UIView?
    private weak var containerViewConroller: UIViewController?
    private var configuration: APEUnitConfiguration!
    
    public init(configuration: APEUnitConfiguration) {
        super.init()
        
        self.configuration = configuration
        let options = WKWebView.Options(events: [Constants.Unit.proxy], contentBehavior: .never, delegate: self)
        
        self.unitWebView = WKWebView.make(with: options)
        
        if let unitUrl = configuration.unitURL {
            unitWebView.load(URLRequest(url: unitUrl))
        }
        
    }
    
     public func display(in containerView: UIView, containerViewConroller: UIViewController) {
     
        // update unitWebView frame according to containerView bounds
        containerView.layoutIfNeeded()
        containerView.addSubview(self.unitWebView)
        
        unitWebView.anchor(top: containerView.topAnchor, paddingTop: 0, bottom: containerView.bottomAnchor, paddingBottom: 0, leadingAnchor: containerView.leadingAnchor, paddingLeading: 0, trailingAnchor: containerView.trailingAnchor, paddingTrailing: 0, width: nil, height: nil)
    
        self.containerView = containerView
        self.containerViewConroller = containerViewConroller
        
    }
    
}

extension APEUnitView: WKNavigationDelegate {
    public func webView(_ webView: WKWebView,
                 didReceive challenge: URLAuthenticationChallenge,
                 completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if case .local = self.configuration.environment,
            challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
            return
        }
        completionHandler(.performDefaultHandling, nil)
    }
    
    // todo handle failures
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    }
}

private extension APEUnitView {
    
    func setContainerViewSize(anchor: NSLayoutDimension, attribute: NSLayoutConstraint.Attribute, size: CGFloat) {
        
        self.containerView?.constraints
            .first(where: { $0.firstAttribute == attribute })
            .flatMap { NSLayoutConstraint.deactivate([$0]) }
        
        let containerViewConstraint = anchor.constraint(equalToConstant: size)
        containerViewConstraint.priority = .defaultHigh
        containerViewConstraint.isActive = true
        
    }
    
    func update(size: CGSize) {
        
        let unitWebViewHeightConstraint = unitWebView.heightAnchor.constraint(equalToConstant: size.height)
        unitWebViewHeightConstraint.isActive = false
        unitWebViewHeightConstraint.priority = .defaultHigh
        unitWebViewHeightConstraint.isActive = true
        
        // height
        if let heightAnchor = self.containerView?.heightAnchor {
            self.setContainerViewSize(anchor: heightAnchor, attribute: .height, size: size.height)
        }
        
        //width
        if let widthAnchor = self.containerView?.widthAnchor {
            self.setContainerViewSize(anchor: widthAnchor, attribute: .width, size: size.width)
        }
        
    }
    
}

extension APEUnitView: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.webView?.hash == self.unitWebView.hash,
            message.name == Constants.Unit.proxy,
            let bodyString = message.body as? String {

            if bodyString.contains(Constants.Unit.resize),
                let dictionary = bodyString.dictionary {
                let height = dictionary.floatValue(for: Constants.Unit.height)
                let width = dictionary.floatValue(for: Constants.Unit.width)
                self.update(size: CGSize(width: width, height: height));
            }

        }
    }
}

extension APEUnitView: WKUIDelegate {}

extension APEUnitView: UIScrollViewDelegate {}

private extension Dictionary {
    func floatValue(for key: Key) -> CGFloat {
        CGFloat(self[key] as? Double ?? 0)
    }
}
