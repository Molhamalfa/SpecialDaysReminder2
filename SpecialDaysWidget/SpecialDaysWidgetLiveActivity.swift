//
//  SpecialDaysWidgetLiveActivity.swift
//  SpecialDaysWidget
//
//  Created by Mac on 28.07.2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SpecialDaysWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct SpecialDaysWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SpecialDaysWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension SpecialDaysWidgetAttributes {
    fileprivate static var preview: SpecialDaysWidgetAttributes {
        SpecialDaysWidgetAttributes(name: "World")
    }
}

extension SpecialDaysWidgetAttributes.ContentState {
    fileprivate static var smiley: SpecialDaysWidgetAttributes.ContentState {
        SpecialDaysWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: SpecialDaysWidgetAttributes.ContentState {
         SpecialDaysWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: SpecialDaysWidgetAttributes.preview) {
   SpecialDaysWidgetLiveActivity()
} contentStates: {
    SpecialDaysWidgetAttributes.ContentState.smiley
    SpecialDaysWidgetAttributes.ContentState.starEyes
}
