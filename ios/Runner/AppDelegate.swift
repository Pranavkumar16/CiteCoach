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

        // Register LLM plugin
        if let controller = window?.rootViewController as? FlutterViewController {
            llmPlugin = LlmPlugin()
            llmPlugin?.register(with: controller.binaryMessenger)
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func applicationWillTerminate(_ application: UIApplication) {
        llmPlugin?.dispose()
    }
}
