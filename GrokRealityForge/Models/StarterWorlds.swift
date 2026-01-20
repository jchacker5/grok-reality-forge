import Foundation

struct StarterWorldPreset: Identifiable {
    let id = UUID()
    let title: String
    let prompt: String
    let style: GenerationStyle
    let size: ImageSize
}

enum StarterWorlds {
    static let version = 2

    static let presets: [StarterWorldPreset] = [
        StarterWorldPreset(
            title: "Neon Rain",
            prompt: "Rain-soaked neon alley in a futuristic Tokyo district, cinematic lighting, wet reflections, panoramic view.",
            style: .photorealistic,
            size: .panorama1024
        ),
        StarterWorldPreset(
            title: "Forest Temple",
            prompt: "Ancient moss-covered forest temple with sunbeams, drifting fog, and glowing runes, immersive panorama.",
            style: .artistic,
            size: .panorama1024
        ),
        StarterWorldPreset(
            title: "Cozy Cabin",
            prompt: "Warm cabin interior with fireplace and snow outside the windows, soft lamplight, panoramic scene.",
            style: .photorealistic,
            size: .panorama1024
        ),
        StarterWorldPreset(
            title: "Sky Islands",
            prompt: "Floating sky islands above a cloud ocean with waterfalls and distant airships, wide panoramic vista.",
            style: .artistic,
            size: .panorama1024
        ),
        StarterWorldPreset(
            title: "Crystal Cavern",
            prompt: "Vast subterranean crystal cavern with bioluminescent light, reflective pools, and towering arches, immersive panorama.",
            style: .photorealistic,
            size: .panorama1024
        )
    ]
}
