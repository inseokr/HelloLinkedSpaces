# HelloLinkedSpaces

An iOS application that uses machine learning to classify places from photos. The app uses Vision framework for image analysis and OpenAI's GPT-3.5 for intelligent place classification.

## Features

- Photo analysis using Vision framework
- Place classification using OpenAI's GPT-3.5
- Support for multiple categories: restaurant, sightseeing, shopping, hotel, and park
- Confidence scoring for classifications
- Detailed tag analysis

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+
- OpenAI API key

## Installation

1. Clone the repository
2. Open the project in Xcode
3. Set up configuration:
   - Copy `Config.xcconfig.example` to `Config.xcconfig`
   - Add your OpenAI API key to `Config.xcconfig`
   - In Xcode, select the project in the navigator
   - Select your target
   - Go to "Build Phases"
   - Expand "Copy Bundle Resources"
   - Click the "+" button
   - Add "Config.xcconfig"
4. Build and run the project

## Usage

1. Take a photo or select one from your photo library
2. The app will analyze the image and provide classification results
3. View the top categories and their confidence scores
4. See which tags contributed to each classification

## Configuration

The app requires an OpenAI API key to function. To set it up:

1. Get an API key from [OpenAI](https://platform.openai.com/api-keys)
2. Copy `Config.xcconfig.example` to `Config.xcconfig`
3. Replace `YOUR_API_KEY_HERE` with your actual API key
4. Make sure `Config.xcconfig` is included in your app bundle:
   - In Xcode, select your target
   - Go to "Build Phases"
   - Expand "Copy Bundle Resources"
   - Add "Config.xcconfig" if it's not already there

## License

This project is licensed under the MIT License - see the LICENSE file for details. 