import Foundation

struct ImageGenerationService {
    private struct ImageGenerationRequest: Encodable {
        let model: String
        let prompt: String
        let n: Int
        let width: Int
        let height: Int
        let response_format: String?
        let quality: String?
        let style: String?
    }

    private struct ImageGenerationResponse: Decodable {
        struct ImageData: Decodable {
            let url: String?
            let b64_json: String?
        }
        let data: [ImageData]?
        let images: [ImageData]?
    }

    private struct APIErrorResponse: Decodable {
        struct ErrorBody: Decodable {
            let message: String?
        }
        let error: ErrorBody?
    }

    func generateImages(prompt: String, options: GenerationOptions, settings: AppSettings, apiKey: String) async throws -> [Data] {
        let responseFormat = settings.responseFormat.trimmingCharacters(in: .whitespacesAndNewlines)
        let quality = settings.quality.trimmingCharacters(in: .whitespacesAndNewlines)
        let allowQuality = settings.apiModel.contains("imagine") ? quality : ""

        let requestBody = ImageGenerationRequest(
            model: settings.apiModel,
            prompt: prompt,
            n: options.variants,
            width: options.size.width,
            height: options.size.height,
            response_format: responseFormat.isEmpty ? nil : responseFormat,
            quality: allowQuality.isEmpty ? nil : allowQuality,
            style: options.style.rawValue
        )

        guard let url = URL(string: settings.apiEndpoint) else {
            throw AppError.apiError(message: "Invalid API endpoint URL.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let retries = 3
        var lastError: Error?
        for attempt in 0..<retries {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw AppError.apiError(message: "Unexpected response from API.")
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    let message = decodeErrorMessage(from: data) ?? "API error (status \(httpResponse.statusCode))."
                    throw AppError.apiError(message: message)
                }

                let decoded = try JSONDecoder().decode(ImageGenerationResponse.self, from: data)
                let payloads = decoded.data ?? decoded.images ?? []
                if payloads.isEmpty {
                    throw AppError.decodingFailed
                }

                return try await resolveImageData(from: payloads)
            } catch {
                lastError = error
                if attempt < retries - 1 {
                    let backoff = UInt64(pow(2.0, Double(attempt)) * 0.8 * 1_000_000_000)
                    try? await Task.sleep(nanoseconds: backoff)
                    continue
                }
            }
        }

        throw lastError ?? AppError.apiError(message: "Generation failed.")
    }

    private func resolveImageData(from payloads: [ImageGenerationResponse.ImageData]) async throws -> [Data] {
        var results: [Data] = []
        for item in payloads {
            if let base64 = item.b64_json, let data = Data(base64Encoded: base64) {
                results.append(data)
                continue
            }
            if let urlString = item.url, let url = URL(string: urlString) {
                let (data, _) = try await URLSession.shared.data(from: url)
                results.append(data)
                continue
            }
        }
        if results.isEmpty {
            throw AppError.decodingFailed
        }
        return results
    }

    private func decodeErrorMessage(from data: Data) -> String? {
        if let decoded = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
            return decoded.error?.message
        }
        if let text = String(data: data, encoding: .utf8), !text.isEmpty {
            return text
        }
        return nil
    }
}
