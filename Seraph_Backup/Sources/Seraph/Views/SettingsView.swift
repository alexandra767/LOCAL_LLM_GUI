import SwiftUI

@available(macOS 13.0, *)
struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @AppStorage("appearance") private var appearance: String = "system"
    
    var body: some View {
        Form {
            Picker("Appearance", selection: $appearance) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.segmented)
            .padding()
            .onChange(of: appearance) { _ in
                updateAppearance()
            }
            
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                if let privacyURL = URL(string: "https://example.com/privacy") {
                    Link("Privacy Policy", destination: privacyURL)
                }
                
                if let termsURL = URL(string: "https://example.com/terms") {
                    Link("Terms of Service", destination: termsURL)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .padding()
        .onAppear {
            updateAppearance()
        }
    }
    
    private func updateAppearance() {
        NSApp.appearance = switch appearance {
        case "light":
            NSAppearance(named: .aqua)
        case "dark":
            NSAppearance(named: .darkAqua)
        default:
            nil
        }
    }
}

@available(macOS 13.0, *)
#Preview {
    SettingsView()
        .environmentObject({
            let state = AppState()
            state.loadSampleData()
            return state
        }())
}
