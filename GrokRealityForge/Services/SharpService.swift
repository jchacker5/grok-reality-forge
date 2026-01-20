import Foundation

struct SharpService {
    func cachedModelURL(for imageURL: URL) -> URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("SharpModels", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        let stem = imageURL.deletingPathExtension().lastPathComponent
        return folder.appendingPathComponent("\(stem).usdz")
    }

    func generateModel(imageURL: URL, prompt: String, endpoint: String, apiKey: String) async throws -> URL {
        guard let url = URL(string: endpoint) else {
            throw AppError.apiError(message: "Invalid SHARP endpoint URL.")
        }

        let imageData = try Data(contentsOf: imageURL)
        let payload: [String: Any] = [
            "image_b64": imageData.base64EncodedString(),
            "prompt": prompt
        ]
        let requestBody = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = requestBody

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw AppError.apiError(message: "SHARP request failed.")
        }

        if let modelURL = extractModelURL(from: data) {
            let (modelData, modelResponse) = try await URLSession.shared.data(from: modelURL)
            guard let modelHttp = modelResponse as? HTTPURLResponse, (200..<300).contains(modelHttp.statusCode) else {
                throw AppError.apiError(message: "Unable to download SHARP model.")
            }
            let destination = cachedModelURL(for: imageURL)
            try modelData.write(to: destination, options: .atomic)
            return destination
        }

        if let modelData = extractModelData(from: data) {
            let destination = cachedModelURL(for: imageURL)
            try modelData.write(to: destination, options: .atomic)
            return destination
        }

        throw AppError.apiError(message: "SHARP response missing model payload.")
    }

    private func extractModelURL(from data: Data) -> URL? {
        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        let candidate = object["usdz_url"] as? String
            ?? object["model_url"] as? String
            ?? object["url"] as? String
        guard let urlString = candidate else { return nil }
        return URL(string: urlString)
    }

    private func extractModelData(from data: Data) -> Data? {
        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        let b64 = object["usdz_b64"] as? String
            ?? object["model_b64"] as? String
        guard let b64 else { return nil }
        return Data(base64Encoded: b64)
    }
}
