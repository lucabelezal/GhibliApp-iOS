import SwiftUI

struct FilmRowView: View {
    let film: Film
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: film.posterURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholder
                case .empty:
                    ShimmerView()
                @unknown default:
                    placeholder
                }
            }
            .frame(width: 100, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(film.title)
                        .font(.body)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .layoutPriority(1)

                    Text(film.synopsis)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .truncationMode(.tail)
                }

                Spacer()

                HStack(spacing: 8) {
                    infoBlock(systemName: "calendar", text: film.releaseYear)
                    infoBlock(systemName: "clock", text: "\(film.duration) min")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .frame(height: 150, alignment: .top)

            VStack(spacing: 0) {
                Spacer()

                Image(systemName: "chevron.forward")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, alignment: .center)

                Spacer()
            }
            .frame(width: 44)
            .frame(height: 150)
        }
        .padding(.horizontal, 8)
        .overlay(alignment: .topTrailing) {
            Button {
                onToggleFavorite()
            } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(isFavorite ? Color.ghibliSecondary : .secondary)
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .buttonStyle(.plain)
            .highPriorityGesture(TapGesture().onEnded { _ in onToggleFavorite() })
            .padding(.trailing, 8)
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(.gray.opacity(0.3))
            .overlay(Text("Imagem\nindisponível").font(.caption).multilineTextAlignment(.center))
    }

    @ViewBuilder
    private func infoBlock(systemName: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemName)
            Text(text)
                .lineLimit(1)
        }
    }

}

struct FilmRowShimmerView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ShimmerView()
                .frame(width: 100, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    shimmerLine(width: 180)
                    shimmerLine(width: 140)
                }

                VStack(alignment: .leading, spacing: 6) {
                    shimmerLine(width: 200)
                    shimmerLine(width: 220)
                    shimmerLine(width: 160)
                }

                Spacer()

                HStack(spacing: 8) {
                    infoChip(width: 70)
                    infoChip(width: 80)
                }
            }
            .frame(height: 150, alignment: .top)

            VStack(spacing: 0) {
                Spacer()

                ShimmerView()
                    .frame(width: 10, height: 30)
                    .clipShape(Capsule())
                    .frame(width: 44, alignment: .center)

                Spacer()
            }
            .frame(width: 44, height: 150)
        }
        .padding(.horizontal, 8)
        .overlay(alignment: .topTrailing) {
            ShimmerView()
                .frame(width: 20, height: 20)
                .clipShape(Circle())
                .frame(width: 44, height: 44)
                .padding(.trailing, 8)
        }
    }

    private func shimmerLine(width: CGFloat) -> some View {
        ShimmerView()
            .frame(width: width, height: 12)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private func infoChip(width: CGFloat) -> some View {
        ShimmerView()
            .frame(width: width, height: 16)
            .clipShape(Capsule())
    }
}
