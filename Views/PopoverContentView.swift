import SwiftUI

struct PopoverContentView: View {
    @ObservedObject var viewModel: UsageViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection

            if viewModel.showingTokenInput {
                tokenInputSection
            } else if viewModel.showingTokenReset {
                tokenResetSection
            } else if let error = viewModel.errorMessage {
                errorSection(error)
            } else if viewModel.usageData != nil {
                usageSection
            } else if viewModel.isLoading {
                loadingSection
            } else {
                emptySection
            }

            Spacer()

            footerSection
        }
        .padding()
        .frame(width: 280, height: 280)
        .onAppear {
            viewModel.resetToUsageView()
        }
    }

    private var headerSection: some View {
        HStack {
            Text(I18nService.shared.translate("app.name"))
                .font(.headline)
            Spacer()
            if viewModel.isLoading {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
                    .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: viewModel.isLoading)
            }
        }
    }

    private var tokenInputSection: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                Button(action: {
                    if let url = URL(string: "https://platform.minimaxi.com/user-center/payment/coding-plan") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Image(systemName: "arrow.up.right.square")
                }
                .buttonStyle(.bordered)
            }

            Text(I18nService.shared.translate("popover.configureToken"))
                .font(.subheadline.bold())

            PasteableTextField(text: $viewModel.tokenInput, placeholder: I18nService.shared.translate("popover.inputPlaceholder"))
                .frame(height: 60)

            HStack {
                Button(action: {
                    viewModel.resetToUsageView()
                }) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.bordered)

                Button(action: {
                    viewModel.saveToken()
                }) {
                    Image(systemName: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.tokenInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .background(Color.accentColor.opacity(0.08))
        .cornerRadius(8)
    }

    private var tokenResetSection: some View {
        VStack(spacing: 16) {
            Label(I18nService.shared.translate("popover.tokenConfigured"), systemImage: "checkmark.circle.fill")
                .font(.subheadline.bold())
                .foregroundColor(.green)

            Button(action: {
                viewModel.showTokenReset()
            }) {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.accentColor.opacity(0.08))
        .cornerRadius(8)
    }

    private func errorSection(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(I18nService.shared.translate("popover.error"), systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline.bold())
                .foregroundColor(.red)
            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }

    private var usageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            dailySection
            weeklySection

            if let expiry = viewModel.usageData?.expiryDate {
                expirySection(expiry)
            }

            statusSection
        }
    }

    private var dailySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(I18nService.shared.translate("popover.daily"), systemImage: "sun.max")
                .font(.caption.bold())

            HStack {
                Text("\(I18nService.shared.translate("popover.remaining")): \(viewModel.usageData?.dailyRemaining ?? 0)/\(viewModel.usageData?.dailyTotal ?? 0) \(I18nService.shared.translate("popover.unit.times"))")
                    .font(.caption)
                Spacer()
            }

            Text("\(I18nService.shared.translate("popover.reset")): \(viewModel.usageData?.dailyResetTime ?? "")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color.orange.opacity(0.15))
        .cornerRadius(6)
    }

    private var weeklySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(I18nService.shared.translate("popover.weekly"), systemImage: "calendar")
                .font(.caption.bold())

            HStack {
                Text("\(I18nService.shared.translate("popover.remaining")): \(viewModel.usageData?.weeklyRemaining ?? 0)/\(viewModel.usageData?.weeklyTotal ?? 0) \(I18nService.shared.translate("popover.unit.times"))")
                    .font(.caption)
                Spacer()
            }

            Text("\(I18nService.shared.translate("popover.reset")): \(viewModel.usageData?.weeklyResetTime ?? "")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color.blue.opacity(0.15))
        .cornerRadius(6)
    }

    private func expirySection(_ date: Date) -> some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"

        return HStack {
            Text("\(I18nService.shared.translate("popover.expiry")): \(formatter.string(from: date))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var statusSection: some View {
        HStack {
            if viewModel.usageData?.isHealthy == true {
                Label(I18nService.shared.translate("popover.normal"), systemImage: "checkmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundColor(.green)
            } else {
                Label(I18nService.shared.translate("popover.low"), systemImage: "exclamationmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundColor(.red)
            }
            Spacer()
        }
    }

    private var loadingSection: some View {
        VStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var emptySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(I18nService.shared.translate("popover.notConfigured"), systemImage: "gear")
                .font(.subheadline.bold())
            Text(I18nService.shared.translate("popover.configureFirst"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    private var footerSection: some View {
        HStack(spacing: 8) {
            if viewModel.showingTokenInput || viewModel.showingTokenReset {
                Button(action: { viewModel.resetToUsageView() }) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.bordered)
            } else {
                Button(action: {
                    Task {
                        await viewModel.refresh()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)

                Button(action: { viewModel.toggleTokenInput() }) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}