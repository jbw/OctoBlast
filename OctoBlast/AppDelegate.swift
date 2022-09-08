//
//  AppDelegate.swift
//  OctoBlast
//
//  Created by Jason Watson on 16/08/2022.
//

import Foundation
import OctoKit
import Sparkle
import SwiftUI
import UserNotifications

let UPDATE_NOTIFICATION_IDENTIFIER = "UpdateCheck"

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate, SPUUpdaterDelegate, SPUStandardUserDriverDelegate {
    @IBOutlet var updaterController: SPUStandardUpdaterController!

    private var personalAccessTokenManager: AuthAccessToken! = AuthAccessToken.shared
    private var github: GitHub!
    private var auth: GithubOAuth! = GithubOAuth.shared
    private var notificationCount = 0
    private var open: NSMenuItem = .init(title: "Open (0)", action: #selector(onOpen), keyEquivalent: "O")

    var timer: Timer?

    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        setupMenu()
        setupAutoRefresh()
        refresh()
    }

    func application(_: NSApplication, open urls: [URL]) {
        auth.handleOAuthCallback(url: urls[0], completion: { tokenConfig, _ in
            let token: String = tokenConfig.accessToken!
            if let decodedData = Data(base64Encoded: token) {
                let decodedString = String(data: decodedData, encoding: .utf8)!
                self.personalAccessTokenManager.setOAuthAccessToken(token: decodedString)
                self.github = GitHub(config: tokenConfig)
                self.refresh()
            }
        })
    }

    func application(_: NSApplication, openFile _: String) -> Bool {
        return false
    }

    // Request for permissions to publish notifications for update alerts
    // This delegate method will be called when Sparkle schedules an update check in the future,
    // which may be a good time to request for update permission. This will be after the user has allowed
    // Sparkle to check for updates automatically. If you need to publish notifications for other reasons,
    // then you may have a more ideal time to request for notification authorization unrelated to update checking.
    func updater(_: SPUUpdater, willScheduleUpdateCheckAfterDelay _: TimeInterval) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { _, _ in
            // Examine granted outcome and error if desired...
        }
    }

    // Declares that we support gentle scheduled update reminders to Sparkle's standard user driver
    var supportsGentleScheduledUpdateReminders: Bool {
        return true
    }

    func standardUserDriverWillHandleShowingUpdate(_: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState) {
        // When an update alert will be presented, place the app in the foreground
        // We will do this for updates the user initiated themselves too for consistency
        // When we later post a notification, the act of clicking a notification will also change the app
        // to have a regular activation policy. For consistency, we should do this if the user
        // does not click on the notification too.
        NSApp.setActivationPolicy(.regular)

        if !state.userInitiated {
            // And add a badge to the app's dock icon indicating one alert occurred
            NSApp.dockTile.badgeLabel = "1"

            // Post a user notification
            // For banner style notification alerts, this may only trigger when the app is currently inactive.
            // For alert style notification alerts, this will trigger when the app is active or inactive.
            do {
                let content = UNMutableNotificationContent()
                content.title = "A new update is available"
                content.body = "Version \(update.displayVersionString) is now available"

                let request = UNNotificationRequest(identifier: UPDATE_NOTIFICATION_IDENTIFIER, content: content, trigger: nil)

                UNUserNotificationCenter.current().add(request)
            }
        }
    }

    func standardUserDriverDidReceiveUserAttention(forUpdate _: SUAppcastItem) {
        // Clear the dock badge indicator for the update
        NSApp.dockTile.badgeLabel = ""

        // Dismiss active update notifications if the user has given attention to the new update
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [UPDATE_NOTIFICATION_IDENTIFIER])
    }

    func standardUserDriverWillFinishUpdateSession() {
        // Put app back in background when the user session for the update finished.
        // We don't have a convenient reason for the user to easily activate the app now.
        // Note this assumes there's no other windows for the app to show
        NSApp.setActivationPolicy(.accessory)
    }

    func userNotificationCenter(_: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.identifier == UPDATE_NOTIFICATION_IDENTIFIER, response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            // If the notification is clicked on, make sure we bring the update in focus
            // If the app is terminated while the notification is clicked on,
            // this will launch the application and perform a new update check.
            // This can be more likely to occur if the notification alert style is Alert rather than Banner
            updaterController.checkForUpdates(nil)
        }

        completionHandler()
    }

    func setupNotificationCenter() {
        UNUserNotificationCenter.current().delegate = self

        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, error in

            if let error = error {
                print(error)
            }
        }
    }

    func setupAutoRefresh() {
        timer = Timer(timeInterval: 60.0, target: self, selector: #selector(onAutoRefreshAlarm), userInfo: nil, repeats: true)

        guard let _ = timer else { return }
        RunLoop.main.add(timer!, forMode: RunLoop.Mode.default)
    }

    @objc func onAutoRefreshAlarm() {
        refresh()
    }

    func setupMenu() {
        let menu = NSMenu()

        // set initial icon
        setIcon(0)

        let prefs = NSMenuItem(title: "Preferences...", action: #selector(onShowPreferences), keyEquivalent: ",")
        let check = NSMenuItem(title: "Check", action: #selector(onRefresh), keyEquivalent: "R")
        let exit = NSMenuItem(title: "Quit", action: #selector(onExit), keyEquivalent: "Q")

        menu.addItem(prefs)
        menu.addItem(check)
        menu.addItem(open)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(exit)

        statusItem.menu = menu
        statusItem.length = NSStatusItem.squareLength
    }

    private func setIcon(_ count: Int, wink _: Bool = false, shout _: Bool = false) {
        setIconWhenNoNotifications()

        DispatchQueue.main.asyncAfter(deadline: .now()) {
            if count > 0 {
                self.setIconWhenNotified(count: count)
            } else {
                self.setIconWhenNoNotifications()
            }
        }
    }

    func fadeOutInMenubarIcon() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 1
            self.statusItem?.button?.animator().alphaValue = 0
        } completionHandler: {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 1
                self.statusItem?.button?.animator().alphaValue = 1
            }
        }
    }

    func fadeOut() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 1
            self.statusItem?.button?.animator().alphaValue = 0
        }
    }

    func fadeIn() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 1
            self.statusItem?.button?.animator().alphaValue = 1
        }
    }

    func waveMenubarIcon() {
        if let button = statusItem.button {
            let animation = CABasicAnimation(keyPath: "transform.rotation.z")
            animation.fromValue = -0.1
            animation.toValue = 0.15
            animation.duration = 1
            animation.speed = 2.1
            animation.repeatCount = 2
            animation.autoreverses = true
            button.layer?.anchorPoint = NSPoint(x: 0.5, y: 1)
            button.layer?.add(animation, forKey: "rotate")
        }
    }

    private func setIconWhenWinking() {
        if let button = statusItem.button {
            let colors: [NSColor] = [.white]

            var iconStyle = NSImage.SymbolConfiguration(paletteColors: colors)

            iconStyle = iconStyle.applying(.init(textStyle: .title3))

            button.image = NSImage(systemSymbolName: "hand.wave", accessibilityDescription: nil)!.withSymbolConfiguration(iconStyle)!
            waveMenubarIcon()
        }
    }

    private func setIconWhenNotified(count _: Int) {
        if let button = statusItem.button {
            // use user defined setting
            let color = UserDefaults.standard.color(forKey: "iconTint")

            let image = NSImage(named: NSImage.Name("StatusIconHighlight"))?.tint(color: NSColor(color))
            image!.size = NSMakeSize(18.0, 18.0)

            button.image = image
        }
    }

    private func setIconWhenNoNotifications() {
        if let button = statusItem.button {
            let image = NSImage(named: NSImage.Name("StatusIconNoNotifications"))
            image!.size = NSMakeSize(18.0, 18.0)

            button.image = image
        }
    }

    private func refresh() {
        let token = personalAccessTokenManager.getToken().token

        if token != nil {
            github = GitHub(config: TokenConfiguration(token))

            github.fetch { _ in
                let newNotifications = self.notificationCount != self.github.myNotifications.count
                self.notificationCount = self.github.myNotifications.count
                self.open.title = "Open (\(self.notificationCount))"

                DispatchQueue.main.async {
                    // if new unread notifications since last check show different icon
                    self.setIcon(self.notificationCount, wink: newNotifications, shout: true)
                }
            }
        }
    }

    private func exitApp() {
        NSApplication.shared.terminate(self)
    }

    @objc func onRefresh() {
        fadeOutInMenubarIcon()
        refresh()
    }

    @objc func onOpen() {
        guard let url = URL(string: "https://github.com/notifications") else { return }

        NSWorkspace.shared.open(url)
    }

    @objc func onShowPreferences() {
        // call when creds saved or add refresh button
        let preferencesView = PreferencesView(refreshStatusIcon: {
            self.setIcon(self.notificationCount)
        })

        let window = NSWindow(
            contentViewController: NSHostingController(rootView: preferencesView)
        )

        window.title = "Preferences"
        window.makeKeyAndOrderFront(nil)
        window.level = .floating
    }

    @objc func onExit() {
        exitApp()
    }
}
