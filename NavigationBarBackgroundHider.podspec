Pod::Spec.new do |s|
    s.name             = 'NavigationBarBackgroundHider'
    s.version          = '1.0.0'
    s.summary          = 'Automatically hide a navigation bars background on scrolling'
    s.homepage         = 'https://github.com/AndreasVerhoeven/NavigationBarBackgroundHider'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'Andreas Verhoeven' => 'cocoapods@aveapps.com' }
    s.source           = { :git => 'https://github.com/AndreasVerhoeven/NavigationBarBackgroundHider.git', :tag => s.version.to_s }
    s.module_name      = 'NavigationBarBackgroundHider'

    s.swift_versions = ['5.0']
    s.ios.deployment_target = '13.0'
    s.source_files = 'Sources/*.swift'
end
