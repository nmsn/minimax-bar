import SwiftUI

struct PopoverContentView: View {
    @Bindable var viewModel: UsageViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection

            if let error = viewModel.errorMessage {
                errorSection(error)
            } else if let data = viewModel.usageData {
                usageSection(data)
            } else if viewModel.isLoading {
                loadingSection
            } else {
                emptySection
            }

            Spacer()

            footerSection
        }
        .padding()
        .frame(width: 280, height: 240)
    }

    private var headerSection: some View {
        HStack {
            Text("MiniMax 使用状态")
                .font(.headline)
            Spacer()
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
    }

    private func errorSection(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("⚠️ 错误")
                .foregroundColor(.red)
                .font(.subheadline.bold())
            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }

    private func usageSection(_ data: UsageData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("当前模型: \(data.modelName)")
                .font(.subheadline)

            Divider()

            dailySection(data)
            weeklySection(data)

            if let expiry = data.expiryDate {
                expirySection(expiry)
            }

            statusSection(data)
        }
    }

    private func dailySection(_ data: UsageData) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("日 (5小时窗口)", systemImage: "sun.max")
                .font(.caption.bold())
                .foregroundColor(.orange)

            HStack {
                Text("剩余: \(data.dailyRemaining)/\(data.dailyTotal) 次")
                    .font(.caption)
                Spacer()
            }

            Text("重置: \(data.dailyResetTime)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(6)
    }

    private func weeklySection(_ data: UsageData) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("周", systemImage: "calendar")
                .font(.caption.bold())
                .foregroundColor(.blue)

            HStack {
                Text("剩余: \(data.weeklyRemaining)/\(data.weeklyTotal) 次")
                    .font(.caption)
                Spacer()
            }

            Text("重置: \(data.weeklyResetTime)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(6)
    }

    private func expirySection(_ date: Date) -> some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"

        return HStack {
            Text("套餐到期: \(formatter.string(from: date))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func statusSection(_ data: UsageData) -> some View {
        HStack {
            Text(data.statusText)
                .font(.caption.bold())
                .foregroundColor(data.isHealthy ? .green : .red)
            Spacer()
        }
    }

    private var loadingSection: some View {
        VStack {
            Spacer()
            ProgressView("加载中...")
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var emptySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("未配置")
                .font(.subheadline.bold())
            Text("请先配置 MiniMax Token")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    private var footerSection: some View {
        HStack {
            Button(action: {
                Task {
                    await viewModel.refresh()
                }
            }) {
                Label("刷新", systemImage: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(.bordered)

            Spacer()

            if !viewModel.isConfigured {
                Button(action: openConfig) {
                    Label("设置 Token", systemImage: "gear")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func openConfig() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let configPath = home.appendingPathComponent(".minimax-config.json")

        let message = """
        请在 ~/.minimax-config.json 配置 Token:

        {
            "token": "your_token_here"
        }

        获取 Token: https://platform.minimaxi.com/user-center/payment/coding-plan
        """

        let alert = NSAlert()
        alert.messageText = "配置 MiniMax Token"
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "打开配置目录")
        alert.addButton(withTitle: "好的")

        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.selectFile(configPath.path, inFileViewerRootedAtPath: home.path)
        }
    }
}
