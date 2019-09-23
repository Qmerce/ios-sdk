//
//  APEStripView.swift
//  ApesterKit
//
//  Created by Hasan Sa on 24/02/2019.
//  Copyright © 2019 Apester. All rights reserved.
//

import Foundation
import WebKit
import SafariServices

#if os(iOS)
@available(iOS 11.0, *)
/// A ChannelToken Loading state update
@objc public protocol APEStripViewDelegate: NSObjectProtocol {


    /// when the ChannelToken loaded successfuly
    ///
    /// - Parameter token: the channel token id
    func stripView(didFinishLoadingChannelToken token:String)


    /// when the ChannelToken couldn't be loaded
    ///
    /// - Parameter token: the channel token id
    func stripView(didFailLoadingChannelToken token:String)


    /// when the stripView height has been updated
    ///
    /// - Parameter height: the stripView new height
    func stripView(didUpdateHeight height:CGFloat)
}

@available(iOS 11.0, *)

/// A Proxy Messaging Handler
///
/// Between The Apester Units Carousel component (The `StripWebView`)
/// And the selected Apester Unit (The `StoryWebView`)
@objcMembers public class APEStripView: NSObject {

    private typealias StripConfig = APEConfig.Strip

    private var lastDeviceOrientation: UIDeviceOrientation = UIDevice.current.orientation

    class FastStripStoryViewController: UIViewController {
        var webView: WKWebView?

        override func viewDidLoad() {
            super.viewDidLoad()
            self.webView!.frame = self.view.bounds
            self.view.addSubview(self.webView!)
        }

        deinit {
            self.webView?.configuration.userContentController
                .unregister(from: [StripConfig.proxy,
                                   StripConfig.showStripStory,
                                   StripConfig.hideStripStory])
        }
    }

    private weak var stripContainerViewConroller: UIViewController?
    private var containerView: UIView?

    private lazy var stripStoryViewController: FastStripStoryViewController = {
        let stripStoryVC = FastStripStoryViewController()
        stripStoryVC.webView = self.storyWebView
        return stripStoryVC
    }()

    // MARK:- Private Properties
    private var configuration: APEStripConfiguration!

    private var messagesTracker = APEStripServiceEventsTracker()

    private var loadingState = APEStripLoadingState()

    private lazy var stripWebView: WKWebView = {
        let webView = WKWebView()
        webView.navigationDelegate = self
        webView.configuration.websiteDataStore = WKWebsiteDataStore.default()
        webView.configuration.userContentController.register(to: [StripConfig.proxy], delegate: self)
        if let url = self.configuration?.url {
            webView.load(URLRequest(url: url))
        }
        return webView
    }()

    private lazy var storyWebView: WKWebView  = {
        let webView = WKWebView()
        webView.navigationDelegate = self
        webView.configuration.websiteDataStore = WKWebsiteDataStore.default()
        webView.configuration.userContentController
            .register(to: [StripConfig.proxy,
                           StripConfig.showStripStory,
                           StripConfig.hideStripStory],
                      delegate: self)
        if let storyUrl = URL(string: StripConfig.stripStoryUrlPath) {
            webView.load(URLRequest(url: storyUrl))
        }
        return webView
    }()

    public weak var delegate: APEStripViewDelegate?

    public var height: CGFloat {
        return CGFloat(self.loadingState.height) + (self.configuration.style.verticalPadding)
    }

    // MARK:- Initializer

    /// init with channelToken and bundle
    ///
    /// - Parameters:
    ///   - channelToken: the publisher channel id
    ///   - bundle: the bundle to extract the app basic information
    @available(*, deprecated, message: "Please Use init(configuration: APEStripConfiguration) inializer")
    convenience public init(channelToken: String, bundle: Bundle) {
        let style = APEStripStyle(shape: .roundSquare, size: .medium,
                                  padding: UIEdgeInsets(top: 5.0, left: 0, bottom: 0, right: 0),
                                  shadow: false, textColor: nil, background: nil)
        let config = try! APEStripConfiguration(channelToken: channelToken, style: style, bundle: bundle)
        self.init(configuration: config)
    }

