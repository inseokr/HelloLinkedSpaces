//
//  ContentView.swift
//  HelloLinkedSpaces
//
//  Created by In Seo on 4/26/25.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var photoService = PhotoAnalysisService()
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var analysisResult: PhotoAnalysisService.AnalysisResult?
    @State private var analysisProgress: String = ""
    @State private var isPickerPresented = false
    @State private var shouldResetPicker = false
    @State private var selectedCategory: String? = nil
    
    // Custom colors for photo-related elements
    private let photoButtonColor = Color.blue
    private let tagBackgroundColor = Color(red: 0.95, green: 0.97, blue: 1.0)
    private let tagTextColor = Color.blue
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Photo Analysis")
                            .font(.system(size: 34, weight: .bold))
                        Text("Upload a photo to analyze its contents")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
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
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .background(Color.white)
                        .cornerRadius(16)
                        .padding(.horizontal)
                    } else {
                        // Photo upload button
                        Button(action: {
                            isPickerPresented = true
                        }) {
                            VStack(spacing: 16) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(photoButtonColor)
                                Text("Select a photo to analyze")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.black)
                                Text("Tap to upload")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                                    .background(Color.white)
                            )
                            .cornerRadius(16)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                        .photosPicker(isPresented: $isPickerPresented,
                                    selection: $selectedItem,
                                    matching: .images,
                                    photoLibrary: .shared())
                    }
                    
                    if let image = selectedImage {
                        // Selected image preview
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                Button(action: {
                                    selectedImage = nil
                                    selectedItem = nil
                                    analysisResult = nil
                                }) {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Image(systemName: "xmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.black)
                                        )
                                }
                                .padding(12),
                                alignment: .topTrailing
                            )
                            .padding(.horizontal)
                        
                        if let result = analysisResult {
                            // Categories section
                            VStack(alignment: .leading, spacing: 24) {
                                Text("Possible Categories")
                                    .font(.system(size: 24, weight: .bold))
                                    .padding(.horizontal)
                                
                                if let selected = selectedCategory,
                                   let category = result.topCategories.first(where: { $0.category == selected }) {
                                    // Expanded category view
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack {
                                            HStack {
                                                Image(systemName: getCategoryIcon(category.category))
                                                    .foregroundColor(getCategoryColor(category.category))
                                                Text(category.category.capitalized)
                                                    .font(.system(size: 18, weight: .semibold))
                                            }
                                            Spacer()
                                            Button(action: {
                                                withAnimation {
                                                    selectedCategory = nil
                                                }
                                            }) {
                                                Image(systemName: "xmark")
                                                    .foregroundColor(.black)
                                                    .font(.system(size: 16, weight: .medium))
                                            }
                                        }
                                        
                                        HStack(alignment: .top, spacing: 24) {
                                            VStack(alignment: .leading) {
                                                Text("Confidence")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.gray)
                                                Text("\(Int(category.confidence * 100))%")
                                                    .font(.system(size: 18, weight: .medium))
                                            }
                                            
                                            if !category.matchedTags.isEmpty {
                                                VStack(alignment: .leading, spacing: 8) {
                                                    Text("Matched Tags")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(.gray)
                                                    
                                                    ScrollView(.horizontal, showsIndicators: false) {
                                                        HStack(spacing: 8) {
                                                            ForEach(category.matchedTags, id: \.tag) { tag in
                                                                Text(tag.tag)
                                                                    .font(.system(size: 16))
                                                                    .foregroundColor(tagTextColor)
                                                                    .padding(.horizontal, 16)
                                                                    .padding(.vertical, 8)
                                                                    .background(tagBackgroundColor)
                                                                    .cornerRadius(20)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
                                    .padding(.horizontal)
                                } else {
                                    // Regular grid view of categories
                                    LazyVGrid(columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ], spacing: 16) {
                                        ForEach(result.topCategories.prefix(2), id: \.category) { category in
                                            Button(action: {
                                                withAnimation {
                                                    selectedCategory = category.category
                                                }
                                            }) {
                                                VStack(alignment: .leading, spacing: 12) {
                                                    HStack {
                                                        Image(systemName: getCategoryIcon(category.category))
                                                            .foregroundColor(getCategoryColor(category.category))
                                                        Text(category.category.capitalized)
                                                            .font(.system(size: 18, weight: .semibold))
                                                    }
                                                    Text("Confidence: \(Int(category.confidence * 100))%")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(.gray)
                                                }
                                                .padding()
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .background(Color.white)
                                                .cornerRadius(12)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                
                                // Tags section
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Extracted Tags")
                                        .font(.system(size: 24, weight: .bold))
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(result.allTags.prefix(10), id: \.tag) { tag in
                                                Text(tag.tag)
                                                    .font(.system(size: 16))
                                                    .foregroundColor(tagTextColor)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(tagBackgroundColor)
                                                    .cornerRadius(20)
                                            }
                                            if result.allTags.count > 10 {
                                                Text("+\(result.allTags.count - 10) more")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.gray)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(Color.gray.opacity(0.1))
                                                    .cornerRadius(20)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.top)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(red: 0.98, green: 0.98, blue: 0.98))
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onChange(of: selectedItem) { oldValue, newValue in
            if let newValue {
                isAnalyzing = true
                analysisProgress = "Loading photo..."
                analysisResult = nil
                
                Task {
                    await analyzeSelectedPhoto(newValue)
                    isAnalyzing = false
                    analysisProgress = ""
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            if isAnalyzing {
                isAnalyzing = false
                analysisProgress = ""
                analysisResult = nil
                selectedImage = nil
                selectedItem = nil
            }
            // Reset picker presentation state
            isPickerPresented = false
        }
    }
    
    private func analyzeSelectedPhoto(_ item: PhotosPickerItem) async {
        isPickerPresented = false
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            selectedImage = image
            if let result = await photoService.analyzePhoto(image) { progress in
                Task { @MainActor in
                    analysisProgress = progress
                }
            } {
                await MainActor.run {
                    analysisResult = result
                }
            }
        }
    }
    
    private func getCategoryIcon(_ category: String) -> String {
        switch category.lowercased() {
        case "restaurant":
            return "fork.knife.circle.fill"
        case "cafe":
            return "cup.and.saucer.fill"
        case "sightseeing":
            return "mountain.2.circle.fill"
        case "shopping":
            return "bag.circle.fill"
        case "hotel":
            return "house.circle.fill"
        case "park":
            return "leaf.circle.fill"
        case "airport":
            return "airplane.circle.fill"
        case "museum":
            return "building.columns.circle.fill"
        default:
            return "mappin.circle.fill"
        }
    }
    
    private func getCategoryColor(_ category: String) -> Color {
        switch category.lowercased() {
        case "restaurant":
            return .orange
        case "cafe":
            return .brown
        case "sightseeing":
            return .blue
        case "shopping":
            return .purple
        case "hotel":
            return .indigo
        case "park":
            return .green
        case "airport":
            return .blue
        case "museum":
            return .orange
        default:
            return .gray
        }
    }
}

// If you need it, here is the FlowLayout (not directly used yet)
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

