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
            let width = viewMode == .week ? daysBefore*3 + 20 : daysBefore * 22 + 20

            button.frame = NSRect(x: 0, y: 0, width: width, height: 22)
            
            let hostingView = NSHostingView(rootView: itemView)
            hostingView.frame = button.frame
            button.addSubview(hostingView)
            button.action = #selector(togglePopover(_:))
            
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
            
            viewModel.getContributions()
        }
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = self.statusBarItem.button {
            if self.popover.isShown {
                self.popover.performClose(sender)
            } else {
                self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }

}

