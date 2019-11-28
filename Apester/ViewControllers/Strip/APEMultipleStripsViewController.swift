//
//  APEMultipleStripsViewController.swift
//  ApisterKitDemo
//
//  Created by Hasan Sa on 24/02/2019.
//  Copyright © 2019 Apester. All rights reserved.
//

import UIKit
import WebKit
import ApesterKit

class APEMultipleStripsViewController: UIViewController {

    @IBOutlet private weak var collectionView: UICollectionView!

    private var stripViewsData: [String: APEStripView] = [:]
    private lazy var style: APEStripStyle = {
        let header = APEStripHeader(text: "Title", size: 25.0, family: nil, weight: 400, color: .darkText)
        return APEStripStyle(shape: .roundSquare, size: .medium,
                             padding: UIEdgeInsets(top: 5.0, left: 0, bottom: 0, right: 0),
                             shadow: false, textColor: nil, background: nil, header: header)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        let env: APEEnvironment = .production
        self.stripViewsData = env.tokens.reduce(into: [:], {
            if let configuration = try? APEStripConfiguration(channelToken: $1,
                                                              style: style,
                                                              bundle: Bundle.main, environment: env) {
                // create the StripService Instance
                let stripView = APEStripView(configuration: configuration)
                stripView.delegate = self
                $0[$1] = stripView
            }
        })
    }
}

extension APEMultipleStripsViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.stripViewsData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ReuseCellIdentifier", for: indexPath) as! APEStripCollectionViewCell
        guard indexPath.row < self.stripViewsData.values.count else {
            return cell
        }
        let stripView = Array(self.stripViewsData.values)[indexPath.row]
        cell.show(stripView: stripView, containerViewConroller: self)
        return cell
    }
}

extension APEMultipleStripsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard indexPath.row < self.stripViewsData.values.count else { return .zero }
        let stripView = Array(self.stripViewsData.values)[indexPath.row]
        return CGSize(width: collectionView.bounds.width, height: stripView.height)
    }
}

extension APEMultipleStripsViewController: APEStripViewDelegate {

    func stripView(_ stripView: APEStripView, didUpdateHeight height: CGFloat) {
        self.collectionView.reloadData()
    }

    func stripView(_ stripView: APEStripView, didFinishLoadingChannelToken token: String) {}

    func stripView(_ stripView: APEStripView, didFailLoadingChannelToken token: String) {
        DispatchQueue.main.async {
            self.stripViewsData[stripView.configuration.channelToken] = nil
            self.collectionView.reloadData()
        }
    }
}

extension APEEnvironment {
    var tokens: [String] {
        switch self {
        case .production:
            return ["5ad092c7e16efe4e5c4fb821", "58ce70315eeaf50e00de3da7", "5aa15c4f85b36c0001b1023c"]
        case .stage:
            return ["58c551f76a67357e3b4aa943"]
        }
    }
}

extension APEStripConfiguration {
    @objc static var tokens: [String] { APEEnvironment.production.tokens }
}