Pod::Spec.new do |s|
 s.name = 'ApesterKit'
 s.version = '3.0.5'
 s.swift_version = '5.0'
 s.license = { :type => "MIT", :file => "LICENSE" }
 s.summary = 'ApesterKit provides a light-weight framework that loads Apester Unit in a webView'
 s.homepage = 'https://github.com/Qmerce/ios-sdk.git'
 s.social_media_url = 'https://twitter.com/hasan_w_sa'
 s.authors = { "Hasan Sa" => "hasan@apester.com" }
 s.source = { :git => "https://github.com/Qmerce/ios-sdk.git", :tag => "v"+s.version.to_s }
 s.platforms     = { :ios => "11.0" }
 s.requires_arc = true
 s.source_files = "ApesterKit", "Sources/*.{h,m,swift}", "Sources/*/*.{h,m,swift}"
# s.resource_bundles = {
#   'ApesterKit' => ['Sources/ApesterKit.bundle/*']
#  }

end