    /// init with configuration
    ///
    /// - Parameter configuration: the strip view custom configuration, i.e channelToken, shape, size
    public init(configuration: APEStripConfiguration) {
        super.init()
        self.configuration = configuration
        // prefetch channel data...
        _ = self.stripWebView
        _ = self.storyWebView
        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            guard let stronSelf = self, let containerView = stronSelf.containerView, let stripContainerViewConroller = stronSelf.stripContainerViewConroller else {
                return
            }
            // validate that when the stripStoryViewController is presented the orientation must be portrait mode
            if stronSelf.stripStoryViewController.presentingViewController != nil, !UIDevice.current.orientation.isPortrait {
                stronSelf.lastDeviceOrientation = UIDevice.current.orientation
                stronSelf.setDeviceOrientation(UIInterfaceOrientation.portrait.rawValue)
                return
            }
            // reload stripWebView
            stronSelf.stripWebView.reload()
            stronSelf.stripWebView.removeFromSuperview()
            stronSelf.display(in: containerView, containerViewConroller: stripContainerViewConroller)
        }

    }

    /// Display the channel carousel units view
    ///
    /// - Parameters:
    ///   - containerView: the channel strip view superview
    ///   - containerViewConroller: the container view ViewController
    public func display(in containerView: UIView, containerViewConroller: UIViewController) {
//        // update stripWebView frame according to containerView bounds
        containerView.layoutIfNeeded()
        containerView.addSubview(self.stripWebView)
        stripWebView.translatesAutoresizingMaskIntoConstraints = false
        stripWebView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        stripWebView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        stripWebView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        let heightAnchor = stripWebView.heightAnchor.constraint(equalTo: containerView.heightAnchor)
        heightAnchor.priority = .defaultLow
        heightAnchor.isActive = true

        self.containerView = containerView
        self.stripContainerViewConroller = containerViewConroller
    }

    /// Remove the channel carousel units view
    public func hide() {
        self.stripWebView.configuration.userContentController
            .unregister(from: [StripConfig.proxy])
        self.stripWebView.removeFromSuperview()
        self.storyWebView.configuration.userContentController
            .unregister(from: [StripConfig.proxy,
                           StripConfig.showStripStory,
                           StripConfig.hideStripStory])
        self.storyWebView.removeFromSuperview()
    }

    deinit {
        hide()
    }
}

// MARK:- UserContentController Script Messages Handle
@available(iOS 11.0, *)
private extension APEStripView {
    func handleUserContentController(message: WKScriptMessage) {
        if let bodyString = message.body as? String {
            if message.webView?.hash == stripWebView.hash {
                handleStripWebViewMessages(bodyString)
            } else if message.webView?.hash == storyWebView.hash {
                handleStoryWebViewMessages(bodyString)
            }
        }
    }

    func handleStripWebViewMessages(_ bodyString: String) {
        if bodyString.contains(StripConfig.initial) {
            self.loadingState.initialMessage = bodyString

        } else if bodyString.contains(StripConfig.loaded) {
            if let superView = stripWebView.superview, storyWebView.superview == nil {
                superView.insertSubview(storyWebView, belowSubview: stripWebView)
            }
            self.loadingState.isLoaded = true
            // get unit height
            if let dictioanry = bodyString.dictionary,
                let heightString = dictioanry[StripConfig.stripHeight] as? String,
                let height = Float(string: heightString) {

                let adjustedContentInsets = self.stripWebView.scrollView.adjustedContentInset.bottom + self.stripWebView.scrollView.adjustedContentInset.top
                self.loadingState.height = height + Float(adjustedContentInsets)
                self.updateStripComponentHeight(self.height)
            }
            // update the delegate on success
            self.delegate?.stripView(didFinishLoadingChannelToken: self.configuration.channelToken)

        } else if bodyString.contains(StripConfig.open) {
            guard self.loadingState.isReady else {
                self.loadingState.openUnitMessage = bodyString
                return
            }
            self.messagesTracker.sendApesterEvent(message: bodyString, to: storyWebView) { _ in
                self.displayStoryComponent()
            }
        }  else if bodyString.contains(StripConfig.destroy) {
            // update the delegate on fail or hide if needed
            if let delegate = self.delegate {
                delegate.stripView(didFailLoadingChannelToken: self.configuration.channelToken)
            } else {
                self.hide()
            }
        }
        // proxy updates
        if self.messagesTracker.canSendApesterEvent(message: bodyString, to: storyWebView) {
            self.messagesTracker.sendApesterEvent(message: bodyString, to: storyWebView)
        }
    }

