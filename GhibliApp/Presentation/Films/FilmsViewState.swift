import Foundation

struct FilmsViewState {
    var status: ViewStatus = .idle
    var films: [Film] = []
    var isOffline: Bool = false
    var snackbar: ConnectivitySnackbar.State? = nil
}
