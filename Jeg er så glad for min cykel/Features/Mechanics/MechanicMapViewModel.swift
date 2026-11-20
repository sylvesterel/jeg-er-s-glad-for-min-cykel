import CoreLocation
import MapKit
import SwiftUI

@Observable final class MechanicMapViewModel {
    static let copenhagen = CLLocationCoordinate2D(latitude: 55.6761, longitude: 12.5683)

    var position: MapCameraPosition = .userLocation(
        fallback: .region(MKCoordinateRegion(center: copenhagen, latitudinalMeters: 6000, longitudinalMeters: 6000))
    )
    var selection: MKMapItem?
    private(set) var shops: [MKMapItem] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var canSearchHere = false

    private var userLocation: CLLocation?
    private var lastSearchCenter: CLLocationCoordinate2D?
    private var visibleRegion: MKCoordinateRegion?
    private var hasStarted = false

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        isLoading = true
        userLocation = await currentLocation()
        await search(around: userLocation?.coordinate ?? Self.copenhagen)
    }

    func searchVisibleRegion() async {
        guard let visibleRegion else { return }
        selection = nil
        await search(around: visibleRegion.center, span: visibleRegion.span)
    }

    func retry() async {
        await search(around: lastSearchCenter ?? userLocation?.coordinate ?? Self.copenhagen)
    }

    func cameraChanged(to region: MKCoordinateRegion) {
        visibleRegion = region
        guard let lastSearchCenter else { return }
        let moved = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
            .distance(from: CLLocation(latitude: lastSearchCenter.latitude, longitude: lastSearchCenter.longitude))
        canSearchHere = moved > 1500
    }

    /// Distance from the user, or from the search center when location is unavailable.
    func distanceText(to item: MKMapItem) -> String {
        let origin = userLocation ?? lastSearchCenter.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }
        guard let origin else { return "" }
        let km = item.location.distance(from: origin) / 1000
        return km.formatted(.number.precision(.fractionLength(1)).locale(Locale(identifier: "da_DK"))) + " km"
    }

    func address(of item: MKMapItem) -> String? {
        item.address?.shortAddress ?? item.address?.fullAddress
    }

    // MARK: - Private

    private func search(around center: CLLocationCoordinate2D, span: MKCoordinateSpan? = nil) async {
        isLoading = true
        errorMessage = nil
        canSearchHere = false
        lastSearchCenter = center
        defer { isLoading = false }

        let region = span.map { MKCoordinateRegion(center: center, span: $0) }
            ?? MKCoordinateRegion(center: center, latitudinalMeters: 8000, longitudinalMeters: 8000)
        // No bike-shop MKPointOfInterestCategory exists on iOS 26, so combine two Danish natural-language queries.
        var found: [MKMapItem] = []
        var failed = false
        for query in ["cykelværksted", "cykelsmed"] {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.region = region
            request.resultTypes = .pointOfInterest
            do {
                found += try await MKLocalSearch(request: request).start().mapItems
            } catch let error as MKError where error.code == .placemarkNotFound {
                // No results for this query: not an error.
            } catch {
                failed = true
            }
        }

        if found.isEmpty && failed {
            shops = []
            errorMessage = "Kunne ikke hente værksteder. Tjek din internetforbindelse."
            return
        }

        let origin = userLocation ?? CLLocation(latitude: center.latitude, longitude: center.longitude)
        var seen = Set<String>()
        shops = found
            .filter { seen.insert($0.identifier?.rawValue ?? "\($0.name ?? "")\($0.location.coordinate)").inserted }
            .sorted { $0.location.distance(from: origin) < $1.location.distance(from: origin) }
    }

    /// First location fix, or nil if denied/unavailable/too slow (caller falls back to Copenhagen).
    private func currentLocation() async -> CLLocation? {
        await withTaskGroup(of: CLLocation?.self) { group in
            group.addTask { await self.firstFix() }
            group.addTask { try? await Task.sleep(for: .seconds(15)); return nil }
            let result = await group.next() ?? nil
            group.cancelAll()
            return result
        }
    }

    private func firstFix() async -> CLLocation? {
        let session = CLServiceSession(authorization: .whenInUse)
        defer { session.invalidate() }
        do {
            for try await update in CLLocationUpdate.liveUpdates() {
                if let location = update.location { return location }
                if update.authorizationDenied || update.authorizationDeniedGlobally
                    || update.authorizationRestricted || update.locationUnavailable {
                    return nil
                }
            }
        } catch {}
        return nil
    }
}
