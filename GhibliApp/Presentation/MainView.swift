import SwiftUI

struct MainView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            Text("Main View")
                .font(.title)
                .foregroundColor(.primary)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
