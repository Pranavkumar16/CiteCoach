import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var llmPlugin: LlmPlugin?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

        // Register LLM plugin after Flutter engine is ready
        if let controller = window?.rootViewController as? FlutterViewController {
            llmPlugin = LlmPlugin()
            llmPlugin?.register(with: controller.binaryMessenger)
        }

        return result
    }

    override func applicationWillTerminate(_ application: UIApplication) {
        llmPlugin?.dispose()
    }
}
