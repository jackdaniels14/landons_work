import SwiftUI

struct ManageServicesView: View {
    @StateObject private var servicePackageService = ServicePackageService()
    @State private var showAddService = false
    @State private var editingService: ServicePackage?

    var body: some View {
        NavigationStack {
            List {
                ForEach(servicePackageService.services) { service in
                    ServiceManagementRow(service: service) {
                        editingService = service
                    } onToggle: {
                        Task {
                            try? await servicePackageService.toggleServiceActive(service.id)
                        }
                    }
                }
                .onDelete { indexSet in
                    deleteServices(at: indexSet)
                }
            }
            .navigationTitle("Services")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddService = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                try? await servicePackageService.fetchServices()
            }
            .sheet(isPresented: $showAddService) {
                AddEditServiceView(service: nil) { newService in
                    Task {
                        try? await servicePackageService.createService(newService)
                    }
                }
            }
            .sheet(item: $editingService) { service in
                AddEditServiceView(service: service) { updatedService in
                    Task {
                        try? await servicePackageService.updateService(updatedService)
                    }
                }
            }
        }
    }

    func deleteServices(at offsets: IndexSet) {
        for index in offsets {
            let service = servicePackageService.services[index]
            Task {
                try? await servicePackageService.deleteService(service.id)
            }
        }
    }
}

struct ServiceManagementRow: View {
    let service: ServicePackage
    let onEdit: () -> Void
    let onToggle: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(service.name)
                        .font(.headline)

                    if !service.isActive {
                        Text("Inactive")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(4)
                    }
                }

                Text(service.formattedPrice)
                    .font(.subheadline)
                    .foregroundColor(.green)

                Text(service.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Menu {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Button {
                    onToggle()
                } label: {
                    Label(
                        service.isActive ? "Deactivate" : "Activate",
                        systemImage: service.isActive ? "eye.slash" : "eye"
                    )
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct AddEditServiceView: View {
    @Environment(\.dismiss) var dismiss

    let service: ServicePackage?
    let onSave: (ServicePackage) -> Void

    @State private var name = ""
    @State private var description = ""
    @State private var basePrice = ""
    @State private var duration = 60
    @State private var features: [String] = []
    @State private var newFeature = ""

    var isValid: Bool {
        !name.isEmpty && !description.isEmpty && Double(basePrice) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Service Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Pricing") {
                    TextField("Base Price ($)", text: $basePrice)
                        .keyboardType(.decimalPad)

                    Stepper("Duration: \(duration) min", value: $duration, in: 15...480, step: 15)
                }

                Section("Features") {
                    ForEach(features, id: \.self) { feature in
                        Text(feature)
                    }
                    .onDelete { indexSet in
                        features.remove(atOffsets: indexSet)
                    }

                    HStack {
                        TextField("Add feature", text: $newFeature)
                        Button {
                            if !newFeature.isEmpty {
                                features.append(newFeature)
                                newFeature = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .navigationTitle(service == nil ? "Add Service" : "Edit Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveService()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let service = service {
                    name = service.name
                    description = service.description
                    basePrice = String(format: "%.0f", service.basePrice)
                    duration = service.duration
                    features = service.features
                }
            }
        }
    }

    func saveService() {
        let newService = ServicePackage(
            id: service?.id ?? UUID(),
            name: name,
            description: description,
            basePrice: Double(basePrice) ?? 0,
            duration: duration,
            features: features,
            isActive: service?.isActive ?? true,
            sortOrder: service?.sortOrder ?? 0
        )

        onSave(newService)
        dismiss()
    }
}

#Preview {
    ManageServicesView()
}
