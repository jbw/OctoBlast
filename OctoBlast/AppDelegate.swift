//
//  AppDelegate.swift
//  OctoBlast
//
//  Created by Jason Watson on 16/08/2022.
//

import Foundation
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var loginManager: PersonalAccessToken! = PersonalAccessToken.shared
    private var github: GitHub! = GitHub.shared
    private var notificationCount = 0
    private var open: NSMenuItem = NSMenuItem(title: "Open (0)", action: #selector(onOpen), keyEquivalent: "O")

    var timer: Timer?

    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        setupAutoRefresh()
        setupMenu()
        refresh()
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

        let login = NSMenuItem(title: "Preferences...", action: #selector(onShowPreferences), keyEquivalent: ",")
        let check = NSMenuItem(title: "Check", action: #selector(onRefresh), keyEquivalent: "R")
        let exit = NSMenuItem(title: "Quit", action: #selector(onExit), keyEquivalent: "Q")

        menu.addItem(login)
        menu.addItem(check)
        menu.addItem(open)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(exit)

        statusItem.menu = menu
        statusItem.length = NSStatusItem.squareLength
    }

    private func setIcon(_ count: Int, wink _: Bool = false, shout _: Bool = false) {
        setIconWhenNotified(count: count)

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
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
            let image = NSImage(named: NSImage.Name("StatusIconHighlight"))
            image!.size = NSMakeSize(18.0, 18.0)

            button.image = image
        }
    }

    private func setIconWhenNoNotifications() {
        if let button = statusItem.button {
            let image = NSImage(named: NSImage.Name("StatusIconLight"))
            image!.size = NSMakeSize(18.0, 18.0)

            button.image = image
        }
    }

    private func refresh() {
        let token = loginManager.personalAccessToken

        if token != nil {
            github.fetch(token!) { _ in
                let newNotifications = self.notificationCount != self.github.myNotifications.count
                self.notificationCount = self.github.myNotifications.count
                self.open.title = "Open (\(self.notificationCount))"

                DispatchQueue.main.async {
                    // if new unreads since last check show different icon
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
        let preferencesView = PreferencesView()

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
