//
//  APEUnitConfiguration.swift
//  ApesterKit
//
//  Created by Almog Haimovitch on 10/03/2020.
//  Copyright © 2020 Apester. All rights reserved.
//

import UIKit

public enum APEUnitParams {
    case unit(mediaId: String)
    case playlist(tags: [String], channelToken: String, context: Bool, fallback: Bool)

    public var id: String {
        switch self {
        case .unit(let mediaId):
            return mediaId
        case .playlist( _, let channelToken, _, _):
            return channelToken
        }
    }
}

@objcMembers public class APEUnitConfiguration: APEConfiguration {
    
    private enum Keys: String {
        case tags = "tags"
        case baseUrl = "baseUrl"
        case mediaId = "mediaId"
        case context = "context"
        case fallback = "fallback"
        case gdprString = "gdprString"
        case channelToken = "channelToken"
        case noApesterAds = "noApesterAds"
        case cachedVersion = "cachedVersion"
    }
    
    public private(set) var unitParams: APEUnitParams
    
    public var gdprString: String?
    
    private(set) var id: String = ""
    private(set) var baseUrl: String?
    private(set) var hideApesterAds: Bool
    
    override var parameters: [String: String] {
        var value = super.parameters
        switch self.unitParams {
        case .unit(let mediaId):
            value[Keys.mediaId.rawValue] = mediaId
        case .playlist(let tags, let channelToken, let context, let fallback):
            value[Keys.channelToken.rawValue] = channelToken
            value[Keys.context.rawValue] = "\(context)"
            value[Keys.fallback.rawValue] = "\(fallback)"
            value[Keys.tags.rawValue] = tags.joined(separator:",")
        }
        value[Keys.noApesterAds.rawValue] = "\(self.hideApesterAds)"
        if let gdprString = self.gdprString {
            value[Keys.gdprString.rawValue] = "\(gdprString)"
        }
        return value
    }
    
    var unitURL: URL? {
        let baseUrl = self.baseUrl ?? self.environment.unitBaseUrl + Constants.Unit.unitPath
        let components = URLComponents(string: baseUrl)
        return components?.url
    }
    
    public init(unitParams: APEUnitParams, bundle: Bundle, hideApesterAds: Bool, gdprString: String?, baseUrl: String?, environment: APEEnvironment) {
        self.unitParams = unitParams
        self.hideApesterAds = hideApesterAds
        self.gdprString = gdprString
        self.baseUrl = baseUrl
        super.init(bundle: bundle, environment: environment)
    }
    
    public convenience init(unitParams: APEUnitParams, bundle: Bundle) {
        self.init(unitParams: unitParams, bundle: bundle, hideApesterAds: false, gdprString: nil, baseUrl: nil, environment: .production)
    }
    
    public convenience init(unitParams: APEUnitParams, bundle: Bundle, hideApesterAds: Bool) {
           self.init(unitParams: unitParams, bundle: bundle, hideApesterAds: hideApesterAds, gdprString: nil, baseUrl: nil, environment: .production)
    }
    
    public convenience init(unitParams: APEUnitParams, bundle: Bundle, gdprString: String) {
        self.init(unitParams: unitParams, bundle: bundle, hideApesterAds: false, gdprString: gdprString, baseUrl: nil, environment: .production)
    }
    
    public convenience init(unitParams: APEUnitParams, bundle: Bundle, baseUrl: String) {
        self.init(unitParams: unitParams, bundle: bundle, hideApesterAds: false, gdprString: nil, baseUrl: baseUrl, environment: .production)
    }
    
    public convenience init(unitParams: APEUnitParams, bundle: Bundle, hideApesterAds: Bool, baseUrl: String) {
        self.init(unitParams: unitParams, bundle: bundle, hideApesterAds: hideApesterAds, gdprString: nil, baseUrl: baseUrl, environment: .production)
    }
    
    public convenience init(unitParams: APEUnitParams, bundle: Bundle, gdprString: String, baseUrl: String) {
        self.init(unitParams: unitParams, bundle: bundle, hideApesterAds: false, gdprString: gdprString, baseUrl: baseUrl, environment: .production)
    }
    
