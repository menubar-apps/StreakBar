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
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        Label("", systemImage: iconName)
            .labelStyle(.iconOnly)
            .font(.body)
            .foregroundStyle(isHovering ? .primary : .secondary)
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.secondary.opacity(isHovering ? 0.15 : 0))
            )
            .whenHovered { over in
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.15)) {
                    isHovering = over
                }
            }
            .scaleEffect(isHovering ? 1.05 : 1.0)
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
    }
}

struct HoverableButton_Previews: PreviewProvider {
    static var previews: some View {
        HoverableLabel(iconName: "gearshape")
    }
}
