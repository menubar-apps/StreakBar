//
//  AppDelegate.swift
//  streak-bar
//
//  Created by Pavel Makhov on 2023-08-30.
//

import Cocoa
import SwiftUI
import Defaults

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusBarItem: NSStatusItem!
    var popover: NSPopover!
    var aboutWindow: NSWindow!
    var contentView: ContentView?
    var hostingView: NSHostingView<StatusItemView>?
    var barItemObservation: Defaults.Observation?

    var viewModel: ViewModel = ViewModel()
    var timer: Timer?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        NSApp.setActivationPolicy(.accessory)
        
        migrateUserDefaults()

        contentView = ContentView(appDelegate: self)

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 600)
        popover.behavior = .semitransient
        popover.contentViewController = NSHostingController(rootView: contentView)
        self.popover = popover
        
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem.button {
            let hostingView = NSHostingView(rootView: StatusItemView(viewModel: viewModel))
            hostingView.sizingOptions = []
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(hostingView)
            NSLayoutConstraint.activate([
                hostingView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                hostingView.topAnchor.constraint(equalTo: button.topAnchor),
                hostingView.bottomAnchor.constraint(equalTo: button.bottomAnchor)
            ])
            self.hostingView = hostingView
            button.action = #selector(togglePopover(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Colors update on their own inside StatusItemView; only the size depends on these settings
        updateBarItemWidth()
        barItemObservation = Defaults.observe(keys: .daysBefore, .viewMode, .borders, options: []) { [weak self] in
            DispatchQueue.main.async {
                self?.updateBarItemWidth()
            }
        }

        timer = Timer.scheduledTimer(
                    timeInterval: Double(60 * 60),
                    target: self,
                    selector: #selector(refreshContributions),
                    userInfo: nil,
                    repeats: true
                )
                timer?.fire()
                RunLoop.main.add(timer!, forMode: .common)
    }

    func barItemWidth() -> CGFloat {
        let count = CGFloat(max(Defaults[.daysBefore], 1))
        let padding: CGFloat = 16
        if Defaults[.viewMode] == .week {
            let borders = Defaults[.borders]
            let cell: CGFloat = borders ? 2 : 3
            let spacing: CGFloat = borders ? 1 : 0
            return count * cell + (count - 1) * spacing + padding
        }
        return count * 16 + (count - 1) * 1 + padding
    }

    func updateBarItemWidth() {
        statusBarItem.length = barItemWidth()
    }
    
    func migrateUserDefaults() {
        // Migrate legacy "transparency" key to "emptyDayTransparency"
        if let oldValue = UserDefaults.standard.object(forKey: "transparency") as? Bool {
            Defaults[.emptyDayTransparency] = oldValue
            UserDefaults.standard.removeObject(forKey: "transparency")
        }
    }
    
    @objc func showAbout() {
        openAboutWindow()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    
    @objc
    func refreshContributions() {
        viewModel.getContributions()
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = self.statusBarItem.button {
            // Check if right-click (or control-click)
            if let event = NSApp.currentEvent, event.type == .rightMouseUp || (event.type == .leftMouseUp && event.modifierFlags.contains(.control)) {
                showContextMenu()
            } else {
                if self.popover.isShown {
                    self.popover.performClose(sender)
                } else {
                    viewModel.getContributions()
                    viewModel.getContributionsByRepository()
                    self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                }
            }
        }
    }
    
    func showContextMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Refresh", action: #selector(refreshContributions), keyEquivalent: "r"))
        
        if let lastUpdate = viewModel.lastUpdateTime {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            let timeString = formatter.string(from: lastUpdate)
            let updateItem = NSMenuItem(title: "Last updated: \(timeString)", action: nil, keyEquivalent: "")
            updateItem.isEnabled = false
            menu.addItem(updateItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // View on GitHub
        if !Defaults[.githubUsername].isEmpty {
            menu.addItem(NSMenuItem(title: "View on GitHub", action: #selector(openGitHubProfile), keyEquivalent: ""))
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About StreakBar", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        
        if let button = statusBarItem.button {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height), in: button)
        }
    }
    
    @objc func openGitHubProfile() {
        let username = Defaults[.githubUsername]
        if let url = URL(string: "https://github.com/\(username)") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc
    func quit() {
        NSLog("User click Quit")
        NSApplication.shared.terminate(self)
    }
    
    // MARK: - Window Management
    
    func openAboutWindow() {
        if aboutWindow == nil {
            let aboutView = AboutView()
            let hostingController = NSHostingController(rootView: aboutView)
            
            aboutWindow = NSWindow(contentViewController: hostingController)
            aboutWindow.title = "About StreakBar"
            aboutWindow.styleMask = [.titled, .closable]
            aboutWindow.setContentSize(NSSize(width: 400, height: 640))
            aboutWindow.isReleasedWhenClosed = false
            aboutWindow.center()
        }
        
        aboutWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

}

