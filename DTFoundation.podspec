Pod::Spec.new do |spec|
  spec.name         = 'DTFoundation'
  spec.version      = '1.0.0'
  spec.summary      = "Standard toolset classes and categories"
  spec.homepage     = "https://github.com/Cocoanetics/DTFoundation"
  spec.author       = { "Oliver Drobnik" => "oliver@drobnik.com" }
  spec.source       = { :git => "https://github.com/Cocoanetics/DTFoundation.git", :tag => spec.version }

  spec.ios.deployment_target = '5.0'
  spec.osx.deployment_target = '10.6'
  spec.requires_arc = true

  spec.subspec 'Core' do |ss|
    ss.source_files = 'Core/Source/*.{h,m}'
    ss.ios.source_files = 'Core/Source/iOS/*.{h,m}'
    ss.osx.source_files = 'Core/Source/OSX/*.{h,m}'
  end

  spec.subspec 'DTHMLParser' do |ss|
    ss.library = 'xml2'
    ss.source_files = 'Core/DTHMLParser/*.{h,m}'

    ss.dependency 'DTFoundation/Core'
  end

  spec.subspec 'DTZipArchive' do |ss|
    ss.source_files = 'Core/Source/DTZipArchive/*.{h,m}'
  end

  spec.subspec 'DTDownloadChache' do |ss|
    ss.platform = :ios
    ss.source_files = 'DTDownloadChache/DTHMLParser/*.{h,m}'
  end

  spec.subspec 'DTBonjour' do |ss|
    ss.platform = :ios
    ss.source_files = 'DTBonjour/DTHMLParser/*.{h,m}'
  end

  spec.subspec 'DTUTI' do |ss|
    ss.source_files = 'Core/Source/DTUTI/*.{h,m}'
  end
end
