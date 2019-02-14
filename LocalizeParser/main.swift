#!/usr/bin/swift

import Foundation

func getLocalizedString(from text: String) -> [String] {
    return findSrings(withPattern: "\"(.*?)\".localized", in: text).compactMap({ ($0 as NSString).substring(with: NSRange(location: 1, length: $0.count-12)) }) // remove " at begining and ".localized at the ed
}

func getNotLocalizedString(from text: String) -> [String] {
    return findSrings(withPattern: "\"(.*?)\"", in: text).compactMap({ ($0 as NSString).substring(with: NSRange(location: 1, length: $0.count-2)) }) // remove " at begining and end
}

private func findSrings(withPattern pattern: String, in text: String) -> [String] {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
        print("Invalid regex pattern")
        return []
    }
    let string = text as NSString
    let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: string.length))
    return results.map({ string.substring(with: $0.range) })
}

extension Sequence where Iterator.Element == String {
    func filterContaining(_ string: String) -> Bool {
        return self.contains(where: { $0.contains(string) })
    }
}


// MARK: -

let path = CommandLine.arguments[1] //"/Users/constantinbreahna/Documents/Developer/LocalizeParser/LocalizeParser/testFolder/"


private func writeToFile(_ text: String, filename: String) {
    let pathUrl = URL(fileURLWithPath: path).appendingPathComponent(filename)
    print(pathUrl.absoluteString)
    do {
        try text.write(to: pathUrl, atomically: true, encoding: .utf8)
    } catch {
        print("Write to file with error:", error.localizedDescription)
    }
}

func getSwiftFilePaths(in path: String) -> [String] {
    var files: [String] = []
    if let components = try? FileManager.default.contentsOfDirectory(atPath: path) {
        for component in components {
            let componentPath = URL(fileURLWithPath: path).appendingPathComponent(component)
            print("Searching for component", componentPath.absoluteString)
            
            if component.contains(".swift") {
                files.append(componentPath.path)
            } else {
                files.append(contentsOf: getSwiftFilePaths(in: componentPath.path))
            }
        }
    } else if path.contains(".swift") {
        files.append(path)
    }
    return files
}


let swiftFiles = getSwiftFilePaths(in: path)


var localizedStringList: [String] = []
var notLocalizedStringList: [String] = []

for file in swiftFiles {
    if let data = FileManager.default.contents(atPath: file) {
        if let stringData = String(bytes: data, encoding: String.Encoding.utf8) {
            
            print("\n CONTENS for file at:", file)
            let localizationStrings = getLocalizedString(from: stringData)
            print("localizationStrings:")
            localizationStrings.forEach({ print($0) })
            
            localizedStringList.append(contentsOf: localizationStrings)
            
            let notLocalized = getNotLocalizedString(from: stringData).filter({ !localizedStringList.filterContaining($0) })
            print("\nnotLocalized:")
            notLocalized.forEach({ print($0) })
            
            notLocalizedStringList.append(contentsOf: notLocalized)
            
            print("\n")
        } else {
            print("Invalid encoding for", file)
        }
    }

}


writeToFile(localizedStringList.joined(separator: "\n"), filename: "Localized.txt")
writeToFile(notLocalizedStringList.joined(separator: "\n"), filename: "NonLocalized.txt")
