//
//  ContentView.swift
//  HelloLinkedSpaces
//
//  Created by In Seo on 4/26/25.
//

import SwiftUI
import Photos
import PhotosUI

struct ContentView: View {
    @StateObject private var photoService = PhotoAnalysisService()
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var analysisResult: PhotoAnalysisService.AnalysisResult?
    @State private var analysisProgress: String = ""
    
    // Custom colors for photo-related elements
    private let photoButtonColor = Color(red: 0.2, green: 0.5, blue: 0.9)
    private let photoButtonBackground = Color(red: 0.95, green: 0.95, blue: 1.0)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    if isAnalyzing {
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(photoButtonColor)
                            Text(analysisProgress)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity, maxHeight: 200)
                    } else {
                        PhotosPicker(selection: $selectedItem,
                                   matching: .images,
                                   photoLibrary: .shared()) {
                            VStack(spacing: 16) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 40))
                                    .foregroundColor(photoButtonColor)
                                Text("Select Photo")
                                    .font(.headline)
                                    .foregroundColor(photoButtonColor)
                            }
                            .frame(maxWidth: .infinity, maxHeight: 200)
                            .background(photoButtonBackground)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(photoButtonColor.opacity(0.3), lineWidth: 2)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                        .padding()
                    }
                    
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: UIScreen.main.bounds.width * 0.9, height: 300)
                            .clipped()
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            .padding()
                        
                        if let result = analysisResult {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Analysis Results")
                                    .font(.title2)
                                    .bold()
                                
                                ForEach(result.topCategories, id: \.category) { category in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("Category:")
                                                .font(.headline)
                                            Text(category.category.capitalized)
                                                .font(.title3)
                                                .foregroundColor(.blue)
                                        }
                                        
                                        HStack {
                                            Text("Confidence:")
                                                .font(.headline)
                                            Text(String(format: "%.1f%%", category.confidence * 100))
                                                .font(.title3)
                                                .foregroundColor(.blue)
                                        }
                                        
                                        if !category.matchedTags.isEmpty {
                                            Text("Matched Tags:")
                                                .font(.headline)
                                                .padding(.top, 5)
                                            
                                            VStack(alignment: .leading, spacing: 8) {
                                                ForEach(category.matchedTags, id: \.tag) { tag in
                                                    HStack {
                                                        Text(tag.tag)
                                                            .font(.subheadline)
                                                        Spacer()
                                                        Text(String(format: "%.1f%%", tag.confidence * 100))
                                                            .font(.subheadline)
                                                            .foregroundColor(.gray)
                                                    }
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Color.blue.opacity(0.1))
                                                    .cornerRadius(8)
                                                }
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.05))
                                    .cornerRadius(10)
                                }
                                
                                if !result.allTags.isEmpty {
                                    Text("Top 20 Extracted Tags:")
                                        .font(.headline)
                                        .padding(.top, 5)
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(result.allTags.prefix(20), id: \.tag) { tag in
                                            HStack {
                                                Text(tag.tag)
                                                    .font(.subheadline)
                                                Spacer()
                                                Text(String(format: "%.1f%%", tag.confidence * 100))
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(10)
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Photo Analysis")
            .onChange(of: selectedItem) { oldValue, newValue in
                print("DEBUG: Photo selection changed")
                if let newValue {
                    print("DEBUG: New photo selected, starting analysis")
                    isAnalyzing = true
                    analysisProgress = "Loading photo..."
                    // Clear previous analysis results
                    analysisResult = nil
                    Task {
                        await analyzeSelectedPhoto(newValue)
                        isAnalyzing = false
                        analysisProgress = ""
                        print("DEBUG: Analysis completed")
                    }
                }
            }
        }
    }
    
    private func analyzeSelectedPhoto(_ item: PhotosPickerItem) async {
        print("DEBUG: Starting photo analysis process")
        if let data = try? await item.loadTransferable(type: Data.self) {
            print("DEBUG: Successfully loaded photo data")
            if let image = UIImage(data: data) {
                print("DEBUG: Successfully created UIImage")
                selectedImage = image
                if let result = await photoService.analyzePhoto(image) { progress in
                    print("DEBUG: Progress update: \(progress)")
                    Task { @MainActor in
                        analysisProgress = progress
                    }
                } {
                    await MainActor.run {
                        analysisResult = result
                        print("DEBUG: Updated UI with analysis result - Categories: \(result.topCategories.count)")
                    }
                }
            } else {
                print("DEBUG: Failed to create UIImage from data")
            }
        } else {
            print("DEBUG: Failed to load photo data")
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, proposal: proposal).size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let positions = layout(sizes: sizes, proposal: proposal).positions
        
        for (index, subview) in subviews.enumerated() {
            subview.place(at: positions[index], proposal: .unspecified)
        }
    }
    
    private func layout(sizes: [CGSize], proposal: ProposedViewSize) -> (positions: [CGPoint], size: CGSize) {
        let width = proposal.width ?? .infinity
        var currentPosition = CGPoint.zero
        var maxHeight: CGFloat = 0
        var positions: [CGPoint] = []
        
        for size in sizes {
            if currentPosition.x + size.width > width {
                currentPosition.x = 0
                currentPosition.y += maxHeight + spacing
                maxHeight = 0
            }
            
            positions.append(currentPosition)
            currentPosition.x += size.width + spacing
            maxHeight = max(maxHeight, size.height)
        }
        
        return (positions, CGSize(width: width, height: currentPosition.y + maxHeight))
    }
}

#Preview {
    ContentView()
}
