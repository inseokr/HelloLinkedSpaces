import CoreML
import Vision
import UIKit

class PlaceClassificationService {
    private let model: MLModel
    private let modelName: String
    private let confidenceThreshold: Double = 0.02 // 2% threshold
    private let openAIApiKey: String
    
    // Define our target categories
    private let targetCategories = ["restaurant", "sightseeing", "shopping", "hotel", "park"]
    
    init(modelName: String = "MobileNetV2", openAIApiKey: String) throws {
        self.modelName = modelName
        self.openAIApiKey = openAIApiKey
        
        // Load the model
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            print("DEBUG: Failed to find model in main bundle")
            throw NSError(domain: "PlaceClassificationService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model file not found in main bundle"])
        }
        
        print("DEBUG: Found model in main bundle")
        let config = MLModelConfiguration()
        self.model = try MLModel(contentsOf: modelURL, configuration: config)
    }
    
    func getRawPredictions(image: UIImage) throws -> [String: Double] {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "PlaceClassificationService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to get CGImage from UIImage"])
        }
        
        // Create a Vision request handler
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // Create a Vision request
        let request = VNCoreMLRequest(model: try VNCoreMLModel(for: model)) { request, error in
            if let error = error {
                print("Vision request error: \(error)")
                return
            }
        }
        
        // Configure the request
        request.imageCropAndScaleOption = .centerCrop
        
        // Perform the request
        try requestHandler.perform([request])
        
        // Get the results
        guard let results = request.results as? [VNClassificationObservation] else {
            throw NSError(domain: "PlaceClassificationService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to get classification results"])
        }
        
        // Convert results to dictionary and filter by confidence threshold
        var predictions: [String: Double] = [:]
        for result in results {
            let confidence = Double(result.confidence)
            if confidence >= confidenceThreshold {
                predictions[result.identifier] = confidence
            }
        }
        
        return predictions
    }
    
    struct CategoryPrediction {
        let category: String
        let confidence: Double
        let contributingTags: [(tag: String, confidence: Double)]
    }
    
    func predict(image: UIImage) async throws -> [CategoryPrediction] {
        print("DEBUG: Starting prediction process")
        
        // Get raw predictions
        let rawPredictions = try getRawPredictions(image: image)
        
        print("DEBUG: Got \(rawPredictions.count) raw predictions")
        
        // Get top 10 tags with their confidence scores
        let topTags = rawPredictions
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { (tag: $0.key, confidence: $0.value) }
        
        // Create prompt for OpenAI
        let prompt = """
        Given these image tags and their confidence scores, classify the image into one of these categories: restaurant, sightseeing, shopping, hotel, or park.
        For each category, provide a confidence score (0-1) and explain which tags contributed to that classification.
        
        Tags:
        \(topTags.map { "- \($0.tag) (confidence: \(String(format: "%.2f", $0.confidence)))" }.joined(separator: "\n"))
        
        Please respond in JSON format with this structure:
        {
            "categories": [
                {
                    "category": "category_name",
                    "confidence": 0.0,
                    "contributing_tags": [
                        {
                            "tag": "tag_name",
                            "confidence": 0.0
                        }
                    ]
                }
            ]
        }
        """
        
        // Call OpenAI API
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIApiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a helpful assistant that classifies images based on their tags."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Parse OpenAI response
        guard let response = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = response["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String,
              let contentData = content.data(using: .utf8),
              let jsonResponse = try JSONSerialization.jsonObject(with: contentData) as? [String: Any],
              let categories = jsonResponse["categories"] as? [[String: Any]] else {
            throw NSError(domain: "PlaceClassificationService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse OpenAI response"])
        }
        
        // Convert OpenAI response to CategoryPrediction array
        return try categories.map { categoryDict in
            guard let category = categoryDict["category"] as? String,
                  let confidence = categoryDict["confidence"] as? Double,
                  let contributingTags = categoryDict["contributing_tags"] as? [[String: Any]] else {
                throw NSError(domain: "PlaceClassificationService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Invalid category format in OpenAI response"])
            }
            
            let tags = try contributingTags.map { tagDict in
                guard let tag = tagDict["tag"] as? String,
                      let tagConfidence = tagDict["confidence"] as? Double else {
                    throw NSError(domain: "PlaceClassificationService", code: 6, userInfo: [NSLocalizedDescriptionKey: "Invalid tag format in OpenAI response"])
                }
                return (tag: tag, confidence: tagConfidence)
            }
            
            return CategoryPrediction(
                category: category,
                confidence: confidence,
                contributingTags: tags
            )
        }
    }
} 