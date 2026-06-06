import SwiftUI
import VaultFeed
import VaultSettings

@MainActor
struct VaultSettingsView: View {
    @Environment(VaultDataModel.self) private var dataModel
    @Environment(DeviceAuthenticationService.self) private var authenticationService
    @State private var viewModel: SettingsViewModel
    @Bindable private var localSettings: LocalSettings

    @State private var modal: Modal?

    private enum Modal: IdentifiableSelf {
        case danger
    }

    init(viewModel: SettingsViewModel, localSettings: LocalSettings) {
        _viewModel = State(wrappedValue: viewModel)
        _localSettings = Bindable(wrappedValue: localSettings)
    }

    var body: some View {
        Form {
            viewOptionsSection
            universalClipboardSection
            dangerSection
        }
        .navigationTitle(viewModel.title)
        .sheet(item: $modal, onDismiss: nil) { item in
            switch item {
            case .danger:
                NavigationStack {
                    SettingsDangerView(viewModel: .init(
                        dataModel: dataModel,
                        authenticationService: authenticationService,
                    ))
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button {
                                modal = nil
                            } label: {
                                Text("Done")
                            }
                        }
                    }
                }
            }
        }
    }

    private var viewOptionsSection: some View {
        Section {
            Picker(selection: $localSettings.state.pasteTimeToLive) {
                ForEach(PasteTTL.defaultOptions) { option in
                    Text(option.localizedName)
                        .tag(option)
                }
            } label: {
                FormRow(image: Image(systemName: "clock.fill"), color: .blue, style: .prominent) {
                    Text(viewModel.pasteTTLTitle)
                }
            }
        } footer: {
            Text("How long copied values stay on the clipboard before iOS automatically clears them.")
        }
    }

    private var universalClipboardSection: some View {
        Section {
            Toggle(isOn: $localSettings.state.allowUniversalClipboardForPasswords) {
                FormRow(image: Image(systemName: "key.fill"), color: .indigo, style: .prominent) {
                    Text("Passwords")
                }
            }
            Toggle(isOn: $localSettings.state.allowUniversalClipboardForOTPs) {
                FormRow(image: Image(systemName: "number"), color: .indigo, style: .prominent) {
                    Text("One-time codes")
                }
            }
            Toggle(isOn: $localSettings.state.allowUniversalClipboardForOther) {
                FormRow(image: Image(systemName: "doc.on.clipboard"), color: .indigo, style: .prominent) {
                    Text("Other")
                }
            }
        } header: {
            Text("Universal Clipboard")
        } footer: {
            Text(
                "When enabled, copied values of the selected kind sync to your other Apple devices via Universal Clipboard. Values are always copied locally; this only controls cross-device sync.",
            )
        }
    }

    private var dangerSection: some View {
        Section {
            Button {
                modal = .danger
            } label: {
                FormRow(
                    image: Image(systemName: "exclamationmark.triangle.fill"),
                    color: .red,
                    style: .prominent,
                ) {
                    Text("Danger Zone")
                }
            }
            .tint(.red)
        }
    }
}
