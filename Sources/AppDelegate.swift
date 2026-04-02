// AppDelegate.swift
// 标准 UIKit 入口，兼容 iOS 10（不使用 UIScene）

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let vc = DashboardViewController()

        // 检查启动参数：-demo 或环境变量 MERACH_DEMO=1
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-demo") || ProcessInfo.processInfo.environment["MERACH_DEMO"] == "1" {
            vc.demoMode = true
        }

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = vc
        window?.makeKeyAndVisible()
        return true
    }
}
