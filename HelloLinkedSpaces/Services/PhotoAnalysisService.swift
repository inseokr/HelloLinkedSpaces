import Foundation
import Photos
import CoreML
import UIKit

class PhotoAnalysisService: ObservableObject {
    @Published var photoMetadata: [PhotoMetadata] = []
    private let userDefaults = UserDefaults.standard
    private let metadataKey = "photoMetadata"
    
    struct CategoryResult {
        let category: String
        let confidence: Float
        let matchedTags: [(tag: String, confidence: Float)]
    }
    
    struct AnalysisResult {
        let topCategories: [CategoryResult]
        let allTags: [(tag: String, confidence: Float)]
    }
    
    init() {
        loadMetadata()
    }
    
    private func getOpenAIApiKey() -> String {
        guard let configPath = Bundle.main.path(forResource: "Config", ofType: "xcconfig"),
              let configString = try? String(contentsOfFile: configPath, encoding: .utf8) else {
            fatalError("Config.xcconfig file not found")
        }
        
        // Parse the config file to find the API key
        let lines = configString.components(separatedBy: .newlines)
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.hasPrefix("OPENAI_API_KEY") {
                let components = trimmedLine.components(separatedBy: "=")
                if components.count == 2 {
                    let apiKey = components[1].trimmingCharacters(in: .whitespaces)
                    if apiKey != "YOUR_API_KEY_HERE" {
                        return apiKey
                    }
                }
            }
        }
        
        fatalError("OpenAI API key not found in Config.xcconfig. Please add it to the configuration file.")
    }
    
    func analyzePhoto(_ image: UIImage, progress: @escaping (String) -> Void) async -> AnalysisResult? {
        print("DEBUG: Starting photo analysis")
        
        guard let cgImage = image.cgImage else {
            print("DEBUG: Failed to get CGImage from UIImage")
            progress("Failed to process image")
            return nil
        }
        
        print("DEBUG: Image size: \(cgImage.width)x\(cgImage.height)")
        progress("Starting image analysis...")
        
        do {
            print("DEBUG: Loading Core ML model")
            progress("Loading model...")
            
            // Initialize the PlaceClassificationService with MobileNetV2
            let classifier = try PlaceClassificationService(modelName: "MobileNetV2", openAIApiKey: getOpenAIApiKey())
            
            print("DEBUG: Running prediction")
            progress("Analyzing image...")
            
            // Get predictions from the model
            let predictions = try await classifier.predict(image: image)
            
            print("DEBUG: Got predictions from Core ML")
            print("DEBUG: Predictions: \(predictions)")
            
            // Get the raw predictions from the model for top 10 tags
            let rawPredictions = try classifier.getRawPredictions(image: image)
            let top10Tags = rawPredictions
                .sorted { $0.value > $1.value }
                .prefix(10)
                .map { (tag: $0.key, confidence: Float($0.value)) }
            
            // Convert predictions to our format
            let topCategories = predictions
                .prefix(2)
                .map { prediction in
                    CategoryResult(
                        category: prediction.category,
                        confidence: Float(prediction.confidence),
                        matchedTags: prediction.contributingTags.map { tag in
                            (tag: tag.tag, confidence: Float(tag.confidence))
                        }
                    )
                }
            
            // Create the analysis result
            let result = AnalysisResult(
                topCategories: topCategories,
                allTags: top10Tags
            )
            
            print("DEBUG: Analysis complete")
            progress("Analysis complete!")
            return result
            
        } catch {
            print("DEBUG: Error during analysis: \(error)")
            progress("Error during analysis: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func saveMetadata(_ metadata: PhotoMetadata) {
        photoMetadata.append(metadata)
        saveToUserDefaults()
    }
    
    private func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(photoMetadata) {
            userDefaults.set(encoded, forKey: metadataKey)
        }
    }
    
    private func loadMetadata() {
        if let data = userDefaults.data(forKey: metadataKey),
           let decoded = try? JSONDecoder().decode([PhotoMetadata].self, from: data) {
            photoMetadata = decoded
        }
    }
} 
