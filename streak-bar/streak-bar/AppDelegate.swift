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

    var viewModel: ViewModel = ViewModel()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        NSApp.setActivationPolicy(.accessory)

        contentView = ContentView()
        itemView =  StatusItemView(viewModel: self.viewModel)
        hostingView = NSHostingView(rootView: itemView)
        
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 600)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        self.popover = popover
        
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
//        redrawBarItem()
        if let button = statusBarItem.button {
            button.frame = NSRect(x: 0, y: 0, width: daysBefore/7*3 + 20, height: 22)
            
            let hostingView = NSHostingView(rootView: itemView)
            hostingView.frame = NSRect(x: 0, y: 0, width: daysBefore/7*3 + 20, height: 22) // Adjust the size as needed
            button.addSubview(hostingView)
            button.action = #selector(togglePopover(_:))
            
            viewModel.getContributions()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    
    func redrawBarItem() {
        if let button = statusBarItem.button {
            button.frame = NSRect(x: 0, y: 0, width: daysBefore/7*3 + 20, height: 22)
            viewModel.getContributions()
            let hostingView = NSHostingView(rootView: itemView)
            hostingView.frame = NSRect(x: 0, y: 0, width: daysBefore/7*3 + 20, height: 22) // Adjust the size as needed
//            button.addSubview(hostingView)
        }
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = self.statusBarItem.button {
            if self.popover.isShown {
//                self.viewModel.popupIsShown = false
                self.popover.performClose(sender)
                self.viewModel.getContributions()
            } else {
//                self.viewModel.popupIsShown.toggle()
                self.viewModel.getContributions()
                redrawBarItem()

                self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
//                self.viewModel.popupIsShown.toggle()
            
//                self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }

}

