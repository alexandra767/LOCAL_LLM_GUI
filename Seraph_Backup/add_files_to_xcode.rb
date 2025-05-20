#!/usr/bin/env ruby

require 'xcodeproj'

# Path to your .xcodeproj file
project_path = 'Seraph.xcodeproj'

# Initialize the Xcodeproj
project = Xcodeproj::Project.open(project_path)

# Get the main target (usually has the same name as the project)
target = project.targets.first

# Paths to add (relative to project file)
paths_to_add = [
  'Sources/Seraph/Views/SidebarView.swift',
  'Sources/Seraph/Views/ContentView.swift',
  'Sources/Seraph/Models/Project.swift',
  # Add other files as needed
]

# Add files to project and target
paths_to_add.each do |file_path|
  # Check if file exists
  unless File.exist?(file_path)
    puts "Warning: File not found: #{file_path}"
    next
  end
  
  # Add file reference if it doesn't exist
  file_ref = project.files.find { |f| f.path == file_path }
  
  unless file_ref
    group = project.main_group.find_subpath(File.dirname(file_path), true)
    file_ref = group.new_file(file_path)
    puts "Added file reference: #{file_path}"
  end
  
  # Add to target if not already added
  unless target.source_build_phase.files_references.include?(file_ref)
    target.add_file_references([file_ref])
    puts "Added to target: #{file_path}"
  end
end

# Save the project
project.save
puts "Project updated successfully!"
