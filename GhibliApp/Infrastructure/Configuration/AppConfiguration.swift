import Foundation

enum AppConfiguration {
    private enum Keys {
        static let ghibliAPIBaseURL = "GhibliAPIBaseURL"
    }

    private static let fileName = "AppConfiguration"
    private static let cache = makeConfiguration(for: .main)

    static var ghibliAPIBaseURL: URL {
        guard
            let urlString = cache[Keys.ghibliAPIBaseURL] as? String,
            let url = URL(string: urlString)
        else {
            fatalError("Missing or invalid GhibliAPIBaseURL entry in \(fileName).plist")
        }
        return url
    }

    #if DEBUG
        static func configuration(for bundle: Bundle) -> [String: Any] {
            makeConfiguration(for: bundle)
        }
    #endif

    private static func makeConfiguration(for bundle: Bundle) -> [String: Any] {
        guard let url = bundle.url(forResource: fileName, withExtension: "plist") else {
            fatalError("Could not locate \(fileName).plist in bundle \(bundle)")
        }

        guard let data = try? Data(contentsOf: url) else {
            fatalError("Unable to read \(fileName).plist")
        }

        guard
            let rawConfiguration = try? PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            ) as? [String: Any]
        else {
            fatalError("Invalid format for \(fileName).plist")
        }

        return rawConfiguration
    }
}
