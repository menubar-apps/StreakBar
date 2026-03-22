//
//  ThemeCardView.swift
//  streak-bar
//
//  Created for HIG improvements
//

import SwiftUI

struct ThemeCardView: View {
    let themeName: String
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isHovering = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        VStack(spacing: 8) {
            // Color swatches
            HStack(spacing: 4) {
                ForEach([ContributionLevel.NONE, .FIRST_QUARTILE, .SECOND_QUARTILE, .THIRD_QUARTILE, .FOURTH_QUARTILE], id: \.self) { level in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Theme.themes[themeName]![level]!)
                        .frame(width: 16, height: 16)
                        .shadow(color: .black.opacity(0.1), radius: 1, y: 0.5)
                }
            }
            
            // Theme name
            Text(themeName.capitalized)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : (isHovering ? Color.primary.opacity(0.05) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .overlay(alignment: .topTrailing) {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .background(
                        Circle()
                            .fill(Color.accentColor)
                            .padding(-2)
                    )
                    .padding(6)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .whenHovered { hovering in
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .scaleEffect(isHovering && !isSelected ? 1.02 : 1.0)
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(themeName.capitalized) theme")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
        .help("Select \(themeName.capitalized) theme")
    }
}
