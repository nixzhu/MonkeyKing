Pod::Spec.new do |s|

  s.name        = "MonkeyKing"
  s.version     = "0.0.1"
  s.summary     = "MonkeyKing help you post message to Chinese Social Network."

  s.description = <<-DESC
                   You just want to share some information to WeChat, ...
                   Why use the buggy third party SDKs?
                   DESC

  s.homepage    = "https://github.com/nixzhu/MonkeyKing"

  s.license     = { :type => "MIT", :file => "LICENSE" }

  s.authors           = { "nixzhu" => "zhuhongxu@gmail.com" }
  s.social_media_url  = "https://twitter.com/nixzhu"

  s.ios.deployment_target   = "8.0"
  # s.osx.deployment_target = "10.7"

  s.source          = { :git => "https://github.com/nixzhu/MonkeyKing.git", :tag => s.version }
  s.source_files    = "MonkeyKing/*.swift"
  s.requires_arc    = true

end
