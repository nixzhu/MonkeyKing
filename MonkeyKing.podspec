Pod::Spec.new do |s|

  s.name        = "MonkeyKing"
  s.version     = "1.4.0"
  s.summary     = "MonkeyKing helps you to post messages to Chinese Social Networks, or do OAuth."

  s.description = <<-DESC
                   You just want to share some information to WeChat, QQ, ...
                   Why use their buggy SDKs?
                   DESC

  s.homepage    = "https://github.com/nixzhu/MonkeyKing"

  s.license     = { :type => "MIT", :file => "LICENSE" }

  s.authors           = { "nixzhu" => "zhuhongxu@gmail.com" }
  s.social_media_url  = "https://twitter.com/nixzhu"

  s.ios.deployment_target   = "8.0"

  s.source          = { :git => "https://github.com/nixzhu/MonkeyKing.git", :tag => s.version }
  s.source_files    = "Sources/*.swift"
  s.requires_arc    = true

end
