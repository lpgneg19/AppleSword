import AppKit
import SwiftUI

struct AppleSwordMenuBar: Scene {
    @ObservedObject var taskStore: TaskStore

    var body: some Scene {
        MenuBarExtra {
            VStack {
                Text(LocalizedStringKey("AppleSword"))
                    .font(.headline)

                Divider()

                if taskStore.tasks.isEmpty {
                    Text(LocalizedStringKey("无活跃任务"))
                        .foregroundColor(.secondary)
                } else {
                    ForEach(taskStore.tasks.prefix(5)) { task in
                        HStack {
                            Text(task.bittorrent?.info?.name ?? task.files.first?.path ?? NSLocalizedString("未知任务", comment: ""))
                                .lineLimit(1)
                            Spacer()
                            Text(
                                "\(ByteCountFormatterUtil.string(fromByteCount: task.downloadSpeed))/s"
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                }

                Divider()

                Button(LocalizedStringKey("显示主窗口")) {
                    NSApp.activate(ignoringOtherApps: true)
                }

                Button(LocalizedStringKey("退出")) {
                    NSApp.terminate(nil)
                }
            }
            .padding()
        } label: {
            Image(systemName: "arrow.down.circle")
        }
    }
}
