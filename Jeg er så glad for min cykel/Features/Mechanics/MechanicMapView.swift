import MapKit
import SwiftUI

struct MechanicMapView: View {
    @Environment(\.isPresented) private var isPresented

    var body: some View {
        // Read isPresented outside our own NavigationStack so it reflects the sheet, not the stack.
        NavigationStack {
            MechanicMapContent(showsCloseButton: isPresented)
        }
    }
}

private struct MechanicMapContent: View {
    let showsCloseButton: Bool
    @State private var model = MechanicMapViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Map(position: $model.position, selection: $model.selection) {
            UserAnnotation()
            ForEach(model.shops, id: \.self) { shop in
                Marker(item: shop)
                    .tint(.orange)
                    .tag(shop)
            }
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange(frequency: .onEnd) { model.cameraChanged(to: $0.region) }
        .onChange(of: model.selection) { _, shop in
            guard let shop else { return }
            withAnimation { model.position = .item(shop) }
        }
        .overlay(alignment: .top) { searchHereButton }
        .safeAreaInset(edge: .bottom) {
            Group {
                if let shop = model.selection {
                    MechanicDetailCard(shop: shop, model: model)
                } else {
                    shopPanel
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            .animation(.snappy, value: model.selection)
        }
        .navigationTitle("Mekanikere")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsCloseButton {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Luk", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .task { await model.start() }
    }

    @ViewBuilder private var searchHereButton: some View {
        if model.canSearchHere && !model.isLoading {
            Button("Søg i dette område", systemImage: "arrow.clockwise") {
                Task { await model.searchVisibleRegion() }
            }
            .buttonStyle(.glass)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private var shopPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("I nærheden")
                    .font(.title2.bold())
                Spacer()
                if model.isLoading {
                    ProgressView()
                } else if !model.shops.isEmpty {
                    Text("\(model.shops.count) værksteder")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let error = model.errorMessage {
                statusView("Noget gik galt", systemImage: "wifi.exclamationmark", message: error, showsRetry: true)
            } else if model.shops.isEmpty {
                if model.isLoading {
                    statusView("Finder værksteder …", systemImage: "location.magnifyingglass", message: nil)
                } else {
                    statusView("Ingen værksteder fundet", systemImage: "bicycle",
                               message: "Flyt kortet og søg i et andet område.", showsRetry: true)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(model.shops, id: \.self) { shop in
                            Button { model.selection = shop } label: { row(shop) }
                                .buttonStyle(.plain)
                            if shop != model.shops.last { Divider().padding(.leading, 52) }
                        }
                    }
                }
                .frame(maxHeight: 260)
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
    }

    private func row(_ shop: MKMapItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "wrench.adjustable.fill")
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.orange.gradient, in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text(shop.name ?? "Cykelværksted")
                    .font(.headline)
                    .lineLimit(1)
                if let address = model.address(of: shop) {
                    Text(address)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            Text(model.distanceText(to: shop))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 10)
        .contentShape(.rect)
    }

    private func statusView(_ title: String, systemImage: String, message: String?, showsRetry: Bool = false) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title)
                .foregroundStyle(.secondary)
            Text(title).font(.headline)
            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            if showsRetry {
                Button("Prøv igen") { Task { await model.retry() } }
                    .buttonStyle(.glass)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

private struct MechanicDetailCard: View {
    let shop: MKMapItem
    let model: MechanicMapViewModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(shop.name ?? "Cykelværksted")
                        .font(.title2.bold())
                    Text(model.distanceText(to: shop) + " væk")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)
                    if let address = model.address(of: shop) {
                        Text(address)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button("Luk", systemImage: "xmark") { model.selection = nil }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
            }

            Button {
                shop.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeCycling])
            } label: {
                Label("Rutevejledning", systemImage: "bicycle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            .tint(.orange)

            HStack(spacing: 12) {
                if let phone = shop.phoneNumber,
                   let url = URL(string: "tel:" + phone.filter { "+0123456789".contains($0) }) {
                    secondaryButton("Ring op", systemImage: "phone.fill") { openURL(url) }
                }
                if let url = shop.url {
                    secondaryButton("Hjemmeside", systemImage: "safari.fill") { openURL(url) }
                }
            }
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
    }

    private func secondaryButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
        .buttonStyle(.glass)
    }
}

#Preview {
    MechanicMapView()
}
