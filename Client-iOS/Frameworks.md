#  Required Frameworks

This project uses several third-party frameworks. Most of them are installed via Carthage, but some require manual actions due to different reasons.

## Frameworks via Carthage
* Be sure to have [Carthage](https://github.com/Carthage/Carthage#installing-carthage) installed on your machine
* Run ``` carthage update ```
* Drag the frameworks from Carthage/Build to the "Linked Frameworks and Libraries" in Xcode (probably already done)
* There should be a Carthage Building Phase on the main app target, all Frameworks should be listed as Input Files  (please check)

## Additional Frameworks
### WebRTC
The WebRTC installation is quite fucked-up. [See full process here](https://webrtc.org/native-code/ios/). Basically there is no pre-compiled version available online. We can't use Carthage either. So we're compiling it ourself. This process takes quite a while. [See the documentation by Google on how to do it.](https://webrtc.org/native-code/ios/). Use the Xcode project in ``` out/ios/all.xcworkspace ``` to compile the framework_objc target. This results in the ``` WebRTC.framework ```, which we're adding to our Xcode project like we did with Carthage (there is no additional Building Phase/declaration as Input File required, as it has nothing to do with Carthage). I suggest copying the compiled framework to ``` Carthage/Build/iOS ``` - before adding it to the target - to store it at the same place as the other frameworks.

### Realm
Due to whatever reason Carthage throws an error when compiling Realm, because it's not Swift 4.2 compatible. So we're installing the framework directly. [See process here](https://realm.io/docs/swift/latest/#dynamic-install). It's pretty simple as there are pre-compiled versions. Download them (currently tested version: Realm Swift 3.11.1). Copy the ``` RealmSwift.framework ``` and ``` Realm.framework ``` to the ``` Carthage/Build/iOS ``` folder as well, because why not. By doing so the project setup keeps the same so you don't need to change anything. And it should just work.
