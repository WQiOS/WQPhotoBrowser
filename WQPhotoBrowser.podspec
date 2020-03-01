
Pod::Spec.new do |s|

s.name         = "WQPhotoBrowser"
s.version      = "0.0.7"
s.summary      = "一款图片放大浏览器，支持收拾放大缩小、长按保存到相册"
s.homepage     = "https://github.com/WQiOS/WQPhotoBrowser"
s.license      = "MIT"
s.author       = { "wangqiang" => "1570375769@qq.com" }
s.platform     = :ios, "8.0" #平台及支持的最低版本
s.requires_arc = true # 是否启用ARC
s.source       = { :git => "https://github.com/WQiOS/WQPhotoBrowser.git", :tag => "#{s.version}" }
s.ios.framework  = 'UIKit'
s.source_files  = "WQPhotoBrowser/*.{h,m}"

s.dependency 'SDWebImage'
s.ios.frameworks = 'Photos','CoreGraphics'

end
