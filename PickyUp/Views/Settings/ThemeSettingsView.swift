//
// ThemeSettingsView.swift
//
// Views/Settings/ThemeSettingsView.swift
//
// Last Updated 11/5/25

import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum AccentColorOption: String, CaseIterable, Identifiable {
    case blue = "Blue"
    case purple = "Purple"
    case pink = "Pink"
    case red = "Red"
    case orange = "Orange"
    case yellow = "Yellow"
    case green = "Green"
    case teal = "Teal"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .teal: return .teal
        }
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var selectedTheme: String = UserDefaults.standard.string(forKey: "selectedTheme") ?? AppTheme.system.rawValue {
        didSet {
            UserDefaults.standard.set(selectedTheme, forKey: "selectedTheme")
        }
    }
    
    @Published var accentColorString: String = UserDefaults.standard.string(forKey: "accentColor") ?? AccentColorOption.blue.rawValue {
        didSet {
            UserDefaults.standard.set(accentColorString, forKey: "accentColor")
        }
    }
    
    @Published var useDynamicType: Bool = UserDefaults.standard.bool(forKey: "useDynamicType") {
        didSet {
            UserDefaults.standard.set(useDynamicType, forKey: "useDynamicType")
        }
    }
    
    var currentTheme: AppTheme {
        get { AppTheme(rawValue: selectedTheme) ?? .system }
        set { selectedTheme = newValue.rawValue }
    }
    
    var currentAccentColor: AccentColorOption {
        get { AccentColorOption(rawValue: accentColorString) ?? .blue }
        set { accentColorString = newValue.rawValue }
    }
    
    private init() {
        // Initialize useDynamicType to true if it's never been set
        if !UserDefaults.standard.bool(forKey: "useDynamicTypeSet") {
            useDynamicType = true
            UserDefaults.standard.set(true, forKey: "useDynamicType")
            UserDefaults.standard.set(true, forKey: "useDynamicTypeSet")
        }
    }
}

struct ThemeSettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // Appearance Section
                Section {
                    ForEach(AppTheme.allCases) { theme in
                        Button {
                            withAnimation {
                                themeManager.currentTheme = theme
                            }
                        } label: {
                            HStack {
                                Image(systemName: theme.icon)
                                    .font(.title3)
                                    .foregroundStyle(themeManager.currentTheme == theme ? themeManager.currentAccentColor.color : .primary)
                                    .frame(width: 30)
                                
                                Text(theme.rawValue)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if themeManager.currentTheme == theme {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(themeManager.currentAccentColor.color)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Choose how the app looks. System follows your device's appearance settings.")
                }
                
                // Accent Color Section
                Section {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(AccentColorOption.allCases) { colorOption in
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    themeManager.currentAccentColor = colorOption
                                }
                            } label: {
                                VStack(spacing: 8) {
                                    Circle()
                                        .fill(colorOption.color.gradient)
                                        .frame(width: 50, height: 50)
                                        .overlay {
                                            if themeManager.currentAccentColor == colorOption {
                                                Circle()
                                                    .strokeBorder(.white, lineWidth: 3)
                                                Image(systemName: "checkmark")
                                                    .font(.title3)
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                        .shadow(color: colorOption.color.opacity(0.3), radius: 4, x: 0, y: 2)
                                    
                                    Text(colorOption.rawValue)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Accent Color")
                } footer: {
                    Text("Choose your preferred accent color for buttons and highlights.")
                }
                
                // Accessibility Section
                Section {
                    Toggle("Dynamic Type", isOn: $themeManager.useDynamicType)
                } header: {
                    Text("Accessibility")
                } footer: {
                    Text("Enable to allow text size to adjust based on your device's accessibility settings.")
                }
                
                // Preview Section
                Section {
                    VStack(spacing: 16) {
                        // Preview Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Circle()
                                    .fill(themeManager.currentAccentColor.color.gradient)
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        Text("JD")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.white)
                                    }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Preview")
                                        .font(.headline)
                                    Text("This is how your app will look")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                            }
                            
                            Divider()
                            
                            HStack {
                                Button("Button") {}
                                    .buttonStyle(.bordered)
                                    .tint(themeManager.currentAccentColor.color)
                                
                                Button("Filled") {}
                                    .buttonStyle(.borderedProminent)
                                    .tint(themeManager.currentAccentColor.color)
                                
                                Spacer()
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                } header: {
                    Text("Preview")
                }
            }
            .navigationTitle("Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CloseToolbarButton()
                }
            }
        }
        // Local preview update is optional; app-wide theme is applied at the App root.
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
    }
}

// MARK: - Preview
#Preview {
    ThemeSettingsView()
        .environmentObject(ThemeManager.shared)
}
