//
//  BoopLexer.swift
//  Boop
//
//  Created by Ivan on 1/26/19.
//  Copyright © 2019 OKatBest. All rights reserved.
//

import Cocoa
import SavannaKit

class BoopLexer: RegexLexer {
    
    // This is not really an exhaustive list, it's more of a rough estimation of
    // what you can encounter in a lot/most of languages. Add more to it!
    // BTW is attribute the correct name? Token was taken.
    var commonAttributes = ["var", "val", "let", "if", "else", "export", "import", "return", "static", "fun", "function", "func", "class", "open", "new", "as", "where", "select", "delete", "add", "limit", "update", "insert"]
    
    
    var moreAttributes = ["true", "false", "to", "string", "int", "float", "double", "bool", "boolean", "from"]
    
    func generators(source: String) -> [TokenGenerator] {
        
        let standalonePrefix = "(?<=[\\s]|^|[\\(,:])"
        let standaloneSuffix = "(?=[\\s\\?\\!,:\\)\\();]|$)"
        
        let quoteLookahead = "(?=(?:(?:[^\"]*\"){2})*[^\"]*$)"
        
        let quotes = "(\"|@\")(?:[^\"\\\\\\n]|\\\\.)*[^\"\\n]*(@\"|\")"
        let number = "\\b(?:0x[a-f0-9]+|(?:\\d(?:_\\d+)*\\d*(?:\\.\\d*)?|\\.\\d\\+)(?:e[+\\-]?\\d+)?)\\b"
        
        
        var generators = [TokenGenerator?]()
        
        generators.append(regexToken(.number, number))
        
        // Find common attributes
        
        generators.append(regexToken(.attribute, "\(standalonePrefix)(\(commonAttributes.joined(separator: "|")))\(standaloneSuffix)", options: .caseInsensitive))
        
        generators.append(regexToken(.keyword, "\(standalonePrefix)(\(moreAttributes.joined(separator: "|")))\(standaloneSuffix)", options: .caseInsensitive))
        
        
        // Extras
        
        
        // - Match MD5 strings
        generators.append(regexToken(.keyword, "\(standalonePrefix)([a-f0-9]{32})\(standaloneSuffix)", options: .dotMatchesLineSeparators))
        
        
        // - Bootleg XML-like tags match:
        
        generators.append(regexToken(.attribute, "(?m)\(quoteLookahead)<(?:.*?)\\b[^>]*\\/?>"))
        
        // Strings
        
        generators.append(regexToken(.string, quotes, options: [.dotMatchesLineSeparators, .caseInsensitive]))
        
        generators.append(regexToken(.string, "`(?:[^`\\\\\\n]|\\\\.)*[^`\\n]*`", options: [.dotMatchesLineSeparators, .caseInsensitive]))
        
        generators.append(regexToken(.string, "'(?:[^\'\\\\\\n]|\\\\.)*[^\'\\n]*'", options: [.dotMatchesLineSeparators, .caseInsensitive]))
        
        generators.append(regexToken(.string, "(\"\"\")(.*?)(\"\"\")", options: [.dotMatchesLineSeparators, .caseInsensitive]))
        
        // More Extras
        
        // - Match JSON labels and generic parameters
        generators.append(regexToken(.extra, "(?m)\(quoteLookahead)(?=(?:[ {\\[]*))([^\\r\\n:\\s\\w]+?|\(quotes))\\s*(?=\\:(?!\\:))"))
        
        
        
        // Comments
        
        generators.append(regexToken(.comment, "\(quoteLookahead)//(.*)"))
        
        generators.append(regexToken(.comment, "\(quoteLookahead)/\\*.*?\\*/", options: [.dotMatchesLineSeparators, .caseInsensitive]))
        
        generators.append(regexToken(.comment, "\(quoteLookahead)<\\!--[\\s\\S]*?(?:-\\->|$)", options: [.dotMatchesLineSeparators, .caseInsensitive]))
        
      
        
        
        return generators.compactMap( { $0 })
    }
    
    func regexToken(_ type: BoopToken.TokenType, _ pattern:String, options: NSRegularExpression.Options = .caseInsensitive) -> TokenGenerator? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return nil
        }
        let generator = RegexTokenGenerator(regularExpression: regex, tokenTransformer: { (range) -> Token in
            return BoopToken(type: type, range: range)
        })
        return TokenGenerator.regex(generator)
    }
    
}
