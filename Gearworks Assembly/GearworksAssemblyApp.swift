import SwiftUI
import Foundation

@main
struct GearworksAssemblyApp: App {
    @StateObject private var gearStore = GameStore.shared
    @State private var gearGateReady: Bool? = nil
    @Environment(\.scenePhase) private var scenePhase

    private let gearSourceLink = "https://example.com"
    private let gearCheckDomain = "example"

    init() {
        UINavigationBar.appearance().tintColor = UIColor(GearPalette.copper)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = gearGateReady {
                    if ready {
                        GearGlassPanel(urlString: gearSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                    } else {
                        ContentView()
                            .environmentObject(gearStore)
                            .preferredColorScheme(.dark)
                    }
                } else {
                    GearForgeLoadingScreen()
                        .preferredColorScheme(.dark)
                        .onAppear { beginGearGateCheck() }
                }
            }
            .onChange(of: scenePhase) { phase in
                if phase == .background { gearStore.saveNow() }
            }
        }
    }

    private func beginGearGateCheck() {
        guard let url = URL(string: gearSourceLink) else {
            gearGateReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = GearRedirectBeacon(checkDomain: gearCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    gearGateReady = false
                    return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(self.gearCheckDomain) {
                    gearGateReady = false
                    return
                }
                if let httpResponse = response as? HTTPURLResponse,
                   let responseURL = httpResponse.url?.absoluteString,
                   responseURL.contains(self.gearCheckDomain) {
                    gearGateReady = false
                    return
                }
                if error != nil {
                    gearGateReady = false
                    return
                }
                gearGateReady = true
            }
        }.resume()

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if gearGateReady == nil {
                gearGateReady = false
            }
        }
    }
}

final class GearRedirectBeacon: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String

    init(checkDomain: String) {
        self.checkDomain = checkDomain
    }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let urlString = request.url?.absoluteString, urlString.contains(checkDomain) {
            foundCheckDomain = true
        }
        resolvedURL = request.url
        completionHandler(request)
    }
}
