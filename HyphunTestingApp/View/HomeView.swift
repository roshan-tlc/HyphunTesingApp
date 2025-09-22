//
//  CommonProperties.swift
//  HyphunTestingApp
//
//  Created by Krithik Roshan on 21/09/25.
//

import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Device.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Device.isConnected, ascending: false), NSSortDescriptor(keyPath: \Device.udid, ascending: true)]
    ) private var devices: FetchedResults<Device>
    @State private var status: String = CommonProperties.checkingForConnectedIPhone
    @State private var isRefreshing: Bool = false
    @State private var showClearConfirmation: Bool = false
    @State private var deviceToDelete: Device?
    @State private var showDeleteDeviceConfirmation: Bool = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text(CommonProperties.iphoneUseMonitor)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing))
                    .shadow(radius: 2)
                    .padding(.top)
                Text(status)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
                Divider()
                    .background(Color.secondary.opacity(0.3))
                if devices.isEmpty {
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .red]), startPoint: .leading, endPoint: .trailing))
                        Text(CommonProperties.noDevicesHaveBeenConnectedYet)
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(CommonProperties.noDeviceConnected)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(devices, id: \.udid) { device in
                                DeviceCardView(device: device, onDelete: {
                                    deviceToDelete = device
                                    showDeleteDeviceConfirmation = true
                                })
                                .transition(.opacity)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                HStack(spacing: 12) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isRefreshing = true
                        }
                        refresh()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isRefreshing = false
                            }
                        }
                    }) {
                        HStack {
                            if isRefreshing {
                                ProgressView()
                                    .frame(width: 60, height: 20, alignment: .center)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                Text(CommonProperties.refresh)
                            }
                        }
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .scaleEffect(isRefreshing ? 0.95 : 1.0)
                        .shadow(radius: isRefreshing ? 2 : 5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .keyboardShortcut("r", modifiers: .command)
                    
                    Button(action: {
                        showClearConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text(CommonProperties.clearAllDevices)
                        }
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Color.red.opacity(0.9))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .alert(isPresented: $showClearConfirmation) {
                        Alert(
                            title: Text(CommonProperties.clearAllDevices),
                            message: Text(CommonProperties.deleteStoredInformation),
                            primaryButton: .destructive(Text(CommonProperties.delete)) {
                                clearAllDevices()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .alert(isPresented: $showDeleteDeviceConfirmation) {
            Alert(
                title: Text(CommonProperties.deleteDevice),
                message: Text("Are you sure you want to delete the device '\(deviceToDelete?.deviceName ?? "Unknown")' (UDID: \(deviceToDelete?.udid ?? "Unknown"))? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    if let device = deviceToDelete {
                        deleteDevice(device)
                    }
                    deviceToDelete = nil
                },
                secondaryButton: .cancel()
            )
        }
        
    }
    
    private func refresh() {
        isRefreshing = true
        let ideviceInfoPath = "/opt/homebrew/bin/ideviceinfo"
        let udid = runProcess("/opt/homebrew/bin/idevice_id", args: ["-l"]).trimmingCharacters(in: .whitespacesAndNewlines)
        resetConnectionStatus()
        if udid.isEmpty {
            saveDeviceInfo(udid: CommonProperties.emptyString, deviceName: nil, iosVersion: nil, battery: nil,
                           availableStorage: nil, isConnected: false)
            return
        }
        let deviceNameResult = runProcess(ideviceInfoPath, args: ["-u", udid, "-k", "DeviceName"]).trimmingCharacters(in: .whitespacesAndNewlines)
        if deviceNameResult.isEmpty {
            saveDeviceInfo(udid: udid, deviceName: nil, iosVersion: nil, battery: nil, availableStorage: nil, isConnected: true)
            return
        }
        let rawIosVersion = runProcess(ideviceInfoPath, args: ["-u", udid, "-k", "ProductVersion"]).trimmingCharacters(in: .whitespacesAndNewlines)
        let iosVersion = rawIosVersion.isEmpty ? "Unknown" : rawIosVersion
        var batteryResult = runProcess(ideviceInfoPath, args: ["-u", udid, "-k", "BatteryCurrentCapacity"]).trimmingCharacters(in: .whitespacesAndNewlines)
        if batteryResult.isEmpty {
            batteryResult = runProcess(ideviceInfoPath, args: ["-u", udid, "-k", "BatteryAvailableCapacity"]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if batteryResult.isEmpty {
            let diagnostics = runProcess("/opt/homebrew/bin/idevicediagnostics", args: ["diagnostics", "-u", udid])
            if let batteryLevel = parseBatteryLevel(from: diagnostics) {
                batteryResult = batteryLevel
            }
        }
        let battery = batteryResult.isEmpty ? "Unknown" : "\(batteryResult)%"
        let totalStorage = runProcess(ideviceInfoPath, args: ["-u", udid, "-k", "TotalDiskCapacity"]).trimmingCharacters(in: .whitespacesAndNewlines)
        var availableStorageResult = runProcess(ideviceInfoPath, args: ["-u", udid, "-k", "TotalDataAvailable"]).trimmingCharacters(in: .whitespacesAndNewlines)
        if availableStorageResult.isEmpty {
            availableStorageResult = runProcess(ideviceInfoPath, args: ["-u", udid, "-k", "TotalSystemAvailable"]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let availableStorage = formatStorage(totalStorage: totalStorage, available: availableStorageResult)
        saveDeviceInfo(udid: udid, deviceName: deviceNameResult, iosVersion: iosVersion, battery: battery, availableStorage: availableStorage, isConnected: true)
        isRefreshing = false
    }
    
    private func resetConnectionStatus() {
        let fetchRequest: NSFetchRequest<Device> = Device.fetchRequest()
        do {
            let devices = try viewContext.fetch(fetchRequest)
            for device in devices {
                device.isConnected = false
            }
            try viewContext.save()
        } catch {
        }
    }
    
    private func clearAllDevices() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Device.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try viewContext.execute(batchDeleteRequest)
            try viewContext.save()
        } catch {
        }
    }
    
    private func deleteDevice(_ device: Device) {
        do {
            viewContext.delete(device)
            try viewContext.save()
        } catch {
            print("ERROR deleting device from Core Data: \(error)")
        }
    }
    
    private func saveDeviceInfo(udid: String, deviceName: String?, iosVersion: String?, battery: String?, availableStorage: String?, isConnected: Bool) {
        let fetchRequest: NSFetchRequest<Device> = Device.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "udid == %@", udid)
        
        do {
            let devices = try viewContext.fetch(fetchRequest)
            let device: Device
            
            if let existingDevice = devices.first {
                device = existingDevice
            } else if !udid.isEmpty {
                device = Device(context: viewContext)
                device.udid = udid
            } else {
                return
            }
            
            if let name = deviceName, !name.isEmpty, name != "—" {
                device.deviceName = name
            }
            if let version = iosVersion, !version.isEmpty, version != "Unknown" {
                device.iosVersion = version
            }
            if let bat = battery, !bat.isEmpty, bat != "Unknown" {
                device.battery = bat
            }
            if let storage = availableStorage, !storage.isEmpty, storage != "Unknown" {
                device.availableStorage = storage
            }
            device.isConnected = isConnected
            
            try viewContext.save()
        } catch {
            print("ERROR saving to Core Data: \(error)")
        }
    }
    
    private func formatStorage(totalStorage: String, available: String) -> String {
        guard let totalBytes = Double(totalStorage), let availableBytes = Double(available) else {
            return "Unknown"
        }
        let availableGB = availableBytes / 1_000_000_000
        let totalGB = totalBytes / 1_000_000_000
        return String(format: "%.2f GB / %.2f GB", availableGB, totalGB)
    }
    
    private func parseBatteryLevel(from diagnostics: String) -> String? {
        if let range = diagnostics.range(of: "BatteryLevel\":\\s*(\\d+)", options: .regularExpression) {
            let value = diagnostics[range].split(separator: ":").last?.trimmingCharacters(in: .whitespaces)
            return value
        }
        return nil
    }
    
    private func runProcess(_ command: String, args: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = args
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return CommonProperties.emptyString
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? CommonProperties.emptyString
        return output
    }
}


