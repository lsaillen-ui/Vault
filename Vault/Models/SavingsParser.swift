import Foundation

// MARK: - Résultat du parsing

enum SavingsValue {
    case monetary(Double)    // Ex: "CHF 25" → 25.0, "€12.50" → 12.50
    case percentage(Double)  // Ex: "-20%" → 20.0, "−30 %" → 30.0
    case unknown             // Ex: "Livraison offerte", "2+1 gratuit"

    var monetaryAmount: Double? {
        guard case .monetary(let v) = self else { return nil }
        return v
    }

    var percentageAmount: Double? {
        guard case .percentage(let v) = self else { return nil }
        return v
    }
}

// MARK: - Parser

enum SavingsParser {

    private static let currencyCodes    = ["CHF", "EUR", "USD", "GBP", "CAD", "AUD"]
    private static let currencySymbols  = ["€", "$", "£", "¥", "₣"]

    /// Parse la valeur textuelle d'un bon et retourne le type d'économie reconnu.
    ///
    /// Formats reconnus :
    /// - "CHF 25", "25 CHF", "€12.50", "25€"        → `.monetary(25.0)`
    /// - "-20%", "−30%", "20 % off", "Réduc 15%"    → `.percentage(20.0)`
    /// - "Livraison offerte", "2+1 gratuit"          → `.unknown`
    static func parse(_ raw: String) -> SavingsValue {
        let text = normalized(raw)

        // Priorité 1 : pourcentage (présence du signe %)
        if text.contains("%") {
            if let value = firstPositiveNumber(in: text), value > 0 {
                return .percentage(value)
            }
            return .unknown
        }

        // Priorité 2 : montant monétaire
        var stripped = text
        for code in currencyCodes {
            stripped = stripped.replacingOccurrences(of: code, with: " ", options: .caseInsensitive)
        }
        for sym in currencySymbols {
            stripped = stripped.replacingOccurrences(of: sym, with: " ")
        }

        if let value = firstPositiveNumber(in: stripped), value > 0 {
            return .monetary(value)
        }

        return .unknown
    }

    // MARK: - Helpers privés

    /// Normalise la chaîne : espaces, tirets spéciaux, virgules décimales.
    private static func normalized(_ raw: String) -> String {
        raw
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "\u{2212}", with: "-")   // Signe moins Unicode → ASCII
            .replacingOccurrences(of: "−", with: "-")          // Tiret typographique
            .replacingOccurrences(of: "\u{00A0}", with: " ")   // Espace insécable → espace
    }

    /// Extrait le premier nombre positif (entier ou décimal) présent dans le texte.
    private static func firstPositiveNumber(in text: String) -> Double? {
        // Cherche entier ou décimal avec séparateur . ou ,
        let pattern = #"(\d+(?:[.,]\d+)?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text)
        else { return nil }

        // Normalise la virgule décimale en point
        let numStr = String(text[range]).replacingOccurrences(of: ",", with: ".")
        return Double(numStr)
    }
}

// MARK: - Tests rapides (debug uniquement)

#if DEBUG
extension SavingsParser {
    static func runTests() {
        let cases: [(String, SavingsValue)] = [
            ("CHF 25",            .monetary(25)),
            ("25 CHF",            .monetary(25)),
            ("€12.50",            .monetary(12.5)),
            ("25€",               .monetary(25)),
            ("-20%",              .percentage(20)),
            ("−30%",              .percentage(30)),
            ("20 % off",          .percentage(20)),
            ("CHF 0",             .unknown),     // 0 considéré inconnu
            ("Livraison offerte", .unknown),
            ("2+1 gratuit",       .unknown),
        ]
        for (input, expected) in cases {
            let result = parse(input)
            let ok: Bool
            switch (result, expected) {
            case (.monetary(let a), .monetary(let b)):   ok = abs(a - b) < 0.01
            case (.percentage(let a), .percentage(let b)): ok = abs(a - b) < 0.01
            case (.unknown, .unknown):                   ok = true
            default:                                     ok = false
            }
            print("[SavingsParser] \(ok ? "✓" : "✗") \"\(input)\" → \(result) (attendu: \(expected))")
        }
    }
}
#endif
