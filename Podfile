source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!

abstract_target 'PIALibrary' do
    pod 'SwiftyBeaver', '~> 1.4'
    pod 'Gloss', '~> 2'
    pod 'Alamofire', '~> 4'
    pod 'ReachabilitySwift'
    #pod 'PIATunnel', :git => 'https://github.com/pia-foss/tunnel-apple.git', :commit => 'dfe7f3c'
    pod 'PIATunnel', '~> 1.1.3'

    target 'PIALibrary-iOS' do
        platform :ios, '9.0'
    end
    target 'PIALibraryTests-iOS' do
        platform :ios, '9.0'
    end
    target 'PIALibraryHost-iOS' do
        platform :ios, '9.0'
    end

    #target 'PIALibrary-macOS' do
    #    platform :osx, '10.11'
    #end
    #target 'PIALibraryTests-macOS' do
    #    platform :osx, '10.11'
    #end
end
