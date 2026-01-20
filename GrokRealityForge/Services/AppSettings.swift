import Foundation
import SwiftUI

final class AppSettings: ObservableObject {
    @AppStorage("xai_api_endpoint") var apiEndpoint: String = "https://api.x.ai/v1/images/generations"
    @AppStorage("xai_api_model") var apiModel: String = "grok-2-image-1212"
    @AppStorage("xai_response_format") var responseFormat: String = "b64_json"
    @AppStorage("xai_quality") var quality: String = ""
    @AppStorage("xai_style") var style: String = "photorealistic"
    @AppStorage("sharp_enabled") var sharpEnabled: Bool = false
    @AppStorage("sharp_endpoint") var sharpEndpoint: String = ""
    @AppStorage("sharp_api_key") var sharpApiKey: String = ""

    var resolvedStyle: GenerationStyle {
        GenerationStyle(rawValue: style) ?? .photorealistic
    }
}
