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
    var preferencesWindow: NSWindow!
    var aboutWindow: NSWindow!
    var contentView: ContentView?
    var itemView: StatusItemView?
    var hostingView: NSView?

    @Default(.daysBefore) var daysBefore
    @Default(.viewMode) var viewMode

    var viewModel: ViewModel = ViewModel()
    var timer: Timer?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        NSApp.setActivationPolicy(.accessory)
        
        setupMenu()

        contentView = ContentView(appDelegate: self)
        itemView =  StatusItemView(viewModel: self.viewModel)
        hostingView = NSHostingView(rootView: itemView)
        
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 0, height: 0)
        popover.behavior = .semitransient
        popover.contentViewController = NSHostingController(rootView: contentView)
        self.popover = popover
        
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem.button {
            let width = viewMode == .week ? daysBefore * 3 + 20 : (daysBefore + 1) * 17 + 20

            button.frame = NSRect(x: 0, y: 0, width: width, height: 22)
            
            let hostingView = NSHostingView(rootView: itemView)
            hostingView.frame = button.frame
            button.addSubview(hostingView)
            button.action = #selector(togglePopover(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            
            // Fetch menubar data only
            viewModel.getContributions()
        }
        
        timer = Timer.scheduledTimer(
                    timeInterval: Double(60 * 60),
                    target: self,
                    selector: #selector(redrawBarItem),
                    userInfo: nil,
                    repeats: true
                )
                timer?.fire()
                RunLoop.main.add(timer!, forMode: .common)
    }
    
    func setupMenu() {
        let mainMenu = NSMenu()
        
        // App menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        
        appMenu.addItem(NSMenuItem(title: "About StreakBar", action: #selector(showAbout), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Quit StreakBar", action: #selector(quit), keyEquivalent: "q"))
        
        NSApp.mainMenu = mainMenu
    }
    
    @objc func showAbout() {
        // The about view is already in the popover, so just open it
        if let button = self.statusBarItem.button {
            if !self.popover.isShown {
                self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    
    @objc
    func redrawBarItem() {
        if let button = statusBarItem.button {
            button.subviews.removeAll()
            viewModel.contributions.removeAll()
            
            let width = viewMode == .week ? daysBefore*3 + 20 : daysBefore * 22 + 20
            
            button.frame = NSRect(x: 0, y: 0, width: width, height: 22)
            
            let hostingView = NSHostingView(rootView: itemView)
            hostingView.frame = button.frame
            button.addSubview(hostingView)
            button.action = #selector(togglePopover(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            
            viewModel.getContributions()
            viewModel.getContributionsByRepository()
        }
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
                    self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                }
            }
        }
    }
    
    func showContextMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Refresh", action: #selector(redrawBarItem), keyEquivalent: "r"))
        
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
            let point = NSPoint(x: button.frame.origin.x, y: button.frame.origin.y - 5)
            menu.popUp(positioning: nil, at: point, in: button)
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
    
    func openSettingsWindow() {
        if preferencesWindow == nil {
            let settingsView = SettingsView(appDelegate: self)
            let hostingController = NSHostingController(rootView: settingsView)
            
            preferencesWindow = NSWindow(contentViewController: hostingController)
            preferencesWindow.title = "Settings"
            preferencesWindow.styleMask = [.titled, .closable, .resizable]
            preferencesWindow.setContentSize(NSSize(width: 500, height: 600))
            preferencesWindow.center()
        }
        
        preferencesWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func openAboutWindow() {
        if aboutWindow == nil {
            let aboutView = AboutView()
            let hostingController = NSHostingController(rootView: aboutView)
            
            aboutWindow = NSWindow(contentViewController: hostingController)
            aboutWindow.title = "About StreakBar"
            aboutWindow.styleMask = [.titled, .closable]
            aboutWindow.setContentSize(NSSize(width: 400, height: 400))
            aboutWindow.center()
        }
        
        aboutWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

}