    public convenience init(unitParams: APEUnitParams, bundle: Bundle, hideApesterAds: Bool, gdprString: String, baseUrl: String) {
        self.init(unitParams: unitParams, bundle: bundle, hideApesterAds: hideApesterAds, gdprString: gdprString, baseUrl: baseUrl, environment: .production)
    }
    
    @objc public convenience init(mediaId: String, bundle: Bundle) {
        self.init(unitParams: .unit(mediaId: mediaId),
                  bundle: bundle)
    }
    
    @objc public convenience init(mediaId: String, bundle: Bundle, hideApesterAds: Bool) {
        self.init(unitParams: .unit(mediaId: mediaId),
                  bundle: bundle, hideApesterAds: hideApesterAds)
    }
    
    @objc public convenience init(mediaId: String, bundle: Bundle, gdprString: String) {
        self.init(unitParams: .unit(mediaId: mediaId),
                  bundle: bundle, gdprString: gdprString)
    }
    
    @objc public convenience init(mediaId: String, bundle: Bundle, baseUrl: String) {
        self.init(unitParams: .unit(mediaId: mediaId),
                  bundle: bundle, baseUrl: baseUrl)
    }
    
    @objc public convenience init(mediaId: String, bundle: Bundle, hideApesterAds: Bool, baseUrl: String) {
        self.init(unitParams: .unit(mediaId: mediaId),
                  bundle: bundle, hideApesterAds: hideApesterAds, baseUrl: baseUrl)
    }
    
    @objc public convenience init(mediaId: String, bundle: Bundle, hideApesterAds: Bool, gdprString: String, baseUrl: String) {
        self.init(unitParams: .unit(mediaId: mediaId),
                  bundle: bundle, hideApesterAds: hideApesterAds, gdprString: gdprString, baseUrl: baseUrl)
    }

    @objc public convenience init(tags: [String], channelToken: String, context: Bool, fallback: Bool, bundle: Bundle) {
        self.init(unitParams: .playlist(tags: tags, channelToken: channelToken, context: context, fallback: fallback),
                  bundle: bundle)
    }
    
    @objc public convenience init(tags: [String], channelToken: String, context: Bool, fallback: Bool, bundle: Bundle, hideApesterAds: Bool) {
        self.init(unitParams: .playlist(tags: tags, channelToken: channelToken, context: context, fallback: fallback),
                  bundle: bundle, hideApesterAds:  hideApesterAds)
    }
    
    @objc public convenience init(tags: [String], channelToken: String, context: Bool, fallback: Bool, bundle: Bundle, gdprString: String) {
        self.init(unitParams: .playlist(tags: tags, channelToken: channelToken, context: context, fallback: fallback),
                  bundle: bundle, gdprString:  gdprString)
    }
    
    @objc public convenience init(tags: [String], channelToken: String, context: Bool, fallback: Bool, bundle: Bundle, baseUrl: String) {
        self.init(unitParams: .playlist(tags: tags, channelToken: channelToken, context: context, fallback: fallback),
                  bundle: bundle, baseUrl:  baseUrl)
    }
    
    @objc public convenience init(tags: [String], channelToken: String, context: Bool, fallback: Bool, bundle: Bundle, gdprString: String, baseUrl: String) {
        self.init(unitParams: .playlist(tags: tags, channelToken: channelToken, context: context, fallback: fallback),
                  bundle: bundle, gdprString: gdprString, baseUrl:  baseUrl)
    }
    
    @objc public convenience init(tags: [String], channelToken: String, context: Bool, fallback: Bool, bundle: Bundle, hideApesterAds: Bool, baseUrl: String) {
        self.init(unitParams: .playlist(tags: tags, channelToken: channelToken, context: context, fallback: fallback),
                  bundle: bundle, hideApesterAds: hideApesterAds, baseUrl:  baseUrl)
    }
    
    @objc public convenience init(tags: [String], channelToken: String, context: Bool, fallback: Bool, bundle: Bundle, hideApesterAds: Bool, gdprString: String, baseUrl: String) {
        self.init(unitParams: .playlist(tags: tags, channelToken: channelToken, context: context, fallback: fallback),
                  bundle: bundle, hideApesterAds: hideApesterAds, gdprString: gdprString, baseUrl:  baseUrl)
    }
    
}
