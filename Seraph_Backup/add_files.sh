#!/bin/bash

# Close Xcode if it's open
osascript -e 'tell application "Xcode" to quit'

# Path to the .xcodeproj file
PROJECT="Seraph.xcodeproj"

# Add files to the project
xcodebuild -project "$PROJECT" -list

# Add View files
xcodebuild -project "$PROJECT" -target Seraph -sources "Sources/Seraph/Views/SidebarView.swift" "Sources/Seraph/Views/ContentView.swift"

# Add Model files
xcodebuild -project "$PROJECT" -target Seraph -sources "Sources/Seraph/Models/Project.swift"

echo "Files have been added to the Xcode project. Please reopen Xcode to see the changes."
