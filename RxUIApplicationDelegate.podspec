Pod::Spec.new do |s|
  s.name             = 'RxUIApplicationDelegate'
  s.version          = '0.1.1'
  s.summary          = 'UIApplicationDelegate with a declarative input/output interface.'

  s.description      = 'RxUIApplicationDelegate serves as an application delegate while providing a declarative means of input (render(model: Model)) and output (RxSwift.Observable<Model>).'

  s.homepage         = 'https://github.com/brian.semiglia@gmail.com/RxUIApplicationDelegate'
  # s.screenshots    = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
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
  s.source_files = 'RxUIApplicationDelegate/Classes/**/*'
  s.dependency 'RxSwift', '~> 4.0'
  s.dependency 'Changeset', '3.1'
end
