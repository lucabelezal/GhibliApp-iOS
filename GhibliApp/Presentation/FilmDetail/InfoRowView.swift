import SwiftUI

struct InfoRowView: View {

    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label + ":")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 110, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .multilineTextAlignment(.leading)

            Spacer()
        }
    }
}
