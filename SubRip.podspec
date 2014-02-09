Pod::Spec.new do |s|

  s.name         = "SubRip for Mac"
  s.version      = "1.0.0"
  s.summary      = "An Objective-C parser for SRT files."
  s.homepage     = "https://github.com/sstigler/SubRip-for-Mac"
  s.license      = { :type => 'BSD', :file => 'LICENSE' }
  s.authors		 = { "Sam Stigler" => "sstigler1985@mac.com", "Jan Weiß" => '' }
  s.platform     = :osx, '10.7';
  s.source       = { :git => "git@github.com:sstigler/SubRip-for-Mac.git", :tag => "1.0.0" }
  s.source_files = 'SubRip/**/*', 'TagSupport/**/*', 'External/**/*'
  s.private_header_files = 'TagSupport/**/*.h', 'External/**/*.h'
  s.framework  = 'CoreMedia'
  s.requires_arc = false
  s.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) SUBRIP_TAG_SUPPORT=1 SUBRIP_SUBVIEWER_SUPPORT=1' }

end
