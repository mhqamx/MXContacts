#
# Be sure to run `pod lib lint MXContacts.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MXContacts'
  s.version          = '1.0.0'
  s.summary          = '联系人库'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
                      系统联系人操作公用库
                       DESC

  s.homepage         = 'https://github.com/mhqamx/MXContacts'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'mhqamx' => 'maxiao@seaway.net.cn' }
  s.source           = { :git => 'https://github.com/mhqamx/MXContacts.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'MXContacts/Classes/**/*'
  
  # s.resource_bundles = {
  #   'MXContacts' => ['MXContacts/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = "AddressBook", "Contacts"
  # s.dependency 'AFNetworking', '~> 2.3'
end