    func updateStripComponentHeight(_ height: CGFloat) {
        self.containerView.flatMap { containerView in
            // Auto Layout
            let heightAnchor = stripWebView.heightAnchor.constraint(equalToConstant: height)
            heightAnchor.priority = .defaultHigh
            heightAnchor.isActive = true
        }
        self.delegate?.stripView(didUpdateHeight: height)
    }

    func handleStoryWebViewMessages(_ bodyString: String) {
        if bodyString.contains(StripConfig.isReady) {
            self.loadingState.isReady = true

            // send openUnitMessage if needed
            if let openUnitMessage = self.loadingState.openUnitMessage {
                self.messagesTracker.sendApesterEvent(message: openUnitMessage, to: storyWebView) { _ in
                    self.loadingState.openUnitMessage = nil
                }
            }

        } else if bodyString.contains(StripConfig.next) {
            if self.loadingState.initialMessage != nil {
                self.loadingState.initialMessage = nil
            }

        } else if (bodyString.contains(StripConfig.off) || bodyString.contains(StripConfig.destroy)) {
            self.hideStoryComponent()
        }
        
        // proxy updates
        if self.messagesTracker.canSendApesterEvent(message: bodyString, to: stripWebView) {
            self.messagesTracker.sendApesterEvent(message: bodyString, to: stripWebView)
        }
    }

    func displayStoryComponent() {
        self.lastDeviceOrientation = UIDevice.current.orientation
        if !self.lastDeviceOrientation.isPortrait, self.lastDeviceOrientation != .unknown {
            setDeviceOrientation(UIInterfaceOrientation.portrait.rawValue)
        }
        self.stripContainerViewConroller?.present(self.stripStoryViewController, animated: true, completion: nil)
    }

    func hideStoryComponent() {
        self.stripStoryViewController.dismiss(animated: false) {
            if !self.lastDeviceOrientation.isPortrait, self.lastDeviceOrientation != .unknown {
                self.setDeviceOrientation(self.lastDeviceOrientation.rawValue)
            }
        }
    }

    func setDeviceOrientation(_ rawValue: Int) {
        UIDevice.current.setValue(rawValue, forKey: "orientation")
    }
}

// MARK:- WKScriptMessageHandler
@available(iOS 11.0, *)
extension APEStripView: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        DispatchQueue.main.async {
            self.handleUserContentController(message: message)
        }
    }
}

// MARK:- WKNavigationDelegate
@available(iOS 11.0, *)
extension APEStripView: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let initialMessage = self.loadingState.initialMessage {
            self.messagesTracker.sendApesterEvent(message: initialMessage, to: self.storyWebView) { _ in
                self.loadingState.initialMessage = nil
            }
        }
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        var policy = WKNavigationActionPolicy.cancel
        defer {
            decisionHandler(policy)
        }
        guard let url = navigationAction.request.url else { return }
        func presentSFSafariViewController() {
            guard url.scheme != nil else { return }
            let presntedVC = self.stripContainerViewConroller?.presentedViewController ?? self.stripContainerViewConroller
            presntedVC?.present(SFSafariViewController(url: url), animated: true, completion: nil)
        }
        switch navigationAction.navigationType {
        case .other, .reload, .backForward:
            if let host = url.host, host.contains(APEConfig.Strip.apester) {
                policy = .allow
            } else if (url.absoluteString != APEConfig.Strip.blank && !url.absoluteString.contains(APEConfig.Strip.safeframe)) {
                presentSFSafariViewController()
            }
        case .linkActivated:
            presentSFSafariViewController()
        default: break
        }
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        guard let response = navigationResponse.response as? HTTPURLResponse,
            let url = navigationResponse.response.url else {
                decisionHandler(.cancel)
                return
        }
        if let headerFields = response.allHeaderFields as? [String: String] {
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
            cookies.forEach { cookie in
                webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
            }
        }
        decisionHandler(.allow)
    }
}

#endif
