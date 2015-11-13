<p>
<a href="http://cocoadocs.org/docsets/MonkeyKing"><img src="https://img.shields.io/cocoapods/v/MonkeyKing.svg?style=flat"></a> 
<a href="https://github.com/Carthage/Carthage/"><img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat"></a> 
</p>

# MonkeyKing

MonkeyKing helps you post messages to Chinese Social Networks, without their buggy SDKs.

MonkeyKing use the same analysis process of [openshare](https://github.com/100apps/openshare), support share **Text**, **URL**, **Image**, **Audio**, and **Video** to **WeChat**, **QQ** or **Weibo**. MonkeyKing also can post message to Weibo by webpage. (Note that Auido and Video are only specifically for WeChat or QQ)

One more thing: MonkeyKing supports **OAuth**.

## Requirements

Swift 2.0, iOS 8.0

## Example

Share to WeChat (微信)：

### Basic

1. In your Project Target's `Info.plist`, add URL Type as follow:

	![URL Scheme for WeChat](https://raw.githubusercontent.com/nixzhu/MonkeyKing/master/images/url_scheme_for_wechat.png)
	
	You need apply your own `appID` first, off course.
	
	If your App support iOS 9, you need set `LSApplicationQueriesSchemes` in your `Info.plist`:
	
	```xml
	<key>LSApplicationQueriesSchemes</key>
	<array>
		<string>weixin</string>
	</array>
	```
	
	Your app check if can open WeChat will need it.
	
	If your App support iOS 9, you need set `NSAppTransportSecurity` in your `Info.plist`:
	
	
	```xml
	<dict>
		<key>NSExceptionDomains</key>
		<dict>
			<key>api.weibo.com</key>
			<dict>
				<key>NSIncludesSubdomains</key>
				<true/>
				<key>NSThirdPartyExceptionMinimumTLSVersion</key>
				<string>TLSv1.0</string>
				<key>NSThirdPartyExceptionRequiresForwardSecrecy</key>
				<false/>
			</dict>
		</dict>
	</dict>
	```
	
	
	Just like fellow:
	
	![URL Scheme for WeChat](https://raw.githubusercontent.com/nixzhu/MonkeyKing/master/images/AppTransportSecurity.png)
	
	
	
2. Prepare your message and share it:

	```swift
    @IBAction func shareURLToWeChatSession(sender: UIButton) {

        MonkeyKing.registerAccount(.WeChat(appID: weChatAppID))

        let message = MonkeyKing.Message.WeChat(.Session(info: (
            title: "Session",
            description: "Hello Session",
            thumbnail: UIImage(named: "rabbit"),
            media: .URL(NSURL(string: "http://www.apple.com/cn")!)
        )))

        MonkeyKing.shareMessage(message) { success in
            print("shareURLToWeChatSession success: \(success)")
        }
    }
	```
	
3. If you need handle call back, add following code

	```swift
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {

        if MonkeyKing.handleOpenURL(url) {
            return true
        }

        return false
    }
	```
	
	to your AppDelegate.
	
It's done!

If you don't want to register account before share each time, you may do it in AppDelegate like follow:
	
```swift
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

    MonkeyKing.registerAccount(.WeChat(appID: "wxd930ea5d5a258f4f"))

    return true
}
```

### OAuth

Weibo OAuth:

```swift
let account = MonkeyKing.Account.Weibo(appID: weiboAppID, appKey: weiboAppKey, redirectURL: weiboRedirectURL)

MonkeyKing.OAuth(account) { (OAuthInfo, response, error) -> Void in
    print("OAuthInfo \(OAuthInfo) error \(error)")
    // Now, you can use the token to fetch info.
}
```
	 
If user do not installed Weibo App on their devices, MonkeyKing will use web OAuth:
	 
![weiboOAuth](https://raw.githubusercontent.com/nixzhu/MonkeyKing/master/images/wbOAuth.png)


### More

If you like use `UIActivityViewController` to share, MonkeyKing has `AnyActivity` can help you. 

![System Share](https://raw.githubusercontent.com/nixzhu/MonkeyKing/master/images/system_share.jpg)

Check the demo for more information.

## Installation

It's recommended to use CocoaPods or Carthage.

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects.

CocoaPods 0.36 adds supports for Swift and embedded frameworks. You can install it with the following command:

```bash
$ [sudo] gem install cocoapods
```

To integrate MonkeyKing into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'MonkeyKing', '~> 0.6.6'
```

Then, run the following command:

```bash
$ pod install
```

You should open the `{Project}.xcworkspace` instead of the `{Project}.xcodeproj` after you installed anything from CocoaPods.

For more information about how to use CocoaPods, I suggest [this tutorial](http://www.raywenderlich.com/64546/introduction-to-cocoapods-2).

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager for Cocoa application. To install the carthage tool, you can use [Homebrew](http://brew.sh).

```bash
$ brew update
$ brew install carthage
```

To integrate MonkeyKing into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "nixzhu/MonkeyKing" >= 0.6.6
```

Then, run the following command to build the MonkeyKing framework:

```bash
$ carthage update
```

At last, you need to set up your Xcode project manually to add the MonkeyKing framework.

On your application targets’ “General” settings tab, in the “Linked Frameworks and Libraries” section, drag and drop each framework you want to use from the Carthage/Build folder on disk.

On your application targets’ “Build Phases” settings tab, click the “+” icon and choose “New Run Script Phase”. Create a Run Script with the following content:

```
/usr/local/bin/carthage copy-frameworks
```

and add the paths to the frameworks you want to use under “Input Files”:

```
$(SRCROOT)/Carthage/Build/iOS/MonkeyKing.framework
```

For more information about how to use Carthage, please see its [project page](https://github.com/Carthage/Carthage).

## Contact

NIX [@nixzhu](https://twitter.com/nixzhu) or 
Limon [@LimonTop](http://weibo.com/u/1783821582)

## Credits

WeChat logos from [WeChat-Logo](https://github.com/RayPS/WeChat-Logo) by Ray.

## License

MonkeyKing is available under the [MIT License][mitLink] license. See the LICENSE file for more info.
[mitLink]:http://opensource.org/licenses/MIT
