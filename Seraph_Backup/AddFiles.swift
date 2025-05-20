import Foundation

let projectPath = "/Users/alexandratitus767/Developer/AI_GUI_PROJECT_LOCAL_LLMs/Seraph/Seraph.xcodeproj/project.pbxproj"
let filesToAdd = [
    "Sources/Seraph/Views/SidebarView.swift",
    "Sources/Seraph/Views/ContentView.swift",
    "Sources/Seraph/Models/Project.swift"
]

do {
    var projectContent = try String(contentsOfFile: projectPath, encoding: .utf8)
    
    for file in filesToAdd {
        let fileRef = "/* \(file) in Sources */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"\(file.components(separatedBy: "/").last!)\"; sourceTree = \"<group>\"; };"
        let buildFile = "\t\t[0-9A-F]{24} /* \(file.components(separatedBy: "/").last!) in Sources */ = {isa = PBXBuildFile; fileRef = [0-9A-F]{24} /* \(file.components(separatedBy: "/").last!) */; };"
        
        // Add file reference if not exists
        if !projectContent.contains(fileRef) {
            if let range = projectContent.range(of: "children = \\(\n") {
                let insertPos = projectContent.index(range.upperBound, offsetBy: 0)
                projectContent.insert(contentsOf: "\t\t\t\(fileRef)\n", at: insertPos)
                print("Added file reference for \(file)")
            }
        }
        
        // Add build file if not exists
        if !projectContent.contains(buildFile) {
            if let range = projectContent.range(of: "files = \\(\n") {
                let insertPos = projectContent.index(range.upperBound, offsetBy: 0)
                projectContent.insert(contentsOf: "\t\t\t\(buildFile)\n", at: insertPos)
                print("Added build file for \(file)")
            }
        }
    }
    
    try projectContent.write(toFile: projectPath, atomically: true, encoding: .utf8)
    print("Project file updated successfully!")
    
} catch {
    print("Error: \(error)")
}
