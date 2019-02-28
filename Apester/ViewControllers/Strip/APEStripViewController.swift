//
//  APEStripViewController.swift
//  ApisterKitDemo
//
//  Created by Hasan Sa on 24/02/2019.
//  Copyright © 2019 Apester. All rights reserved.
//

import UIKit
import WebKit
import ApesterKit

class APEStripViewController: UIViewController {

  private var storyViewController: APEStripStoryViewController?
  private let stripServiceInstance = APEStripService(channelToken: "5890a541a9133e0e000e31aa", bundle:  Bundle.main)
  private var stripWebView: WKWebView?

  override func viewDidLoad() {
    super.viewDidLoad()
    self.stripServiceInstance.dataSource = self
    self.stripServiceInstance.delegate = self
    setupStripComponent()
    // display loading view
  }
}

private extension APEStripViewController {
  func setupStripComponent() {
    self.stripWebView = self.stripServiceInstance.stripWebView
    stripWebView!.frame = self.view.bounds
    self.view.addSubview(stripWebView!)
  }
}

extension APEStripViewController: APEStripServiceDataSource {
  var showStoryFunction: String {
    return "console.log('show story');"
  }

  var hideStoryFunction: String {
    return "console.log('hdie story');"
  }
}

extension APEStripViewController: APEStripServiceDelegate {
  func stripComponentIsReady(unitHeight height: CGFloat) {
    self.stripWebView?.frame.size.height = height
    /// hide loading
    print(#function)
  }

  func displayStoryComponent() {
    if self.storyViewController == nil {
      self.storyViewController = APEStripStoryViewController()
      self.storyViewController?.webView = self.stripServiceInstance.storyWebView
    }

    self.navigationController?.pushViewController(self.storyViewController!, animated: true)
  }

  func hideStoryComponent() {
    self.storyViewController?.navigationController?.popViewController(animated: true)
  }
}
