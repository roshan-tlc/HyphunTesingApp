//
//  DeviceCardView.swift
//  HyphunTestingApp
//
//  Created by Krithik Roshan on 22/09/25.
//

import SwiftUI

struct DeviceCardView: View {
    let device: Device
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("UDID: \(device.udid ?? "—")")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: device.isConnected ? "link.circle.fill" : "link.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(device.isConnected ? LinearGradient(gradient: Gradient(colors: [.green, .mint]), startPoint: .leading, endPoint: .trailing) : LinearGradient(gradient: Gradient(colors: [.red, .pink]), startPoint: .leading, endPoint: .trailing))
                    .accessibilityLabel(device.isConnected ? "Connected" : "Disconnected")
            }
            Divider()
                .background(Color.secondary.opacity(0.3))
            InfoRow(label: CommonProperties.deviceName, value: device.deviceName ?? "—")
            InfoRow(label: CommonProperties.iosVersion, value: device.iosVersion ?? "—")
            InfoRow(label: CommonProperties.battery, value: device.battery ?? "Unknown")
            InfoRow(label: CommonProperties.storage, value: device.availableStorage ?? "Unknown")
            HStack {
                Spacer()
                Button(action: onDelete) {
                    HStack {
                        Image(systemName: "trash")
                        Text(CommonProperties.remove)
                    }
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(LinearGradient(gradient: Gradient(colors: [.red, .pink]), startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Remove device \(device.deviceName ?? "Unknown")")
            }
        }
        .padding()
        .background(
            LinearGradient(gradient: Gradient(colors: [Color(.windowBackgroundColor), Color(.controlBackgroundColor).opacity(0.9)]), startPoint: .top, endPoint: .bottom)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label + ":")
                .font(.system(.body, design: .rounded, weight: .semibold))
            Spacer()
            Text(value)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.secondary)
        }
    }
}
