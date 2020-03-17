//
//  ViewController.swift
//  Apester
//
//  Created by Almog Haimovitch on 09/03/2020.
//  Copyright © 2020 Apester. All rights reserved.
//

import UIKit
import ApesterKit

class APEUnitViewController: UIViewController {
    
    var apesterUnitView: APEUnitView!
    let configuration = try? APEUnitConfiguration(unitParams: APEUnitParams.unit(mediaId: "5e6fa2351d18fd8580776612"),
                                                  bundle: Bundle.main, environment: .stage)
    
//    let configuration = try? APEUnitConfiguration(unitParams: APEUnitParams.playlist(tags: ["yo", "bo", "ho"], channelToken: "5d6fc15d07d512002b67ecc6", context: false, fallback: false), bundle: Bundle.main, environment: .local)
    
    private var unitsParams: [APEUnitParams] = UnitConfigurationsFactory.unitsParams
    
    @IBOutlet weak var unitContainerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let unitParams = unitsParams.first {
            // preLoad implemntation
            apesterUnitView = APEUnitsViewService.shared.unitView(for: unitParams)
        }
        
        if apesterUnitView == nil {
            // not preload!
            guard let unitConfig = configuration else { return }
            apesterUnitView = APEUnitView(configuration: unitConfig)

        }
        
        unitsParams.forEach {
            APEUnitsViewService.shared.unitView(for: $0)?.delegate = self
        }
        
        apesterUnitView.display(in: unitContainerView, containerViewConroller: self)

    }
    
}

extension APEUnitViewController: APEUnitViewDelegate {
    func unitView(_ unitView: APEUnitView, didFinishLoadingUnit mediaId: String) {
        
    }
    
    func unitView(_ unitView: APEUnitView, didFailLoadingUnit mediaId: String) {
        
    }
    
    func unitView(_ unitView: APEUnitView, didUpdateHeight height: CGFloat) {
        
    }
    
}
