//
//  HoverableLabel.swift
//  streak-bar
//
//  Created by Pavel Makhov on 2023-09-03.
//

import SwiftUI

struct HoverableLabel: View {
    
    let iconName: String
    @State private var isHovering = false

    var body: some View {
        Label("Settings", systemImage: iconName)
            .labelStyle(.iconOnly)
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous).fill(.secondary.opacity(isHovering ? 0.2 : 0))
            )
            .whenHovered { over in isHovering = over }
    }
}

struct HoverableButton_Previews: PreviewProvider {
    static var previews: some View {
        HoverableLabel(iconName: "gearshape")
    }
}
