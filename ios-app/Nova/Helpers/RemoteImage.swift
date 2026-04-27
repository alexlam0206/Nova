import SwiftUI

struct RemoteImageView: View {
    let urlString: String?
    let width: CGFloat
    let height: CGFloat

    @State private var uiImage: UIImage? = nil

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.3)
                
            }
        }
        .frame(width: width, height: height)
        .clipped()
        .task(id: urlString) {
            guard let urlString = urlString, let url = URL(string: urlString) else { return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    uiImage = image
                }
            } catch {
                // ignore
            }
        }
    }
}
