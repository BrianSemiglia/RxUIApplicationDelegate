Pod::Spec.new do |s|
  s.name             = 'RxUIApplicationDelegate'
  s.version          = '0.1.1'
  s.summary          = 'UIApplicationDelegate with a declarative input/output interface.'
  s.description      = 'RxUIApplicationDelegate serves as an application delegate while providing declarative input/output.'
  s.homepage         = 'https://github.com/brian.semiglia@gmail.com/RxUIApplicationDelegate'
  s.license          = {
    :type => 'MIT',
    :file => 'LICENSE'
  }
  s.author           = { 'Brian Semiglia' => 'brian.semiglia@gmail.com' }
  s.source           = {
    :git => 'https://github.com/briansemiglia/RxUIApplicationDelegate.git',
    :tag => s.version.to_s
  }
  s.social_media_url = 'https://twitter.com/brians_'
  s.ios.deployment_target = '9.0'
  s.source_files = 'Core/**/*'
  s.dependency 'RxSwift', '~> 4.2.0'
  s.dependency 'Changeset', '3.1'
end
