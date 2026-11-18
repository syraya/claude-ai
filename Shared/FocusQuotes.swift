import Foundation

/// Lines for the block screen, so it says something different each time you meet it.
enum FocusQuotes {
    /// Classical lines on time and attention, with who said them and where.
    static let classical: [(text: String, source: String)] = [
        ("Hold every hour in your grasp.", "Seneca, Letters 1"),
        ("It is not that we have a short time to live, but that we waste a lot of it.", "Seneca, On the Shortness of Life"),
        ("Begin at once to live, and count each separate day as a separate life.", "Seneca, Letters 101"),
        ("Waste no more time arguing what a good man should be. Be one.", "Marcus Aurelius, Meditations"),
        ("Concentrate every minute on doing what's in front of you.", "Marcus Aurelius, Meditations"),
        ("Dwell on the beauty of life.", "Marcus Aurelius, Meditations"),
        ("No man is free who is not master of himself.", "Epictetus"),
        ("The unexamined life is not worth living.", "Socrates, in Plato's Apology"),
        ("Well begun is half done.", "Aristotle"),
        ("Time is the most valuable thing a man can spend.", "Theophrastus"),
        ("The journey of a thousand miles begins with a single step.", "Lao Tzu, Tao Te Ching"),
        ("He who has a why to live can bear almost any how.", "Nietzsche, Twilight of the Idols"),
    ]

    /// OMO's own reminders. `app` is the blocked app's name.
    static func reminders(app: String) -> [String] {
        [
            "\(app) will still be here when you're done.",
            "What were you about to open, and why?",
            "Will this make the next hour better or worse?",
            "Stay with the thought you were having.",
            "One more page. Then decide.",
            "The urge passes. The work stays done.",
        ]
    }

    /// A random line: sometimes your OMO's own, sometimes a reminder, usually a classic.
    static func random(app: String, companion: OmoCompanion) -> String {
        switch Int.random(in: 0..<10) {
        case 0..<2:
            return "“\(companion.whisper)”\n\(companion.name)"
        case 2..<4:
            return reminders(app: app).randomElement() ?? companion.whisper
        default:
            let quote = classical.randomElement() ?? classical[0]
            return "“\(quote.text)”\n\(quote.source)"
        }
    }
}
